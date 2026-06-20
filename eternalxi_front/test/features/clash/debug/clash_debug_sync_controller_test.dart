import 'package:eternal_xi/features/clash/debug/data/clash_debug_sync_controller.dart';
import 'package:eternal_xi/features/clash/debug/domain/clash_debug_bootstrap_result.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences countingApplierPrefs;
late SharedPreferences backupPrefs;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    countingApplierPrefs = await SharedPreferences.getInstance();
    backupPrefs = await SharedPreferences.getInstance();
  });

  group('ClashDebugSyncController Fase 72', () {
    test('validateLocal muestra snapshot válido', () async {
      final controller = _controller();

      await controller.validateLocal();

      expect(controller.lastResult?.operation, ClashSyncOperation.validate);
      expect(controller.lastValidateResult?.isSuccess, isTrue);
      expect(controller.lastValidateResult?.validationResult?.isValid, isTrue);
    });

    test('pull notFound muestra estado notFound', () async {
      final controller = _controller();

      await controller.pullRemote();

      expect(controller.lastPullResult?.operation, ClashSyncOperation.pull);
      expect(controller.lastPullResult?.isNotFound, isTrue);
    });

    test('pull success guarda serverRevision', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.executePushLocal();
      await controller.pullRemote();

      expect(controller.lastPullResult?.isSuccess, isTrue);
      expect(controller.lastPullResult?.serverRevision, 1);
      expect(controller.knownServerRevision, 1);
    });

    test('pull success guarda snapshot remoto sin aplicar', () async {
      final applier = _CountingApplier();
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, applier: applier);

      await controller.executePushLocal();
      await controller.pullRemote();

      expect(controller.pendingRemoteSnapshot, isNotNull);
      expect(applier.applyCalls, 0);
      expect(controller.canApplyPendingRemote, isTrue);
    });

    test('applyPendingRemote aplica tras confirmación manual', () async {
      final applier = _CountingApplier();
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, applier: applier);

      await controller.executePushLocal();
      await controller.pullRemote();

      final result = await controller.applyPendingRemote();

      expect(applier.applyCalls, 1);
      expect(result?.isSuccess, isTrue);
      expect(controller.lastApplyResult?.isSuccess, isTrue);
    });

    test('snapshot inválido remoto no aplica', () async {
      final applier = _CountingApplier(
        result: const ClashSyncApplyResult(
          status: ClashSyncApplyStatus.validationFailed,
          message: 'invalid',
        ),
      );
      final controller = _controller(applier: applier);
      controller.pendingRemoteSnapshot = _validSnapshot();
      controller.lastPullResult = ClashSyncOperationResult.fromPull(
        pullResult: ClashSyncPullResult.success(
          snapshot: _validSnapshot(),
          serverRevision: 1,
        ),
        startedAt: _epoch,
        completedAt: _epoch,
      );

      final result = await controller.applyPendingRemote();

      expect(result?.isValidationFailed, isTrue);
    });

    test('401/unavailable muestra authRequired o error controlado', () async {
      final controller = _controller(
        client: _UnauthorizedSyncClient(),
        isAuthenticated: () async => true,
      );

      await controller.pullRemote();

      expect(controller.lastPullResult?.errorCode, 'unauthorized');
      expect(controller.isUnauthorized, isTrue);
    });

    test('sin autenticación no llama al coordinator', () async {
      final client = _CountingSyncClient();
      final controller = _controller(
        client: client,
        isAuthenticated: () async => false,
      );

      await controller.pullRemote();

      expect(client.pullCalls, 0);
      expect(controller.authRequired, isTrue);
      expect(controller.lastPullResult, isNull);
    });
  });

  group('ClashDebugSyncController Fase 75', () {
    test('subir local sin remoto crea save', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.executePushLocal();

      expect(controller.lastPushResult?.operation, ClashSyncOperation.push);
      expect(controller.lastPushResult?.isSuccess, isTrue);
      expect(client.serverRevision, 1);
    });

    test('subir local con revision conocida actualiza', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.executePushLocal();
      await controller.executePushLocal();

      expect(controller.lastPushResult?.isSuccess, isTrue);
      expect(client.serverRevision, 2);
    });

    test('subida con snapshot inválido no llama API', () async {
      final client = _CountingSyncClient();
      final controller = _controller(
        client: client,
        builder: _InvalidSnapshotBuilder(),
      );

      await controller.executePushLocal();

      expect(client.pushCalls, 0);
      expect(controller.lastPushResult?.isValidationFailed, isTrue);
    });

    test('conflicto 409 se muestra y no reintenta', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.executePushLocal();
      await controller.executePushLocal();
      controller.knownServerRevision = 1;

      await controller.executePushLocal();

      expect(controller.lastPushResult?.isConflict, isTrue);
      expect(controller.knownServerRevision, 2);
      expect(client.serverRevision, 2);
    });

    test('willOverwriteRemoteSave es true si hay remoto', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.executePushLocal();

      expect(await controller.willOverwriteRemoteSave(), isTrue);
      expect(controller.knownServerRevision, 1);
    });

    test('willOverwriteRemoteSave es false si no hay remoto', () async {
      final controller = _controller();

      expect(await controller.willOverwriteRemoteSave(), isFalse);
    });

    test('hasLocalBackup refleja backup store', () async {
      final backupStore = ClashSyncLocalBackupStore(
        sharedPreferences: backupPrefs,
      );
      final controller = _controller(backupStore: backupStore);

      expect(controller.hasLocalBackup, isFalse);

      await backupStore.save(
        ClashSyncLocalBackup(
          generatedAt: _epoch,
          source: ClashSyncLocalBackup.sourceBeforeRemoteApply,
          snapshot: _validSnapshot(),
        ),
      );
      expect(controller.hasLocalBackup, isTrue);
    });

    test('no hay sync automática al crear controller', () {
      final client = _CountingSyncClient();
      _controller(client: client);

      expect(client.pullCalls, 0);
      expect(client.pushCalls, 0);
    });

    test('apply y restore no se ejecutan automáticamente tras push', () async {
      final applier = _CountingApplier();
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, applier: applier);

      await controller.executePushLocal();
      await controller.pullRemote();

      expect(applier.applyCalls, 0);
      expect(controller.lastApplyResult, isNull);
      expect(controller.lastRestoreResult, isNull);
    });
  });

  group('ClashDebugSyncController Fase 76', () {
    setUp(() async {
      await backupPrefs.remove(ClashSharedPreferencesKeys.syncMetadata);
    });

    test(
      'reiniciar controller recupera knownServerRevision desde metadata',
      () async {
        final storage = ClashSyncMetadataStorage(
          sharedPreferences: backupPrefs,
        );
        await storage.save(
          const ClashSyncMetadata(
            knownServerRevision: 7,
            lastOperation: 'pull',
            lastStatus: 'success',
          ),
        );

        final first = _controller(metadataStorage: storage);
        expect(first.knownServerRevision, 7);
        expect(first.effectiveKnownRevision, 7);
        first.dispose();

        final second = _controller(metadataStorage: storage);
        expect(second.knownServerRevision, 7);
        expect(second.metadata.lastOperation, 'pull');
        second.dispose();
      },
    );

    test('pull success persiste metadata', () async {
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, metadataStorage: storage);

      await controller.executePushLocal();
      await controller.pullRemote();

      expect(storage.load().knownServerRevision, 1);
      expect(storage.load().lastOperation, 'pull');
      expect(storage.load().lastPullAt, _epoch);
    });

    test('conflict persiste lastConflictServerRevision', () async {
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, metadataStorage: storage);

      await controller.executePushLocal();
      await controller.executePushLocal();
      controller.knownServerRevision = 1;

      await controller.executePushLocal();

      expect(storage.load().lastConflictServerRevision, 2);
      expect(storage.load().lastStatus, 'conflict');
    });

    test('validate persiste estado sin HTTP extra', () async {
      final client = _CountingSyncClient();
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      final controller = _controller(client: client, metadataStorage: storage);

      await controller.validateLocal();

      expect(client.pullCalls, 0);
      expect(client.pushCalls, 0);
      expect(storage.load().lastOperation, 'validate');
      expect(storage.load().lastStatus, 'success');
    });

    test('operationResultForDisplay usa metadata tras reinicio', () async {
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      await storage.save(
        const ClashSyncMetadata(
          lastOperation: 'push',
          lastStatus: 'success',
          knownServerRevision: 5,
        ),
      );

      final controller = _controller(metadataStorage: storage);
      final display = controller.operationResultForDisplay(
        ClashSyncOperation.push,
      );

      expect(display?.isSuccess, isTrue);
      expect(display?.serverRevision, 5);
      expect(controller.lastPushResult, isNull);
    });

    test('legacy install sin metadata funciona con defaults', () {
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      final controller = _controller(metadataStorage: storage);

      expect(controller.metadata, const ClashSyncMetadata());
      expect(controller.effectiveKnownRevision, isNull);
    });
  });

  group('ClashDebugSyncController Fase 77', () {
    setUp(() async {
      await backupPrefs.remove(ClashSharedPreferencesKeys.syncMetadata);
    });

    test('bootstrap con remoto existente deja pendingRemoteSnapshot', () async {
      final client = FakeClashSyncClient();
      await client.pushSnapshot(_validSnapshot());
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      final applier = _CountingApplier();
      final controller = _controller(
        client: client,
        metadataStorage: storage,
        applier: applier,
      );

      await controller.bootstrapOnlineSave();

      expect(controller.pendingRemoteSnapshot, isNotNull);
      expect(controller.lastBootstrapResult?.isRemoteFound, isTrue);
      expect(controller.knownServerRevision, 1);
      expect(applier.applyCalls, 0);
      expect(storage.load().hasPendingRemoteSnapshot, isTrue);
      expect(storage.load().lastOperation, 'pull');
    });

    test('bootstrap sin remoto crea con snapshot local válido', () async {
      final client = FakeClashSyncClient();
      final storage = ClashSyncMetadataStorage(sharedPreferences: backupPrefs);
      final controller = _controller(client: client, metadataStorage: storage);

      await controller.bootstrapOnlineSave();

      expect(client.serverRevision, 1);
      expect(controller.lastBootstrapResult?.isRemoteCreated, isTrue);
      expect(controller.pendingRemoteSnapshot, isNull);
      expect(storage.load().lastOperation, 'push');
      expect(storage.load().lastSuccessfulSyncAt, _epoch);
    });

    test('bootstrap con snapshot inválido no crea', () async {
      final client = _CountingSyncClient();
      final controller = _controller(
        client: client,
        builder: _InvalidSnapshotBuilder(),
      );

      await controller.bootstrapOnlineSave();

      expect(client.pushCalls, 0);
      expect(client.serverRevision, 0);
      expect(
        controller.lastBootstrapResult?.status,
        ClashDebugBootstrapStatus.validationFailed,
      );
    });

    test('bootstrap 401 muestra estado unauthorized', () async {
      final controller = _controller(
        client: _UnauthorizedSyncClient(),
        isAuthenticated: () async => true,
      );

      await controller.bootstrapOnlineSave();

      expect(
        controller.lastBootstrapResult?.status,
        ClashDebugBootstrapStatus.unauthorized,
      );
    });

    test('no se ejecuta bootstrap al construir controller', () {
      final client = _CountingSyncClient();
      _controller(client: client);

      expect(client.pullCalls, 0);
      expect(client.pushCalls, 0);
    });

    test('sin autenticación bootstrap no llama API', () async {
      final client = _CountingSyncClient();
      final controller = _controller(
        client: client,
        isAuthenticated: () async => false,
      );

      await controller.bootstrapOnlineSave();

      expect(client.pullCalls, 0);
      expect(client.pushCalls, 0);
      expect(controller.authRequired, isTrue);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashDebugSyncController _controller({
  ClashSyncClient? client,
  ClashSyncSnapshotApplier? applier,
  ClashSyncLocalBackupStore? backupStore,
  ClashSyncMetadataStorage? metadataStorage,
  ClashSyncSnapshotBuilder? builder,
  Future<bool> Function()? isAuthenticated,
}) {
  return ClashDebugSyncController(
    coordinator: ClashSyncCoordinator(
      builder: builder ?? _StubSnapshotBuilder(_validSnapshot()),
      validator: const ClashSyncSnapshotValidator(),
      client: client ?? FakeClashSyncClient(),
      now: () => _epoch,
    ),
    applier: applier,
    backupStore: backupStore,
    metadataStorage: metadataStorage,
    isAuthenticated: isAuthenticated,
  );
}

ClashSyncSnapshot _validSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: ClashStorageSchema.currentVersion,
    wallet: const ClashSyncWallet(coins: 1500, gems: 12),
    collection: const ClashSyncCollection(
      ownedCardIds: ['card-a'],
      uniqueCount: 1,
      totalCopies: 1,
    ),
  );
}

class _StubSnapshotBuilder extends ClashSyncSnapshotBuilder {
  _StubSnapshotBuilder(this._snapshot)
    : super(dependencies: const ClashSyncSnapshotBuilderDependencies());

  final ClashSyncSnapshot _snapshot;

  @override
  Future<ClashSyncSnapshot> build() async => _snapshot;
}

class _InvalidSnapshotBuilder extends ClashSyncSnapshotBuilder {
  _InvalidSnapshotBuilder()
    : super(dependencies: const ClashSyncSnapshotBuilderDependencies());

  @override
  Future<ClashSyncSnapshot> build() async {
    return ClashSyncSnapshot(
      generatedAt: _epoch,
      schemaVersion: 0,
      wallet: const ClashSyncWallet(coins: -1, gems: 0),
      collection: const ClashSyncCollection(
        ownedCardIds: [],
        uniqueCount: 0,
        totalCopies: 0,
      ),
    );
  }
}

class _UnauthorizedSyncClient extends ClashSyncClient {
  @override
  Future<ClashSyncPullResult> pullSnapshot() async {
    return ClashSyncPullResult.unavailable(
      message: 'Unauthorized',
      errorCode: 'unauthorized',
    );
  }

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) async {
    return ClashSyncPushResult.rejected(
      errorCode: 'unauthorized',
      message: 'Unauthorized',
    );
  }
}

class _CountingSyncClient extends FakeClashSyncClient {
  int pullCalls = 0;
  int pushCalls = 0;

  @override
  Future<ClashSyncPullResult> pullSnapshot() async {
    pullCalls += 1;
    return super.pullSnapshot();
  }

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) async {
    pushCalls += 1;
    return super.pushSnapshot(
      snapshot,
      expectedServerRevision: expectedServerRevision,
    );
  }
}

class _CountingApplier extends ClashSyncSnapshotApplier {
  _CountingApplier({ClashSyncApplyResult? result, SharedPreferences? prefs})
    : _result =
          result ??
          const ClashSyncApplyResult(
            status: ClashSyncApplyStatus.success,
            backupCreated: true,
          ),
      super(
        builder: _StubSnapshotBuilder(_validSnapshot()),
        validator: const ClashSyncSnapshotValidator(),
        dependencies: ClashSyncSnapshotApplierDependencies(
          sharedPreferences: prefs ?? countingApplierPrefs,
        ),
      );

  final ClashSyncApplyResult _result;
  int applyCalls = 0;

  @override
  Future<ClashSyncApplyResult> applyRemoteSnapshot(
    ClashSyncSnapshot remote, {
    int? serverRevision,
  }) async {
    applyCalls += 1;
    return _result;
  }
}

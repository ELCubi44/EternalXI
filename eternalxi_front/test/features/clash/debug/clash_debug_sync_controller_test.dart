import 'package:eternal_xi/features/clash/debug/data/clash_debug_sync_controller.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences countingApplierPrefs;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    countingApplierPrefs = await SharedPreferences.getInstance();
  });

  group('ClashDebugSyncController Fase 72', () {
    test('validateLocal muestra snapshot válido', () async {
      final controller = _controller();

      await controller.validateLocal();

      expect(controller.lastResult?.operation, ClashSyncOperation.validate);
      expect(controller.lastResult?.isSuccess, isTrue);
      expect(controller.lastResult?.validationResult?.isValid, isTrue);
    });

    test('pull notFound muestra estado notFound', () async {
      final controller = _controller();

      await controller.pullRemote();

      expect(controller.lastResult?.operation, ClashSyncOperation.pull);
      expect(controller.lastResult?.isNotFound, isTrue);
    });

    test('pull success guarda serverRevision', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.pushLocal();
      await controller.pullRemote();

      expect(controller.lastResult?.isSuccess, isTrue);
      expect(controller.lastResult?.serverRevision, 1);
      expect(controller.knownServerRevision, 1);
    });

    test('push sin remoto crea partida', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.pushLocal();

      expect(controller.lastResult?.operation, ClashSyncOperation.push);
      expect(controller.lastResult?.isSuccess, isTrue);
      expect(client.serverRevision, 1);
    });

    test('push con revision conocida actualiza', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.pushLocal();
      await controller.pushLocal();

      expect(controller.lastResult?.isSuccess, isTrue);
      expect(client.serverRevision, 2);
    });

    test('push conflict muestra conflicto sin aplicar remoto', () async {
      final client = FakeClashSyncClient();
      final controller = _controller(client: client);

      await controller.pushLocal();
      controller.knownServerRevision = 0;

      await controller.pushLocal();

      expect(controller.lastResult?.isConflict, isTrue);
      expect(controller.knownServerRevision, 1);
      expect(client.serverRevision, 1);
    });

    test('401/unavailable muestra authRequired o error controlado', () async {
      final controller = _controller(
        client: _UnauthorizedSyncClient(),
        isAuthenticated: () async => true,
      );

      await controller.pullRemote();

      expect(controller.lastResult?.errorCode, 'unauthorized');
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
      expect(controller.lastResult, isNull);
    });

    test('pull success guarda snapshot remoto sin aplicar', () async {
      final applier = _CountingApplier();
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, applier: applier);

      await controller.pushLocal();
      await controller.pullRemote();

      expect(controller.pendingRemoteSnapshot, isNotNull);
      expect(applier.applyCalls, 0);
      expect(controller.canApplyPendingRemote, isTrue);
    });

    test('applyPendingRemote aplica tras confirmación manual', () async {
      final applier = _CountingApplier();
      final client = FakeClashSyncClient();
      final controller = _controller(client: client, applier: applier);

      await controller.pushLocal();
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
      controller.lastResult = ClashSyncOperationResult.fromPull(
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
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashDebugSyncController _controller({
  ClashSyncClient? client,
  ClashSyncSnapshotApplier? applier,
  Future<bool> Function()? isAuthenticated,
}) {
  return ClashDebugSyncController(
    coordinator: ClashSyncCoordinator(
      builder: _StubSnapshotBuilder(_validSnapshot()),
      validator: const ClashSyncSnapshotValidator(),
      client: client ?? FakeClashSyncClient(),
      now: () => _epoch,
    ),
    applier: applier,
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

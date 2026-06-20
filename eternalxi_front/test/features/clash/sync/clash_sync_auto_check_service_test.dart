import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final epoch = DateTime.utc(2026, 6, 20, 12);

  group('ClashSyncAutoCheckService Fase 79', () {
    late SharedPreferences prefs;
    late ClashSyncSettingsStorage settingsStorage;
    late ClashSyncMetadataStorage metadataStorage;
    late _CountingSyncClient client;
    late ClashSyncCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settingsStorage = ClashSyncSettingsStorage(sharedPreferences: prefs);
      metadataStorage = ClashSyncMetadataStorage(sharedPreferences: prefs);
      client = _CountingSyncClient();
      coordinator = ClashSyncCoordinator(
        builder: _StubSnapshotBuilder(_validSnapshot()),
        validator: const ClashSyncSnapshotValidator(),
        client: client,
        now: () => epoch,
      );
    });

    ClashSyncAutoCheckService service({DateTime Function()? now}) {
      return ClashSyncAutoCheckService(
        coordinator: coordinator,
        settingsStorage: settingsStorage,
        metadataStorage: metadataStorage,
        now: now ?? (() => epoch),
      );
    }

    test('runIfEnabled con flag false no llama client', () async {
      final result = await service().runIfEnabled();

      expect(result, isNull);
      expect(client.pullCalls, 0);
      expect(client.pushCalls, 0);
    });

    test('runIfEnabled con true hace pull', () async {
      await settingsStorage.setAutoCheckEnabledOnClashOpen(true);
      await client.pushSnapshot(_validSnapshot());
      client.pushCalls = 0;

      final result = await service().runIfEnabled();

      expect(client.pullCalls, 1);
      expect(client.pushCalls, 0);
      expect(result?.isSuccess, isTrue);
    });

    test('success guarda pending y revision en metadata', () async {
      await settingsStorage.setAutoCheckEnabledOnClashOpen(true);
      await client.pushSnapshot(_validSnapshot());
      client.pushCalls = 0;

      await service().runIfEnabled();

      final metadata = metadataStorage.load();
      expect(metadata.knownServerRevision, 1);
      expect(metadata.hasPendingRemoteSnapshot, isTrue);
      expect(metadata.lastPullAt, epoch);
      expect(metadata.lastOperation, 'pull');
    });

    test('notFound no crea remoto ni pending', () async {
      await settingsStorage.setAutoCheckEnabledOnClashOpen(true);

      await service().runIfEnabled();

      expect(client.serverRevision, 0);
      expect(client.pushCalls, 0);
      final metadata = metadataStorage.load();
      expect(metadata.lastStatus, 'notFound');
      expect(metadata.hasPendingRemoteSnapshot, isFalse);
    });

    test('unauthorized guarda error en metadata', () async {
      await settingsStorage.setAutoCheckEnabledOnClashOpen(true);
      client.available = false;

      await service().runIfEnabled();

      final metadata = metadataStorage.load();
      expect(metadata.lastStatus, 'unavailable');
      expect(client.pullCalls, 1);
      expect(client.pushCalls, 0);
    });

    test('throttle evita pull si lastPullAt reciente', () async {
      await settingsStorage.setAutoCheckEnabledOnClashOpen(true);
      await client.pushSnapshot(_validSnapshot());
      client.pushCalls = 0;
      await service(now: () => epoch).runIfEnabled();

      final throttled = await service(
        now: () => epoch.add(const Duration(minutes: 2)),
      ).runIfEnabled();

      expect(throttled, isNull);
      expect(client.pullCalls, 1);
    });

    test('no llama push ni create', () async {
      await settingsStorage.setAutoCheckEnabledOnClashOpen(true);
      await client.pushSnapshot(_validSnapshot());
      client.pushCalls = 0;

      await service().runIfEnabled();

      expect(client.pushCalls, 0);
    });
  });
}

ClashSyncSnapshot _validSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: DateTime.utc(2026, 6, 20, 12),
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

import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_layer_http_guard.dart';

void main() {
  group('ClashSyncCoordinator Fase 68', () {
    test('validateLocalSnapshotOnly construye y valida snapshot', () async {
      final snapshot = _validSnapshot();
      final coordinator = _coordinator(snapshot: snapshot);

      final result = await coordinator.validateLocalSnapshotOnly();

      expect(result.operation, ClashSyncOperation.validate);
      expect(result.isSuccess, isTrue);
      expect(result.snapshot, snapshot);
      expect(result.validationResult?.isValid, isTrue);
      expect(result.startedAt, _epoch);
      expect(result.completedAt, _epoch);
    });

    test('push válido llama fake client y devuelve success', () async {
      final client = _SpySyncClient();
      final snapshot = _validSnapshot();
      final coordinator = _coordinator(snapshot: snapshot, client: client);

      final result = await coordinator.pushLocalSnapshot();

      expect(client.pushCallCount, 1);
      expect(result.operation, ClashSyncOperation.push);
      expect(result.isSuccess, isTrue);
      expect(result.serverRevision, 1);
      expect(result.snapshot, snapshot);
    });

    test('push inválido no llama client', () async {
      final client = _SpySyncClient();
      final coordinator = _coordinator(
        snapshot: _invalidSnapshot(),
        client: client,
      );

      final result = await coordinator.pushLocalSnapshot();

      expect(client.pushCallCount, 0);
      expect(result.operation, ClashSyncOperation.push);
      expect(result.isValidationFailed, isTrue);
      expect(result.validationResult?.isValid, isFalse);
      expect(result.errorCode, 'validation_failed');
    });

    test('push con expectedRevision incorrecta devuelve conflict', () async {
      final client = FakeClashSyncClient();
      final snapshot = _validSnapshot();
      final coordinator = _coordinator(snapshot: snapshot, client: client);

      await coordinator.pushLocalSnapshot();

      final conflict = await coordinator.pushLocalSnapshot(
        expectedServerRevision: 0,
      );

      expect(conflict.operation, ClashSyncOperation.push);
      expect(conflict.isConflict, isTrue);
      expect(conflict.conflict?.expectedRevision, 0);
      expect(conflict.conflict?.actualRevision, 1);
    });

    test('pull sin remoto devuelve notFound', () async {
      final coordinator = _coordinator(snapshot: _validSnapshot());

      final result = await coordinator.pullRemoteSnapshot();

      expect(result.operation, ClashSyncOperation.pull);
      expect(result.isNotFound, isTrue);
    });

    test('pull después de push devuelve snapshot validado', () async {
      final client = FakeClashSyncClient();
      final snapshot = _validSnapshot();
      final coordinator = _coordinator(snapshot: snapshot, client: client);

      await coordinator.pushLocalSnapshot();

      final pull = await coordinator.pullRemoteSnapshot();

      expect(pull.operation, ClashSyncOperation.pull);
      expect(pull.isSuccess, isTrue);
      expect(pull.snapshot, snapshot);
      expect(pull.serverRevision, 1);
      expect(pull.validationResult?.isValid, isTrue);
    });

    test(
      'pull remoto inválido devuelve validationFailed sin aplicar',
      () async {
        final client = _PullInvalidRemoteClient(_invalidSnapshot());
        final coordinator = _coordinator(
          snapshot: _validSnapshot(),
          client: client,
        );

        final pull = await coordinator.pullRemoteSnapshot();

        expect(pull.operation, ClashSyncOperation.pull);
        expect(pull.isValidationFailed, isTrue);
        expect(pull.errorCode, 'validation_failed');
        expect(pull.snapshot, _invalidSnapshot());
      },
    );

    test('timestamps son inyectables y estables', () async {
      var tick = 0;
      final times = [
        DateTime.utc(2026, 6, 20, 10),
        DateTime.utc(2026, 6, 20, 10, 0, 1),
      ];
      final coordinator = ClashSyncCoordinator(
        builder: _StubSnapshotBuilder(_validSnapshot()),
        validator: const ClashSyncSnapshotValidator(),
        client: FakeClashSyncClient(),
        now: () => times[tick++],
      );

      final result = await coordinator.validateLocalSnapshotOnly();

      expect(result.startedAt, times[0]);
      expect(result.completedAt, times[1]);
    });

    test('coordinator no importa HTTP/API client', () {
      expect(findForbiddenHttpImportsInSyncLayer(), isEmpty);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashSyncCoordinator _coordinator({
  required ClashSyncSnapshot snapshot,
  ClashSyncClient? client,
}) {
  return ClashSyncCoordinator(
    builder: _StubSnapshotBuilder(snapshot),
    validator: const ClashSyncSnapshotValidator(),
    client: client ?? FakeClashSyncClient(),
    now: () => _epoch,
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

ClashSyncSnapshot _invalidSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: 0,
    wallet: const ClashSyncWallet(coins: -1),
  );
}

class _StubSnapshotBuilder extends ClashSyncSnapshotBuilder {
  _StubSnapshotBuilder(this._snapshot)
    : super(dependencies: const ClashSyncSnapshotBuilderDependencies());

  final ClashSyncSnapshot _snapshot;

  @override
  Future<ClashSyncSnapshot> build() async => _snapshot;
}

class _SpySyncClient extends FakeClashSyncClient {
  int pushCallCount = 0;

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) async {
    pushCallCount += 1;
    return super.pushSnapshot(
      snapshot,
      expectedServerRevision: expectedServerRevision,
    );
  }
}

class _PullInvalidRemoteClient extends ClashSyncClient {
  _PullInvalidRemoteClient(this._invalid);

  final ClashSyncSnapshot _invalid;

  @override
  Future<ClashSyncPullResult> pullSnapshot() async {
    return ClashSyncPullResult.success(serverRevision: 1, snapshot: _invalid);
  }

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) {
    return Future.value(ClashSyncPushResult.unavailable());
  }
}

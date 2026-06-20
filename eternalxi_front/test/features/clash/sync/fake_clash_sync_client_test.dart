import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_layer_http_guard.dart';

void main() {
  group('FakeClashSyncClient Fase 67', () {
    test('pull sin snapshot devuelve notFound', () async {
      final client = FakeClashSyncClient();

      final result = await client.pullSnapshot();

      expect(result.isNotFound, isTrue);
      expect(result.serverRevision, 0);
      expect(result.snapshot, isNull);
      expect(result.errorCode, 'not_found');
    });

    test('push válido devuelve success y revision 1', () async {
      final client = FakeClashSyncClient();

      final push = await client.pushSnapshot(_validSnapshot());

      expect(push.isSuccess, isTrue);
      expect(push.serverRevision, 1);
      expect(push.snapshot, _validSnapshot());
      expect(client.serverRevision, 1);
    });

    test('pull después de push devuelve snapshot', () async {
      final client = FakeClashSyncClient();
      final snapshot = _validSnapshot();
      await client.pushSnapshot(snapshot);

      final pull = await client.pullSnapshot();

      expect(pull.isSuccess, isTrue);
      expect(pull.serverRevision, 1);
      expect(pull.snapshot, snapshot);
    });

    test('segundo push válido incrementa revision', () async {
      final client = FakeClashSyncClient();
      await client.pushSnapshot(_validSnapshot());

      final updated = _validSnapshot().copyWith(
        wallet: const ClashSyncWallet(coins: 2000, gems: 20),
      );
      final second = await client.pushSnapshot(
        updated,
        expectedServerRevision: 1,
      );

      expect(second.isSuccess, isTrue);
      expect(second.serverRevision, 2);
      expect(client.serverRevision, 2);

      final pull = await client.pullSnapshot();
      expect(pull.snapshot?.wallet.coins, 2000);
    });

    test(
      'push inválido devuelve validationFailed y no pisa snapshot remoto',
      () async {
        final client = FakeClashSyncClient();
        final valid = _validSnapshot();
        await client.pushSnapshot(valid);

        final invalid = valid.copyWith(
          wallet: const ClashSyncWallet(coins: -5),
        );
        final failed = await client.pushSnapshot(invalid);

        expect(failed.isValidationFailed, isTrue);
        expect(failed.validationResult?.isValid, isFalse);
        expect(failed.errorCode, 'validation_failed');
        expect(client.serverRevision, 1);

        final pull = await client.pullSnapshot();
        expect(pull.snapshot, valid);
      },
    );

    test('conflict si expectedServerRevision no coincide', () async {
      final client = FakeClashSyncClient();
      await client.pushSnapshot(_validSnapshot());

      final conflict = await client.pushSnapshot(
        _validSnapshot().copyWith(wallet: const ClashSyncWallet(coins: 9999)),
        expectedServerRevision: 0,
      );

      expect(conflict.isConflict, isTrue);
      expect(conflict.errorCode, 'revision_conflict');
      expect(conflict.conflict?.expectedRevision, 0);
      expect(conflict.conflict?.actualRevision, 1);
      expect(conflict.conflict?.remoteSnapshot, _validSnapshot());
      expect(client.serverRevision, 1);

      final pull = await client.pullSnapshot();
      expect(pull.snapshot?.wallet.coins, 1500);
    });

    test('rejected si contractVersion no soportada', () async {
      final client = FakeClashSyncClient();
      final snapshot = _validSnapshot().copyWith(contractVersion: 99);

      final result = await client.pushSnapshot(snapshot);

      expect(result.isRejected, isTrue);
      expect(result.errorCode, 'unsupported_contract_version');
      expect(result.status, ClashSyncStatus.rejected);
      expect(client.serverRevision, 0);
      expect((await client.pullSnapshot()).isNotFound, isTrue);
    });

    test('unavailable cuando el cliente fake está deshabilitado', () async {
      final client = FakeClashSyncClient()..available = false;

      final push = await client.pushSnapshot(_validSnapshot());
      final pull = await client.pullSnapshot();

      expect(push.status, ClashSyncStatus.unavailable);
      expect(pull.status, ClashSyncStatus.unavailable);
    });

    test('cliente fake no importa HTTP/API client', () {
      expect(findForbiddenHttpImportsInSyncLayer(), isEmpty);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashSyncSnapshot _validSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: ClashStorageSchema.currentVersion,
    wallet: const ClashSyncWallet(coins: 1500, gems: 12),
    collection: const ClashSyncCollection(
      ownedCardIds: ['card-a', 'card-b'],
      uniqueCount: 2,
      totalCopies: 3,
      duplicateCopies: 1,
    ),
    gachaState: const ClashSyncGachaState(
      pityByBanner: [
        ClashSyncGachaPityState(
          bannerId: 'starter-banner-001',
          pullsSinceLastPity: 0,
        ),
      ],
    ),
  );
}

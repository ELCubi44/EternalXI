import 'dart:io';

import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_save_api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/http_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_contract.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_contract_version.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpClashSyncClient Fase 71', () {
    test('pullSnapshot traduce GET 200 a success', () async {
      final api = _FakeSaveApiPort(getResult: _saveResponse(revision: 2));
      final client = HttpClashSyncClient(api);

      final pull = await client.pullSnapshot();

      expect(pull.isSuccess, isTrue);
      expect(pull.serverRevision, 2);
      expect(pull.snapshot?.wallet.coins, 1500);
    });

    test('pullSnapshot traduce GET null a notFound', () async {
      final client = HttpClashSyncClient(_FakeSaveApiPort());

      final pull = await client.pullSnapshot();

      expect(pull.isNotFound, isTrue);
    });

    test('pushSnapshot con expectedRevision usa updateSave', () async {
      final api = _FakeSaveApiPort(updateResult: _saveResponse(revision: 3));
      final client = HttpClashSyncClient(api);

      final push = await client.pushSnapshot(
        _sampleSnapshot(),
        expectedServerRevision: 2,
      );

      expect(api.updateCalls, 1);
      expect(api.createCalls, 0);
      expect(push.isSuccess, isTrue);
      expect(push.serverRevision, 3);
    });

    test('pushSnapshot sin expectedRevision usa createSave', () async {
      final api = _FakeSaveApiPort(createResult: _saveResponse(revision: 1));
      final client = HttpClashSyncClient(api);

      final push = await client.pushSnapshot(_sampleSnapshot());

      expect(api.createCalls, 1);
      expect(api.updateCalls, 0);
      expect(push.isSuccess, isTrue);
    });

    test('pushSnapshot traduce conflicto 409', () async {
      final api = _FakeSaveApiPort(
        updateError: ClashSaveConflictException(
          conflictResponse: ClashSaveConflictResponse(
            serverRevision: 4,
            serverSaveData: _sampleSnapshot(),
            clientRejectedReason: 'expectedServerRevision 2 != current 4',
          ),
        ),
      );
      final client = HttpClashSyncClient(api);

      final push = await client.pushSnapshot(
        _sampleSnapshot(),
        expectedServerRevision: 2,
      );

      expect(push.isConflict, isTrue);
      expect(push.conflict?.actualRevision, 4);
    });

    test('pushSnapshot traduce notFound en update', () async {
      final api = _FakeSaveApiPort(
        updateError: const ClashSaveNotFoundException(),
      );
      final client = HttpClashSyncClient(api);

      final push = await client.pushSnapshot(
        _sampleSnapshot(),
        expectedServerRevision: 1,
      );

      expect(push.isRejected, isTrue);
      expect(push.errorCode, 'CLASH_SAVE_NOT_FOUND');
    });

    test('no importa backend ni hace llamadas reales', () {
      final syncDir = Directory('lib/features/clash/sync');
      final forbidden = <String>[];

      for (final entity in syncDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        if (!entity.path.contains('http_clash_sync_client') &&
            !entity.path.contains('clash_save_api_client')) {
          continue;
        }
        final content = entity.readAsStringSync();
        if (content.contains('eternalxi_api_back') ||
            content.contains('Spring') ||
            content.contains('217.154.184.202')) {
          forbidden.add(entity.path);
        }
      }

      expect(forbidden, isEmpty);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

class _FakeSaveApiPort implements ClashSaveApiPort {
  _FakeSaveApiPort({
    this.getResult,
    this.createResult,
    this.updateResult,
    this.updateError,
  });

  final ClashSaveResponse? getResult;
  final ClashSaveResponse? createResult;
  final ClashSaveResponse? updateResult;
  final ClashSaveApiException? updateError;

  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<ClashSaveResponse?> getSave() async => getResult;

  @override
  Future<ClashSaveResponse> createSave(ClashSaveUpdateRequest request) async {
    createCalls += 1;
    return createResult ?? _saveResponse(revision: 1);
  }

  @override
  Future<ClashSaveResponse> updateSave(ClashSaveUpdateRequest request) async {
    updateCalls += 1;
    if (updateError != null) {
      throw updateError!;
    }
    return updateResult ?? _saveResponse(revision: 2);
  }
}

ClashSaveResponse _saveResponse({required int revision}) {
  return ClashSaveResponse(
    serverRevision: revision,
    contractVersion: ClashSyncContractVersion.current,
    schemaVersion: ClashStorageSchema.currentVersion,
    saveData: _sampleSnapshot(),
    updatedAt: _epoch,
  );
}

ClashSyncSnapshot _sampleSnapshot() {
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

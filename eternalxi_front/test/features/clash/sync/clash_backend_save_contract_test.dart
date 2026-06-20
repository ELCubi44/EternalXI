import 'dart:io';

import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_contract.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_contract_version.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clash backend save contract Fase 69', () {
    test('ClashSaveUpdateRequest serializa expectedServerRevision', () {
      final request = ClashSaveUpdateRequest(
        expectedServerRevision: 2,
        contractVersion: ClashSyncContractVersion.current,
        schemaVersion: ClashStorageSchema.currentVersion,
        saveData: _sampleSaveData(),
        clientGeneratedAt: _epoch,
      );

      final json = request.toJson();

      expect(json['expectedServerRevision'], 2);
      expect(json['contractVersion'], 1);
      expect(json['saveData'], isA<Map>());
      expect(json['clientGeneratedAt'], '2026-06-20T12:00:00.000Z');
    });

    test('ClashSaveResponse deserializa saveData', () {
      final decoded = ClashSaveResponse.fromJson({
        'serverRevision': 3,
        'contractVersion': 1,
        'schemaVersion': 1,
        'updatedAt': '2026-06-20T14:30:00.000Z',
        'saveData': _sampleSaveData().toJson(),
      });

      expect(decoded.serverRevision, 3);
      expect(decoded.saveData.wallet.coins, 1500);
      expect(decoded.updatedAt, DateTime.utc(2026, 6, 20, 14, 30));
    });

    test('ClashSaveConflictResponse deserializa serverSaveData', () {
      final conflict = ClashSaveConflictResponse.fromJson({
        'serverRevision': 3,
        'serverSaveData': _sampleSaveData().toJson(),
        'clientRejectedReason': 'expectedServerRevision 2 != current 3',
      });

      expect(conflict.serverRevision, 3);
      expect(conflict.serverSaveData.collection.uniqueCount, 1);
      expect(
        conflict.clientRejectedReason,
        'expectedServerRevision 2 != current 3',
      );
    });

    test('ClashSaveClaimRequest serializa claimId y campos opcionales', () {
      const claim = ClashSaveClaimRequest(
        claimId: 'gift:gift-welcome',
        claimType: 'gift',
        sourceId: 'gift-welcome',
        expectedServerRevision: 3,
      );

      final json = claim.toJson();
      final roundTrip = ClashSaveClaimRequest.fromJson(json);

      expect(json['claimId'], 'gift:gift-welcome');
      expect(json['expectedServerRevision'], 3);
      expect(roundTrip, claim);
    });

    test('round-trip ClashSaveUpdateRequest mantiene campos', () {
      final original = ClashSaveUpdateRequest(
        expectedServerRevision: 5,
        contractVersion: 1,
        schemaVersion: 1,
        saveData: _sampleSaveData(),
        clientGeneratedAt: _epoch,
      );

      final decoded = ClashSaveUpdateRequest.fromJson(original.toJson());

      expect(decoded, original);
    });

    test('módulo save contract no importa HTTP/API', () {
      final paths = ['lib/features/clash/sync/domain/clash_save_contract.dart'];
      final forbidden = <String>[];

      for (final path in paths) {
        final file = File(path);
        final content = file.readAsStringSync();
        if (content.contains("import 'package:http/") ||
            content.contains('package:dio/') ||
            content.contains('ClashApiClient')) {
          forbidden.add(path);
        }
      }

      expect(forbidden, isEmpty);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashSyncSnapshot _sampleSaveData() {
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

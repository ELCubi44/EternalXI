import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_validation_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final epoch = DateTime.utc(2026, 6, 20, 12);

  group('ClashSyncMetadataStorage Fase 76', () {
    late SharedPreferences prefs;
    late ClashSyncMetadataStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = ClashSyncMetadataStorage(sharedPreferences: prefs);
    });

    test('load devuelve defaults seguros si no hay datos', () {
      final metadata = storage.load();

      expect(metadata, const ClashSyncMetadata());
      expect(metadata.knownServerRevision, isNull);
    });

    test('pull success guarda revision y lastPullAt', () async {
      final result = ClashSyncOperationResult.fromPull(
        pullResult: ClashSyncPullResult.success(
          snapshot: _snapshot(),
          serverRevision: 2,
        ),
        startedAt: epoch,
        completedAt: epoch,
      );

      final metadata = await storage.updateAfterOperation(
        result,
        hasPendingRemoteSnapshot: true,
        hasLocalBackup: false,
      );

      expect(metadata.knownServerRevision, 2);
      expect(metadata.lastPullAt, epoch);
      expect(metadata.lastOperation, 'pull');
      expect(metadata.lastStatus, 'success');
      expect(metadata.hasPendingRemoteSnapshot, isTrue);
      expect(storage.load().knownServerRevision, 2);
    });

    test('push success guarda revision y lastPushAt', () async {
      final result = ClashSyncOperationResult.fromPush(
        pushResult: ClashSyncPushResult.success(
          serverRevision: 3,
          snapshot: _snapshot(),
        ),
        startedAt: epoch,
        completedAt: epoch,
      );

      final metadata = await storage.updateAfterOperation(
        result,
        hasPendingRemoteSnapshot: false,
        hasLocalBackup: true,
      );

      expect(metadata.knownServerRevision, 3);
      expect(metadata.lastPushAt, epoch);
      expect(metadata.lastSuccessfulSyncAt, epoch);
      expect(metadata.lastOperation, 'push');
      expect(metadata.hasLocalBackup, isTrue);
    });

    test('conflict guarda lastConflictServerRevision y error', () async {
      final result = ClashSyncOperationResult.fromPush(
        pushResult: ClashSyncPushResult.conflict(
          conflict: const ClashSyncConflict(
            expectedRevision: 1,
            actualRevision: 4,
          ),
        ),
        startedAt: epoch,
        completedAt: epoch,
      );

      final metadata = await storage.updateAfterOperation(
        result,
        hasPendingRemoteSnapshot: false,
        hasLocalBackup: false,
      );

      expect(metadata.knownServerRevision, 4);
      expect(metadata.lastConflictServerRevision, 4);
      expect(metadata.lastStatus, 'conflict');
      expect(metadata.lastErrorCode, 'revision_conflict');
    });

    test('validate no hace HTTP pero actualiza estado', () async {
      final result = ClashSyncOperationResult.fromValidation(
        validationResult: ClashSyncValidationResult.empty(checkedAt: epoch),
        snapshot: _snapshot(),
        startedAt: epoch,
        completedAt: epoch,
      );

      final metadata = await storage.updateAfterOperation(
        result,
        hasPendingRemoteSnapshot: false,
        hasLocalBackup: false,
      );

      expect(metadata.lastOperation, 'validate');
      expect(metadata.lastStatus, 'success');
      expect(metadata.lastPullAt, isNull);
      expect(metadata.lastPushAt, isNull);
    });

    test('clearLastError limpia error persistido', () async {
      await storage.save(
        const ClashSyncMetadata(
          lastErrorCode: 'unauthorized',
          lastMessage: 'Unauthorized',
          lastConflictServerRevision: 2,
        ),
      );

      final cleared = await storage.clearLastError();

      expect(cleared.lastErrorCode, isNull);
      expect(cleared.lastMessage, isNull);
      expect(cleared.lastConflictServerRevision, isNull);
      expect(storage.load().lastErrorCode, isNull);
    });

    test('updateAfterApply guarda lastApplyAt', () async {
      final metadata = await storage.updateAfterApply(
        ClashSyncApplyResult(
          status: ClashSyncApplyStatus.success,
          appliedAt: epoch,
          backupCreated: true,
        ),
        isRestore: false,
        hasPendingRemoteSnapshot: false,
        hasLocalBackup: true,
      );

      expect(metadata.lastOperation, 'apply');
      expect(metadata.lastApplyAt, epoch);
      expect(metadata.lastSuccessfulSyncAt, epoch);
      expect(metadata.hasLocalBackup, isTrue);
    });

    test('storageKey no está en dataKeys', () {
      expect(
        ClashSyncMetadataStorage.storageKey,
        ClashSharedPreferencesKeys.syncMetadata,
      );
      expect(
        ClashSharedPreferencesKeys.dataKeys,
        isNot(contains(ClashSharedPreferencesKeys.syncMetadata)),
      );
    });

    test('JSON corrupto devuelve defaults', () async {
      await prefs.setString(ClashSyncMetadataStorage.storageKey, '{bad json');

      expect(storage.load(), const ClashSyncMetadata());
    });
  });
}

ClashSyncSnapshot _snapshot() {
  return ClashSyncSnapshot(
    generatedAt: DateTime.utc(2026, 6, 20, 12),
    schemaVersion: ClashStorageSchema.currentVersion,
    wallet: const ClashSyncWallet(coins: 100, gems: 1),
    collection: const ClashSyncCollection(
      ownedCardIds: ['card-a'],
      uniqueCount: 1,
      totalCopies: 1,
    ),
  );
}

import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClashSyncMetadata Fase 76', () {
    final epoch = DateTime.utc(2026, 6, 20, 12);

    test('serializa y deserializa sin perder campos', () {
      const metadata = ClashSyncMetadata(
        knownServerRevision: 3,
        lastSuccessfulSyncAt: null,
        lastPullAt: null,
        lastPushAt: null,
        lastApplyAt: null,
        lastRestoreAt: null,
        lastOperation: 'push',
        lastStatus: 'success',
        lastErrorCode: null,
        lastMessage: null,
        lastConflictServerRevision: null,
        hasPendingRemoteSnapshot: true,
        hasLocalBackup: false,
      );

      final restored = ClashSyncMetadata.fromJson(metadata.toJson());

      expect(restored.knownServerRevision, 3);
      expect(restored.lastOperation, 'push');
      expect(restored.lastStatus, 'success');
      expect(restored.hasPendingRemoteSnapshot, isTrue);
      expect(restored.hasLocalBackup, isFalse);
    });

    test('fromJson tolera payload vacío', () {
      final metadata = ClashSyncMetadata.fromJson({});

      expect(metadata.knownServerRevision, isNull);
      expect(metadata.hasPendingRemoteSnapshot, isFalse);
      expect(metadata.hasLocalBackup, isFalse);
    });

    test('copyWith limpia error y conflicto', () {
      const metadata = ClashSyncMetadata(
        lastErrorCode: 'conflict',
        lastMessage: 'Conflict',
        lastConflictServerRevision: 2,
      );

      final cleared = metadata.copyWith(clearError: true, clearConflict: true);

      expect(cleared.lastErrorCode, isNull);
      expect(cleared.lastMessage, isNull);
      expect(cleared.lastConflictServerRevision, isNull);
    });

    test('lastOperationEnum y lastStatusEnum resuelven valores', () {
      const metadata = ClashSyncMetadata(
        lastOperation: 'pull',
        lastStatus: 'conflict',
      );

      expect(metadata.lastOperationEnum, ClashSyncOperation.pull);
      expect(metadata.lastStatusEnum, ClashSyncStatus.conflict);
    });

    test('round-trip con timestamps', () {
      final metadata = ClashSyncMetadata(
        lastSuccessfulSyncAt: epoch,
        lastPullAt: epoch,
        lastPushAt: epoch,
      );

      final restored = ClashSyncMetadata.fromJson(metadata.toJson());

      expect(restored.lastSuccessfulSyncAt?.toUtc(), epoch);
      expect(restored.lastPullAt?.toUtc(), epoch);
      expect(restored.lastPushAt?.toUtc(), epoch);
    });
  });
}

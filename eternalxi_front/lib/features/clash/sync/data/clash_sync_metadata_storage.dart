import 'dart:convert';

import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste metadatos locales de sync (Fase 76). No guarda snapshots ni tokens.
class ClashSyncMetadataStorage {
  const ClashSyncMetadataStorage({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  static const storageKey = ClashSharedPreferencesKeys.syncMetadata;

  ClashSyncMetadata load() {
    final raw = sharedPreferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const ClashSyncMetadata();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const ClashSyncMetadata();
      }
      return ClashSyncMetadata.fromJson(decoded);
    } catch (_) {
      return const ClashSyncMetadata();
    }
  }

  Future<bool> save(ClashSyncMetadata metadata) async {
    try {
      return await sharedPreferences.setString(
        storageKey,
        jsonEncode(metadata.toJson()),
      );
    } catch (_) {
      return false;
    }
  }

  Future<ClashSyncMetadata> clearLastError() async {
    final cleared = load().copyWith(clearError: true, clearConflict: true);
    await save(cleared);
    return cleared;
  }

  Future<ClashSyncMetadata> updateAfterOperation(
    ClashSyncOperationResult result, {
    required bool hasPendingRemoteSnapshot,
    required bool hasLocalBackup,
  }) async {
    final current = load();
    final completedAt = result.completedAt ?? DateTime.now().toUtc();
    var next = current.copyWith(
      lastOperation: result.operation.name,
      lastStatus: result.status.name,
      hasPendingRemoteSnapshot: hasPendingRemoteSnapshot,
      hasLocalBackup: hasLocalBackup,
    );

    if (result.isSuccess) {
      next = next.copyWith(clearError: true, clearConflict: true);
    } else {
      next = next.copyWith(
        lastErrorCode: result.errorCode,
        lastMessage: result.message,
      );
    }

    if (result.isSuccess && result.serverRevision != null) {
      next = next.copyWith(knownServerRevision: result.serverRevision);
    }
    if (result.isConflict && result.conflict != null) {
      next = next.copyWith(
        knownServerRevision: result.conflict!.actualRevision,
        lastConflictServerRevision: result.conflict!.actualRevision,
      );
    }

    switch (result.operation) {
      case ClashSyncOperation.validate:
        break;
      case ClashSyncOperation.pull:
        next = next.copyWith(lastPullAt: completedAt);
      case ClashSyncOperation.push:
        next = next.copyWith(lastPushAt: completedAt);
        if (result.isSuccess) {
          next = next.copyWith(lastSuccessfulSyncAt: completedAt);
        }
    }

    await save(next);
    return next;
  }

  Future<ClashSyncMetadata> updateAfterApply(
    ClashSyncApplyResult result, {
    required bool isRestore,
    required bool hasPendingRemoteSnapshot,
    required bool hasLocalBackup,
  }) async {
    final current = load();
    final completedAt = result.appliedAt ?? DateTime.now().toUtc();
    final statusName = _applyStatusName(result.status);

    var next = current.copyWith(
      lastOperation: isRestore ? 'restore' : 'apply',
      lastStatus: statusName,
      hasPendingRemoteSnapshot: hasPendingRemoteSnapshot,
      hasLocalBackup: hasLocalBackup,
    );

    if (result.isSuccess) {
      next = next.copyWith(
        clearError: true,
        clearConflict: true,
        lastSuccessfulSyncAt: completedAt,
      );
    } else {
      next = next.copyWith(
        lastErrorCode: result.errorCode ?? statusName,
        lastMessage: result.message,
      );
    }

    if (isRestore) {
      next = next.copyWith(lastRestoreAt: completedAt);
    } else {
      next = next.copyWith(lastApplyAt: completedAt);
    }

    await save(next);
    return next;
  }

  String _applyStatusName(ClashSyncApplyStatus status) {
    return switch (status) {
      ClashSyncApplyStatus.success => ClashSyncStatus.success.name,
      ClashSyncApplyStatus.validationFailed =>
        ClashSyncStatus.validationFailed.name,
      ClashSyncApplyStatus.backupFailed => ClashSyncStatus.rejected.name,
      ClashSyncApplyStatus.applyFailed => ClashSyncStatus.rejected.name,
      ClashSyncApplyStatus.unsupported => ClashSyncStatus.rejected.name,
    };
  }
}

import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';

/// Metadatos locales de sync Clash (Fase 76). JSON pequeño, sin snapshots.
class ClashSyncMetadata {
  const ClashSyncMetadata({
    this.knownServerRevision,
    this.lastSuccessfulSyncAt,
    this.lastPullAt,
    this.lastPushAt,
    this.lastApplyAt,
    this.lastRestoreAt,
    this.lastOperation,
    this.lastStatus,
    this.lastErrorCode,
    this.lastMessage,
    this.lastConflictServerRevision,
    this.hasPendingRemoteSnapshot = false,
    this.hasLocalBackup = false,
  });

  final int? knownServerRevision;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastPullAt;
  final DateTime? lastPushAt;
  final DateTime? lastApplyAt;
  final DateTime? lastRestoreAt;
  final String? lastOperation;
  final String? lastStatus;
  final String? lastErrorCode;
  final String? lastMessage;
  final int? lastConflictServerRevision;
  final bool hasPendingRemoteSnapshot;
  final bool hasLocalBackup;

  ClashSyncOperation? get lastOperationEnum {
    final raw = lastOperation;
    if (raw == null) {
      return null;
    }
    for (final value in ClashSyncOperation.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  ClashSyncStatus? get lastStatusEnum {
    final raw = lastStatus;
    if (raw == null) {
      return null;
    }
    for (final value in ClashSyncStatus.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (knownServerRevision != null) 'knownServerRevision': knownServerRevision,
    if (lastSuccessfulSyncAt != null)
      'lastSuccessfulSyncAt': lastSuccessfulSyncAt!.toUtc().toIso8601String(),
    if (lastPullAt != null) 'lastPullAt': lastPullAt!.toUtc().toIso8601String(),
    if (lastPushAt != null) 'lastPushAt': lastPushAt!.toUtc().toIso8601String(),
    if (lastApplyAt != null)
      'lastApplyAt': lastApplyAt!.toUtc().toIso8601String(),
    if (lastRestoreAt != null)
      'lastRestoreAt': lastRestoreAt!.toUtc().toIso8601String(),
    if (lastOperation != null) 'lastOperation': lastOperation,
    if (lastStatus != null) 'lastStatus': lastStatus,
    if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (lastConflictServerRevision != null)
      'lastConflictServerRevision': lastConflictServerRevision,
    'hasPendingRemoteSnapshot': hasPendingRemoteSnapshot,
    'hasLocalBackup': hasLocalBackup,
  };

  factory ClashSyncMetadata.fromJson(Map<String, dynamic> json) {
    return ClashSyncMetadata(
      knownServerRevision: _readOptionalInt(json['knownServerRevision']),
      lastSuccessfulSyncAt: _readOptionalDate(json['lastSuccessfulSyncAt']),
      lastPullAt: _readOptionalDate(json['lastPullAt']),
      lastPushAt: _readOptionalDate(json['lastPushAt']),
      lastApplyAt: _readOptionalDate(json['lastApplyAt']),
      lastRestoreAt: _readOptionalDate(json['lastRestoreAt']),
      lastOperation: json['lastOperation']?.toString(),
      lastStatus: json['lastStatus']?.toString(),
      lastErrorCode: json['lastErrorCode']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastConflictServerRevision: _readOptionalInt(
        json['lastConflictServerRevision'],
      ),
      hasPendingRemoteSnapshot: json['hasPendingRemoteSnapshot'] == true,
      hasLocalBackup: json['hasLocalBackup'] == true,
    );
  }

  ClashSyncMetadata copyWith({
    int? knownServerRevision,
    DateTime? lastSuccessfulSyncAt,
    DateTime? lastPullAt,
    DateTime? lastPushAt,
    DateTime? lastApplyAt,
    DateTime? lastRestoreAt,
    String? lastOperation,
    String? lastStatus,
    String? lastErrorCode,
    String? lastMessage,
    int? lastConflictServerRevision,
    bool? hasPendingRemoteSnapshot,
    bool? hasLocalBackup,
    bool clearError = false,
    bool clearConflict = false,
  }) {
    return ClashSyncMetadata(
      knownServerRevision: knownServerRevision ?? this.knownServerRevision,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      lastApplyAt: lastApplyAt ?? this.lastApplyAt,
      lastRestoreAt: lastRestoreAt ?? this.lastRestoreAt,
      lastOperation: lastOperation ?? this.lastOperation,
      lastStatus: lastStatus ?? this.lastStatus,
      lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
      lastMessage: clearError ? null : (lastMessage ?? this.lastMessage),
      lastConflictServerRevision: clearConflict
          ? null
          : (lastConflictServerRevision ?? this.lastConflictServerRevision),
      hasPendingRemoteSnapshot:
          hasPendingRemoteSnapshot ?? this.hasPendingRemoteSnapshot,
      hasLocalBackup: hasLocalBackup ?? this.hasLocalBackup,
    );
  }
}

DateTime? _readOptionalDate(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

int? _readOptionalInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

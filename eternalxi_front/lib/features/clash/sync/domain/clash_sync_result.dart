import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_validation_result.dart';

/// Estado de una operación de sync Clash (Fase 67).
enum ClashSyncStatus {
  success,
  validationFailed,
  conflict,
  rejected,
  notFound,
  unavailable,
}

/// Detalle de conflicto de revisión entre cliente y servidor simulado.
class ClashSyncConflict {
  const ClashSyncConflict({
    required this.expectedRevision,
    required this.actualRevision,
    this.remoteSnapshot,
  });

  final int? expectedRevision;
  final int actualRevision;
  final ClashSyncSnapshot? remoteSnapshot;
}

/// Resultado de subir un snapshot al servidor (real o fake).
class ClashSyncPushResult {
  const ClashSyncPushResult({
    required this.status,
    this.serverRevision,
    this.snapshot,
    this.validationResult,
    this.conflict,
    this.message,
    this.errorCode,
  });

  final ClashSyncStatus status;
  final int? serverRevision;
  final ClashSyncSnapshot? snapshot;
  final ClashSyncValidationResult? validationResult;
  final ClashSyncConflict? conflict;
  final String? message;
  final String? errorCode;

  bool get isSuccess => status == ClashSyncStatus.success;

  bool get isValidationFailed => status == ClashSyncStatus.validationFailed;

  bool get isConflict => status == ClashSyncStatus.conflict;

  bool get isRejected => status == ClashSyncStatus.rejected;

  factory ClashSyncPushResult.success({
    required int serverRevision,
    ClashSyncSnapshot? snapshot,
  }) {
    return ClashSyncPushResult(
      status: ClashSyncStatus.success,
      serverRevision: serverRevision,
      snapshot: snapshot,
    );
  }

  factory ClashSyncPushResult.validationFailed({
    required ClashSyncValidationResult validationResult,
    String? message,
  }) {
    return ClashSyncPushResult(
      status: ClashSyncStatus.validationFailed,
      validationResult: validationResult,
      message: message ?? 'Snapshot failed local validation',
      errorCode: 'validation_failed',
    );
  }

  factory ClashSyncPushResult.conflict({
    required ClashSyncConflict conflict,
    String? message,
  }) {
    return ClashSyncPushResult(
      status: ClashSyncStatus.conflict,
      serverRevision: conflict.actualRevision,
      snapshot: conflict.remoteSnapshot,
      conflict: conflict,
      message: message ?? 'Server revision conflict',
      errorCode: 'revision_conflict',
    );
  }

  factory ClashSyncPushResult.rejected({
    required String errorCode,
    String? message,
  }) {
    return ClashSyncPushResult(
      status: ClashSyncStatus.rejected,
      message: message,
      errorCode: errorCode,
    );
  }

  factory ClashSyncPushResult.unavailable({String? message}) {
    return ClashSyncPushResult(
      status: ClashSyncStatus.unavailable,
      message: message ?? 'Sync service unavailable',
      errorCode: 'unavailable',
    );
  }
}

/// Resultado de descargar el snapshot remoto.
class ClashSyncPullResult {
  const ClashSyncPullResult({
    required this.status,
    this.serverRevision,
    this.snapshot,
    this.message,
    this.errorCode,
  });

  final ClashSyncStatus status;
  final int? serverRevision;
  final ClashSyncSnapshot? snapshot;
  final String? message;
  final String? errorCode;

  bool get isSuccess => status == ClashSyncStatus.success;

  bool get isNotFound => status == ClashSyncStatus.notFound;

  factory ClashSyncPullResult.success({
    required int serverRevision,
    required ClashSyncSnapshot snapshot,
  }) {
    return ClashSyncPullResult(
      status: ClashSyncStatus.success,
      serverRevision: serverRevision,
      snapshot: snapshot,
    );
  }

  factory ClashSyncPullResult.notFound({String? message}) {
    return ClashSyncPullResult(
      status: ClashSyncStatus.notFound,
      serverRevision: 0,
      message: message ?? 'No remote snapshot stored',
      errorCode: 'not_found',
    );
  }

  factory ClashSyncPullResult.unavailable({
    String? message,
    String? errorCode,
  }) {
    return ClashSyncPullResult(
      status: ClashSyncStatus.unavailable,
      message: message ?? 'Sync service unavailable',
      errorCode: errorCode ?? 'unavailable',
    );
  }
}

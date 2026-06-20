import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_validation_result.dart';

/// Operación ejecutada por [ClashSyncCoordinator] (Fase 68).
enum ClashSyncOperation { validate, push, pull }

/// Resultado agregado de una operación de sync orquestada localmente.
class ClashSyncOperationResult {
  const ClashSyncOperationResult({
    required this.operation,
    required this.status,
    this.snapshot,
    this.validationResult,
    this.serverRevision,
    this.conflict,
    this.message,
    this.errorCode,
    this.startedAt,
    this.completedAt,
  });

  final ClashSyncOperation operation;
  final ClashSyncStatus status;
  final ClashSyncSnapshot? snapshot;
  final ClashSyncValidationResult? validationResult;
  final int? serverRevision;
  final ClashSyncConflict? conflict;
  final String? message;
  final String? errorCode;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isSuccess => status == ClashSyncStatus.success;

  bool get isValidationFailed => status == ClashSyncStatus.validationFailed;

  bool get isConflict => status == ClashSyncStatus.conflict;

  bool get isNotFound => status == ClashSyncStatus.notFound;

  bool get isRejected => status == ClashSyncStatus.rejected;

  factory ClashSyncOperationResult.fromValidation({
    required ClashSyncValidationResult validationResult,
    required ClashSyncSnapshot snapshot,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ClashSyncOperationResult(
      operation: ClashSyncOperation.validate,
      status: validationResult.isValid
          ? ClashSyncStatus.success
          : ClashSyncStatus.validationFailed,
      snapshot: snapshot,
      validationResult: validationResult,
      message: validationResult.isValid
          ? null
          : 'Local snapshot failed validation',
      errorCode: validationResult.isValid ? null : 'validation_failed',
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  factory ClashSyncOperationResult.fromPush({
    required ClashSyncPushResult pushResult,
    ClashSyncSnapshot? localSnapshot,
    ClashSyncValidationResult? localValidation,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ClashSyncOperationResult(
      operation: ClashSyncOperation.push,
      status: pushResult.status,
      snapshot: pushResult.snapshot ?? localSnapshot,
      validationResult: pushResult.validationResult ?? localValidation,
      serverRevision: pushResult.serverRevision,
      conflict: pushResult.conflict,
      message: pushResult.message,
      errorCode: pushResult.errorCode,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  factory ClashSyncOperationResult.fromPull({
    required ClashSyncPullResult pullResult,
    ClashSyncValidationResult? remoteValidation,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    final remoteInvalid = remoteValidation != null && !remoteValidation.isValid;
    final status = remoteInvalid
        ? ClashSyncStatus.validationFailed
        : pullResult.status;

    return ClashSyncOperationResult(
      operation: ClashSyncOperation.pull,
      status: status,
      snapshot: pullResult.snapshot,
      validationResult: remoteValidation,
      serverRevision: pullResult.serverRevision,
      message: remoteInvalid
          ? 'Remote snapshot failed validation'
          : pullResult.message,
      errorCode: remoteInvalid ? 'validation_failed' : pullResult.errorCode,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }
}

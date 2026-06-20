import 'clash_sync_apply_status.dart';
import 'clash_sync_validation_result.dart';

/// Resultado de aplicar manualmente un snapshot remoto al almacenamiento local.
class ClashSyncApplyResult {
  const ClashSyncApplyResult({
    required this.status,
    this.appliedAt,
    this.backupCreated = false,
    this.appliedSections = const [],
    this.skippedSections = const [],
    this.validationResult,
    this.message,
    this.errorCode,
  });

  final ClashSyncApplyStatus status;
  final DateTime? appliedAt;
  final bool backupCreated;
  final List<String> appliedSections;
  final List<String> skippedSections;
  final ClashSyncValidationResult? validationResult;
  final String? message;
  final String? errorCode;

  bool get isSuccess => status == ClashSyncApplyStatus.success;

  bool get isValidationFailed =>
      status == ClashSyncApplyStatus.validationFailed;

  bool get isBackupFailed => status == ClashSyncApplyStatus.backupFailed;

  bool get isApplyFailed => status == ClashSyncApplyStatus.applyFailed;

  bool get isUnsupported => status == ClashSyncApplyStatus.unsupported;
}

/// Severidad de un issue de validación del snapshot sync.
enum ClashSyncValidationSeverity { error, warning }

/// Issue individual detectado al validar un [ClashSyncSnapshot].
class ClashSyncValidationIssue {
  const ClashSyncValidationIssue({
    required this.code,
    required this.message,
    required this.path,
    this.severity = ClashSyncValidationSeverity.error,
  });

  final String code;
  final String message;
  final String path;
  final ClashSyncValidationSeverity severity;

  bool get isError => severity == ClashSyncValidationSeverity.error;

  bool get isWarning => severity == ClashSyncValidationSeverity.warning;

  @override
  bool operator ==(Object other) {
    return other is ClashSyncValidationIssue &&
        other.code == code &&
        other.message == message &&
        other.path == path &&
        other.severity == severity;
  }

  @override
  int get hashCode => Object.hash(code, message, path, severity);
}

/// Resultado agregado de validar un snapshot sync (Fase 66).
class ClashSyncValidationResult {
  const ClashSyncValidationResult({
    required this.errors,
    required this.warnings,
    this.checkedAt,
  });

  final List<ClashSyncValidationIssue> errors;
  final List<ClashSyncValidationIssue> warnings;
  final DateTime? checkedAt;

  bool get isValid => errors.isEmpty;

  bool get hasErrors => errors.isNotEmpty;

  bool get hasWarnings => warnings.isNotEmpty;

  factory ClashSyncValidationResult.empty({DateTime? checkedAt}) {
    return ClashSyncValidationResult(
      errors: const [],
      warnings: const [],
      checkedAt: checkedAt,
    );
  }

  ClashSyncValidationResult merge(ClashSyncValidationResult other) {
    return ClashSyncValidationResult(
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
      checkedAt: checkedAt ?? other.checkedAt,
    );
  }
}

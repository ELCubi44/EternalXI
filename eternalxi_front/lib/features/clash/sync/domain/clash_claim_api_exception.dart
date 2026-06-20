/// Error base de llamadas HTTP a `/api/v1/clash/claims` (Fase 82).
class ClashClaimApiException implements Exception {
  const ClashClaimApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  final int statusCode;
  final String message;
  final String? errorCode;

  @override
  String toString() => message;
}

/// Claim rechazado por validación (HTTP 400).
class ClashClaimValidationException extends ClashClaimApiException {
  const ClashClaimValidationException({String? message, String? errorCode})
    : super(
        statusCode: 400,
        errorCode: errorCode ?? 'VALIDATION_ERROR',
        message: message ?? 'Claim inválido',
      );
}

/// Usuario no autenticado (HTTP 401).
class ClashClaimUnauthorizedException extends ClashClaimApiException {
  const ClashClaimUnauthorizedException({String? message, String? errorCode})
    : super(
        statusCode: 401,
        errorCode: errorCode ?? 'UNAUTHORIZED',
        message: message ?? 'Debes iniciar sesión para continuar.',
      );
}

/// Conflicto de revisión u otro 409 futuro.
class ClashClaimConflictException extends ClashClaimApiException {
  const ClashClaimConflictException({String? message, String? errorCode})
    : super(
        statusCode: 409,
        errorCode: errorCode ?? 'CLASH_CLAIM_CONFLICT',
        message: message ?? 'Conflicto al procesar el claim',
      );
}

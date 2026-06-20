import 'package:eternal_xi/features/clash/sync/domain/clash_save_contract.dart';

/// Error base de llamadas HTTP a `/api/v1/clash/save` (Fase 71).
class ClashSaveApiException implements Exception {
  const ClashSaveApiException({
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

/// Partida Clash no encontrada (HTTP 404 en PUT/GET con error explícito).
class ClashSaveNotFoundException extends ClashSaveApiException {
  const ClashSaveNotFoundException({String? message})
    : super(
        statusCode: 404,
        errorCode: 'CLASH_SAVE_NOT_FOUND',
        message: message ?? 'No existe partida Clash para este usuario',
      );
}

/// Conflicto de revisión (HTTP 409 con [ClashSaveConflictResponse]).
class ClashSaveConflictException extends ClashSaveApiException {
  ClashSaveConflictException({required this.conflictResponse, String? message})
    : super(
        statusCode: 409,
        errorCode: 'revision_conflict',
        message:
            message ??
            conflictResponse.clientRejectedReason ??
            'Server revision conflict',
      );

  final ClashSaveConflictResponse conflictResponse;
}

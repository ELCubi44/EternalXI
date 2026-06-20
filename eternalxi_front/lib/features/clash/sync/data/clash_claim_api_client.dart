import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';

/// Cliente HTTP para claims idempotentes Clash (Fase 82).
///
/// Usa [ApiClient] existente (JWT vía interceptores). **No** envía `userId`.
/// No está registrado en providers ni flujos de rewards todavía.
class ClashClaimApiClient {
  ClashClaimApiClient(this._dio);

  factory ClashClaimApiClient.fromApiClient(ApiClient apiClient) {
    return ClashClaimApiClient(apiClient.dio);
  }

  final Dio _dio;

  static const _path = ApiConstants.clashClaims;

  /// POST `/api/v1/clash/claims` — aceptado (201) o ya procesado (200).
  Future<ClashClaimResponse> submitClaim(ClashClaimRequest request) async {
    _assertNoUserIdInBody(request);
    try {
      final response = await _dio.post<dynamic>(_path, data: request.toJson());
      return _handleSuccessResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  static ClashClaimResponse _handleSuccessResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status != 200 && status != 201) {
      throw _mapHttpError(status, response.data);
    }
    return _parseClaimResponse(response.data);
  }

  static ClashClaimResponse _parseClaimResponse(dynamic data) {
    final map = _readMap(data);
    return ClashClaimResponse.fromJson(map);
  }

  static Map<String, dynamic> _readMap(dynamic data) {
    final map = _readMapOrNull(data);
    if (map == null) {
      throw const ClashClaimApiException(
        statusCode: 0,
        message: 'Respuesta Clash claim inválida',
      );
    }
    return map;
  }

  static Map<String, dynamic>? _readMapOrNull(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static int? _statusCode(DioException error) {
    return error.response?.statusCode;
  }

  static ClashClaimApiException _mapDioException(DioException error) {
    final status = _statusCode(error) ?? 0;
    return _mapHttpError(
      status,
      error.response?.data,
      fallbackMessage: error.message,
    );
  }

  static ClashClaimApiException _mapHttpError(
    int status,
    dynamic data, {
    String? fallbackMessage,
  }) {
    final map = _readMapOrNull(data);
    final message = _readMessage(map) ?? fallbackMessage ?? 'Error Clash claim';
    final errorCode = map?['error']?.toString();

    if (status == 400) {
      return ClashClaimValidationException(
        message: message,
        errorCode: errorCode,
      );
    }

    if (status == 401) {
      return ClashClaimUnauthorizedException(
        message: message,
        errorCode: errorCode,
      );
    }

    if (status == 409) {
      return ClashClaimConflictException(
        message: message,
        errorCode: errorCode,
      );
    }

    return ClashClaimApiException(
      statusCode: status,
      message: message,
      errorCode: errorCode,
    );
  }

  static String? _readMessage(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }
    final raw = map['message'] ?? map['mensaje'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return null;
  }

  static void _assertNoUserIdInBody(ClashClaimRequest request) {
    final json = request.toJson();
    if (json.containsKey('userId') ||
        json.containsKey('user_id') ||
        json.containsKey('idUsuario')) {
      throw const ClashClaimApiException(
        statusCode: 0,
        message: 'userId must not be sent in Clash claim body',
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_contract.dart';

/// Contrato mínimo del cliente save (HTTP o fake en tests).
abstract class ClashSaveApiPort {
  Future<ClashSaveResponse?> getSave();

  Future<ClashSaveResponse> createSave(ClashSaveUpdateRequest request);

  Future<ClashSaveResponse> updateSave(ClashSaveUpdateRequest request);
}

/// Cliente HTTP para guardado online Clash (Fase 71).
///
/// Usa [ApiClient] existente (JWT vía interceptores). **No** envía `userId`.
class ClashSaveApiClient implements ClashSaveApiPort {
  ClashSaveApiClient(this._dio);

  factory ClashSaveApiClient.fromApiClient(ApiClient apiClient) {
    return ClashSaveApiClient(apiClient.dio);
  }

  final Dio _dio;

  static const _path = ApiConstants.clashSave;

  /// GET `/api/v1/clash/save` — `null` si 404.
  @override
  Future<ClashSaveResponse?> getSave() async {
    try {
      final response = await _dio.get<dynamic>(_path);
      return _handleGetResponse(response);
    } on DioException catch (error) {
      if (_statusCode(error) == 404) {
        return null;
      }
      throw _mapDioException(error);
    }
  }

  /// POST `/api/v1/clash/save` — crea partida inicial (201/200).
  @override
  Future<ClashSaveResponse> createSave(ClashSaveUpdateRequest request) async {
    _assertNoUserIdInBody(request);
    try {
      final response = await _dio.post<dynamic>(_path, data: request.toJson());
      return _handleMutationResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// PUT `/api/v1/clash/save` — actualiza con `expectedServerRevision`.
  @override
  Future<ClashSaveResponse> updateSave(ClashSaveUpdateRequest request) async {
    _assertNoUserIdInBody(request);
    try {
      final response = await _dio.put<dynamic>(_path, data: request.toJson());
      return _handleMutationResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  static ClashSaveResponse? _handleGetResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status == 404) {
      return null;
    }
    if (status >= 400) {
      throw _mapHttpError(status, response.data);
    }
    return _parseSaveResponse(response.data);
  }

  static ClashSaveResponse _handleMutationResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw _mapHttpError(status, response.data);
    }
    return _parseSaveResponse(response.data);
  }

  static ClashSaveResponse _parseSaveResponse(dynamic data) {
    final map = _readMap(data);
    return ClashSaveResponse.fromJson(map);
  }

  static ClashSaveConflictResponse? _parseConflictResponse(dynamic data) {
    final map = _readMapOrNull(data);
    if (map == null) {
      return null;
    }
    if (map.containsKey('serverSaveData')) {
      return ClashSaveConflictResponse.fromJson(map);
    }
    return null;
  }

  static Map<String, dynamic> _readMap(dynamic data) {
    final map = _readMapOrNull(data);
    if (map == null) {
      throw const ClashSaveApiException(
        statusCode: 0,
        message: 'Respuesta Clash save inválida',
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

  static ClashSaveApiException _mapDioException(DioException error) {
    final status = _statusCode(error) ?? 0;
    return _mapHttpError(
      status,
      error.response?.data,
      fallbackMessage: error.message,
    );
  }

  static ClashSaveApiException _mapHttpError(
    int status,
    dynamic data, {
    String? fallbackMessage,
  }) {
    final map = _readMapOrNull(data);
    final message = _readMessage(map) ?? fallbackMessage ?? 'Error Clash save';
    final errorCode = map?['error']?.toString();

    if (status == 404) {
      return ClashSaveNotFoundException(message: message);
    }

    if (status == 409) {
      final conflict = _parseConflictResponse(data);
      if (conflict != null) {
        return ClashSaveConflictException(
          conflictResponse: conflict,
          message: message,
        );
      }
      return ClashSaveApiException(
        statusCode: 409,
        message: message,
        errorCode: errorCode ?? 'CLASH_SAVE_ALREADY_EXISTS',
      );
    }

    return ClashSaveApiException(
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

  static void _assertNoUserIdInBody(ClashSaveUpdateRequest request) {
    final json = request.toJson();
    if (json.containsKey('userId') ||
        json.containsKey('user_id') ||
        json.containsKey('idUsuario')) {
      throw const ClashSaveApiException(
        statusCode: 0,
        message: 'userId must not be sent in Clash save body',
      );
    }
  }
}

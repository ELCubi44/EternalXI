import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          headers: {'Accept': 'application/json'},
        ),
      ) {
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
    // Placeholder para agregar Authorization en el futuro.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;

  String extractErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'No se pudo conectar con el servidor. Verifica backend y red.';
      }

      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final mapped = _mapBackendError(responseData);
        if (mapped != null) return mapped;
      }

      if (error.error is SocketException) {
        return 'Error de red. Revisa tu conexion y vuelve a intentar.';
      }

      return 'Error de comunicación con el servidor.';
    }

    return 'Ocurrió un error inesperado.';
  }

  static const _knownErrorMessages = <String, String>{
    'AMOUNT_MUST_BE_INTEGER': 'El importe debe ser un número entero.',
    'INSUFFICIENT_FUNDS': 'No tienes suficiente dinero.',
    'FORBIDDEN': 'No tienes permiso para hacer esta acción.',
    'INTERNAL_ERROR': 'Ha ocurrido un error. Inténtalo de nuevo.',
  };

  static String? _mapBackendError(Map<String, dynamic> data) {
    final errorCode = data['error'];
    final rawMessage = data['message'] ?? data['mensaje'];
    final msg = rawMessage is String ? rawMessage.trim() : '';

    if (errorCode is String && errorCode.trim().isNotEmpty) {
      final code = errorCode.trim().toUpperCase();
      final known = _knownErrorMessages[code];
      if (known != null) return known;
      if (msg.isNotEmpty) return msg;
      return 'Error del servidor ($code).';
    }

    if (msg.isNotEmpty) return msg;
    return null;
  }
}

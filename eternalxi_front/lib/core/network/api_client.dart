import 'dart:io';

import 'package:eternal_xi/app/localization/app_locale.dart';
import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/network/auth_interceptor.dart';
import 'package:eternal_xi/core/network/token_refresh_interceptor.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ApiClient {
  ApiClient({
    String acceptLanguage = 'es',
    SecureStorageService? secureStorage,
    Future<void> Function()? onUnauthorized,
  })  : _acceptLanguage = _normalizeLanguage(acceptLanguage),
        dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/json',
            'Accept-Language': _normalizeLanguage(acceptLanguage),
          },
        ),
      ) {
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = _acceptLanguage;
          handler.next(options);
        },
      ),
    );
    if (secureStorage != null) {
      dio.interceptors.add(
        AuthInterceptor(
          secureStorage: secureStorage,
          onUnauthorized: onUnauthorized,
        ),
      );
      dio.interceptors.add(
        TokenRefreshInterceptor(
          dio: dio,
          secureStorage: secureStorage,
          onSessionExpired: onUnauthorized,
        ),
      );
    }
  }

  void attachSessionExpiredHandler(Future<void> Function() handler) {
    for (final interceptor in dio.interceptors) {
      if (interceptor is AuthInterceptor) {
        interceptor.onUnauthorized = handler;
      }
      if (interceptor is TokenRefreshInterceptor) {
        interceptor.onSessionExpired = handler;
      }
    }
  }

  final Dio dio;
  String _acceptLanguage;

  String get acceptLanguage => _acceptLanguage;

  void setAcceptLanguage(String languageTag) {
    _acceptLanguage = _normalizeLanguage(languageTag);
    dio.options.headers['Accept-Language'] = _acceptLanguage;
  }

  static String _normalizeLanguage(String raw) {
    return raw.trim().toLowerCase().startsWith('en') ? 'en' : 'es';
  }

  String extractErrorMessage(Object error) {
    final l10n = AppLocalizations(Locale(AppLocale.languageCode));
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return l10n.apiConnectionError;
      }

      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final mapped = _mapBackendError(responseData);
        if (mapped != null) return mapped;
      }

      if (error.error is SocketException) {
        return l10n.apiNetworkError;
      }

      return l10n.apiCommunicationError;
    }

    return l10n.apiUnexpectedError;
  }

  static String? _mapBackendError(Map<String, dynamic> data) {
    final l10n = AppLocalizations(Locale(AppLocale.languageCode));
    final knownErrorMessages = <String, String>{
      'AMOUNT_MUST_BE_INTEGER': l10n.apiAmountMustBeInteger,
      'INSUFFICIENT_FUNDS': l10n.apiInsufficientFunds,
      'FORBIDDEN': l10n.apiForbidden,
      'INTERNAL_ERROR': l10n.apiInternalError,
      'EMAIL_UNAVAILABLE': l10n.apiEmailUnavailable,
    };
    final errorCode = data['error'];
    final rawMessage = data['message'] ?? data['mensaje'];
    final msg = rawMessage is String ? rawMessage.trim() : '';

    if (errorCode is String && errorCode.trim().isNotEmpty) {
      final code = errorCode.trim().toUpperCase();
      final known = knownErrorMessages[code];
      if (known != null) return known;
      if (msg.isNotEmpty) return msg;
      return AppLocale.languageCode.startsWith('en')
          ? 'Server error ($code).'
          : 'Error del servidor ($code).';
    }

    if (msg.isNotEmpty) return msg;
    return null;
  }
}

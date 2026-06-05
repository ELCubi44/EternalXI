import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/models/auth_response_model.dart';

/// Renueva el access token con el refresh token ante un 401.
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required SecureStorageService secureStorage,
    this.onSessionExpired,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  final Dio _dio;
  final SecureStorageService _secureStorage;
  Future<void> Function()? onSessionExpired;

  static const _retryKey = 'token_refresh_retried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final path = err.requestOptions.uri.path;
    if (_isPublicAuthPath(path) || err.requestOptions.extra[_retryKey] == true) {
      handler.next(err);
      return;
    }

    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final refreshResponse = await _dio.post(
        '${ApiConstants.auth}/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_retryKey: true}),
      );
      final auth = AuthResponseModel.fromJson(
        refreshResponse.data as Map<String, dynamic>,
      );
      await _secureStorage.updateTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        tokenType: auth.tokenType,
      );
      await _secureStorage.saveUser(auth.user);

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] =
          '${auth.tokenType} ${auth.accessToken}';
      retryOptions.extra[_retryKey] = true;

      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      // No cerrar sesión automáticamente: el usuario solo sale con logout manual.
      handler.next(err);
    }
  }

  bool _isPublicAuthPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/password-reset/') ||
        path.contains('/auth/email-verification/');
  }

}

import 'package:dio/dio.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';

/// Añade el JWT a cada petición (salvo login/registro).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService secureStorage,
    this.onUnauthorized,
  }) : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;
  final Future<void> Function()? onUnauthorized;

  static const _publicPathPrefixes = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/password-reset/',
    '/auth/email-verification/',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    final isPublic = _publicPathPrefixes.any(path.contains);
    if (!isPublic) {
      final token = await _secureStorage.getAccessToken();
      final tokenType = await _readTokenType();
      if (token != null && token.isNotEmpty && token != 'token-temporal') {
        options.headers['Authorization'] = '$tokenType $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.uri.path;
      final isPublic = _publicPathPrefixes.any(path.contains);
      if (!isPublic && onUnauthorized != null) {
        await onUnauthorized!();
      }
    }
    handler.next(err);
  }

  Future<String> _readTokenType() async {
    // tokenType no expuesto; Bearer por defecto en API Eternal XI.
    return 'Bearer';
  }
}

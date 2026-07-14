import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/email_change_confirm_response.dart';
import 'package:eternal_xi/data/models/api_message_model.dart';
import 'package:eternal_xi/data/models/auth_response_model.dart';
import 'package:eternal_xi/data/models/oauth_providers_response.dart';
import 'package:eternal_xi/data/models/register_response_model.dart';
import 'package:eternal_xi/data/models/user_model.dart';

class AuthApiService {
  AuthApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponseModel> login({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.auth}/login',
        data: {'correo': correo, 'contrasena': contrasena},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<RegisterResponseModel> register({
    required String correo,
    required String contrasena,
    required String nickname,
    required String fechaNacimiento,
    required bool aceptaTerminos,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.auth}/register',
        data: {
          'correo': correo,
          'contrasena': contrasena,
          'nickname': nickname,
          'fechaNacimiento': fechaNacimiento,
          'aceptaTerminos': aceptaTerminos,
        },
      );
      return RegisterResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ApiMessageModel> requestEmailVerification({
    required String correo,
  }) async {
    return _postMessage('${ApiConstants.auth}/email-verification/request', {
      'correo': correo,
    });
  }

  Future<ApiMessageModel> confirmEmailVerification({
    required String correo,
    required String codigo,
  }) async {
    return _postMessage('${ApiConstants.auth}/email-verification/confirm', {
      'correo': correo,
      'codigo': codigo,
    });
  }

  Future<AuthResponseModel> refreshSession({
    required String refreshToken,
  }) async {
    final response = await _apiClient.dio.post(
      '${ApiConstants.auth}/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> confirmAge({
    required int idUsuario,
    required String fechaNacimiento,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.auth}/confirm-age',
        data: {
          'idUsuario': idUsuario,
          'fechaNacimiento': fechaNacimiento,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ApiMessageModel> requestPasswordReset({required String correo}) async {
    return _postMessage('${ApiConstants.auth}/password-reset/request', {
      'correo': correo,
    });
  }

  Future<ApiMessageModel> confirmPasswordReset({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    return _postMessage('${ApiConstants.auth}/password-reset/confirm', {
      'correo': correo,
      'codigo': codigo,
      'nuevaContrasena': nuevaContrasena,
    });
  }

  Future<ApiMessageModel> requestEmailChange({
    required int idUsuario,
    required String contrasenaActual,
    required String nuevoCorreo,
  }) async {
    return _postMessage('${ApiConstants.auth}/email-change/request', {
      'idUsuario': idUsuario,
      'contrasenaActual': contrasenaActual,
      'nuevoCorreo': nuevoCorreo,
    });
  }

  Future<EmailChangeConfirmResponse> confirmEmailChange({
    required int idUsuario,
    required String nuevoCorreo,
    required String codigo,
    required String codigoCorreoActual,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.auth}/email-change/confirm',
        data: {
          'idUsuario': idUsuario,
          'nuevoCorreo': nuevoCorreo,
          'codigo': codigo,
          'codigoCorreoActual': codigoCorreoActual,
        },
      );
      return EmailChangeConfirmResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ApiMessageModel> requestNicknameChange({
    required int idUsuario,
    required String contrasenaActual,
    required String nuevoNickname,
  }) async {
    return _postMessage('${ApiConstants.auth}/nickname-change/request', {
      'idUsuario': idUsuario,
      'contrasenaActual': contrasenaActual,
      'nuevoNickname': nuevoNickname,
    });
  }

  Future<ApiMessageModel> requestAccountDeletion() async {
    return _postMessage('${ApiConstants.accountDeletion}/request', {});
  }

  Future<ApiMessageModel> confirmAccountDeletion({required String codigo}) async {
    return _postMessage('${ApiConstants.accountDeletion}/confirm', {
      'codigo': codigo,
    });
  }

  Future<EmailChangeConfirmResponse> confirmNicknameChange({
    required int idUsuario,
    required String nuevoNickname,
    required String codigo,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.auth}/nickname-change/confirm',
        data: {
          'idUsuario': idUsuario,
          'nuevoNickname': nuevoNickname,
          'codigo': codigo,
        },
      );
      return EmailChangeConfirmResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ApiMessageModel> _postMessage(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.dio.post(path, data: payload);
      return ApiMessageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<AuthResponseModel> loginWithGoogle({
    required String idToken,
    bool aceptaTerminos = false,
    String? nickname,
  }) async {
    return _oauthLogin(
      '${ApiConstants.auth}/oauth/google',
      idToken: idToken,
      aceptaTerminos: aceptaTerminos,
      nickname: nickname,
    );
  }

  Future<AuthResponseModel> loginWithApple({
    required String idToken,
    bool aceptaTerminos = false,
    String? nickname,
  }) async {
    return _oauthLogin(
      '${ApiConstants.auth}/oauth/apple',
      idToken: idToken,
      aceptaTerminos: aceptaTerminos,
      nickname: nickname,
    );
  }

  Future<ApiMessageModel> linkGoogle({required String idToken}) async {
    return _postMessage('${ApiConstants.auth}/oauth/link/google', {
      'idToken': idToken,
    });
  }

  Future<ApiMessageModel> linkApple({required String idToken}) async {
    return _postMessage('${ApiConstants.auth}/oauth/link/apple', {
      'idToken': idToken,
    });
  }

  Future<OAuthProvidersResponse> getOAuthProviders() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.auth}/oauth/providers',
      );
      return OAuthProvidersResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<AuthResponseModel> _oauthLogin(
    String path, {
    required String idToken,
    required bool aceptaTerminos,
    String? nickname,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        path,
        data: {
          'idToken': idToken,
          'aceptaTerminos': aceptaTerminos,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
        },
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }
}

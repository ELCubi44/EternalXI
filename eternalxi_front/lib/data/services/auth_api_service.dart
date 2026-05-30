import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/email_change_confirm_response.dart';
import 'package:eternal_xi/data/models/api_message_model.dart';
import 'package:eternal_xi/data/models/auth_response_model.dart';
import 'package:eternal_xi/data/models/register_response_model.dart';

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
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.auth}/register',
        data: {
          'correo': correo,
          'contrasena': contrasena,
          'nickname': nickname,
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
}

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/models/email_change_confirm_response.dart';
import 'package:eternal_xi/data/models/user_model.dart';
import 'package:eternal_xi/data/services/auth_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthApiService authApiService,
    required SecureStorageService secureStorageService,
    required UserApiService userApiService,
  }) : _authApiService = authApiService,
       _secureStorageService = secureStorageService,
       _userApiService = userApiService {
    _pushTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen((token) {
          final userId = currentUser?.id;
          if (userId == null) {
            return;
          }

          _registerPushToken(
            userId: userId,
            token: token,
          );
        });
  }

  final AuthApiService _authApiService;
  final SecureStorageService _secureStorageService;
  final UserApiService _userApiService;

  StreamSubscription<String>? _pushTokenRefreshSubscription;

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    _setLoading(true);
    errorMessage = null;
    try {
      final userId = await _secureStorageService.getUserId();
      final accessToken = await _secureStorageService.getAccessToken();
      final refreshToken = await _secureStorageService.getRefreshToken();

      if (userId == null) {
        currentUser = null;
        return false;
      }

      final hasAccess = accessToken != null && accessToken.isNotEmpty;
      final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
      if (!hasAccess && !hasRefresh) {
        currentUser = null;
        return false;
      }

      if (hasRefresh) {
        await _tryRefreshSession(refreshToken!);
      }

      if (currentUser == null) {
        final nickname = await _secureStorageService.getNickname();
        final correo = await _secureStorageService.getCorreo();
        final nivel = await _secureStorageService.getNivel();
        final fotoRaw = await _secureStorageService.getFoto();
        final fotoTrim = fotoRaw?.trim();
        currentUser = UserModel(
          id: int.tryParse(userId) ?? 0,
          correo: correo ?? '',
          nickname: nickname ?? '',
          nivel: int.tryParse(nivel ?? '1') ?? 1,
          foto: (fotoTrim == null || fotoTrim.isEmpty) ? null : fotoTrim,
        );
      }

      await _syncPushTokenForCurrentUser();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<_SessionRefreshResult> _tryRefreshSession(String refreshToken) async {
    try {
      final result = await _authApiService.refreshSession(
        refreshToken: refreshToken,
      );
      await _secureStorageService.updateTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        tokenType: result.tokenType,
      );
      await _secureStorageService.saveUser(result.user);
      currentUser = result.user;
      return _SessionRefreshResult.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        return _SessionRefreshResult.invalid;
      }
      return _SessionRefreshResult.offline;
    } catch (_) {
      return _SessionRefreshResult.offline;
    }
  }

  Future<bool> login({
    required String correo,
    required String contrasena,
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await _authApiService.login(
        correo: correo,
        contrasena: contrasena,
      );

      await _secureStorageService.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        tokenType: result.tokenType,
        user: result.user,
      );

      currentUser = result.user;

      await _syncPushTokenForCurrentUser();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await forceLogout();
  }

  /// Cierra sesión local (tokens + usuario en memoria).
  Future<void> forceLogout() async {
    await _secureStorageService.clearAuthSession();
    currentUser = null;
    errorMessage = null;
    notifyListeners();
  }

  void setCurrentUser(UserModel? user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> refreshCurrentUserFromServer() async {
    final id = currentUser?.id;
    if (id == null) {
      return;
    }
    try {
      final user = await _userApiService.getUserById(id);
      currentUser = user;
      await _secureStorageService.saveUser(user);
      notifyListeners();
    } catch (_) {
      // Mantener sesión local si falla el refresco puntual.
    }
  }

  Future<String?> requestEmailVerification(String correo) async {
    return _runMessageAction(
      () => _authApiService.requestEmailVerification(correo: correo),
    );
  }

  Future<String?> confirmEmailVerification({
    required String correo,
    required String codigo,
  }) async {
    return _runMessageAction(
      () => _authApiService.confirmEmailVerification(
        correo: correo,
        codigo: codigo,
      ),
    );
  }

  Future<String?> register({
    required String correo,
    required String nickname,
    required String contrasena,
    required String fechaNacimiento,
    required bool aceptaTerminos,
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await _authApiService.register(
        correo: correo,
        nickname: nickname,
        contrasena: contrasena,
        fechaNacimiento: fechaNacimiento,
        aceptaTerminos: aceptaTerminos,
      );
      return result.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmAge(String fechaNacimiento) async {
    final userId = currentUser?.id;
    if (userId == null) {
      return false;
    }
    _setLoading(true);
    errorMessage = null;
    try {
      final user = await _authApiService.confirmAge(
        idUsuario: userId,
        fechaNacimiento: fechaNacimiento,
      );
      currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> requestPasswordReset(String correo) async {
    return _runMessageAction(
      () => _authApiService.requestPasswordReset(correo: correo),
    );
  }

  Future<String?> confirmPasswordReset({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    return _runMessageAction(
      () => _authApiService.confirmPasswordReset(
        correo: correo,
        codigo: codigo,
        nuevaContrasena: nuevaContrasena,
      ),
    );
  }

  Future<String?> requestEmailChange({
    required int idUsuario,
    required String contrasenaActual,
    required String nuevoCorreo,
  }) async {
    return _runMessageAction(
      () => _authApiService.requestEmailChange(
        idUsuario: idUsuario,
        contrasenaActual: contrasenaActual,
        nuevoCorreo: nuevoCorreo,
      ),
    );
  }

  Future<EmailChangeConfirmResponse?> confirmEmailChange({
    required int idUsuario,
    required String nuevoCorreo,
    required String codigo,
    required String codigoCorreoActual,
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await _authApiService.confirmEmailChange(
        idUsuario: idUsuario,
        nuevoCorreo: nuevoCorreo,
        codigo: codigo,
        codigoCorreoActual: codigoCorreoActual,
      );
      currentUser = result.user;
      await _secureStorageService.saveUser(result.user);
      notifyListeners();
      return result;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> requestNicknameChange({
    required int idUsuario,
    required String contrasenaActual,
    required String nuevoNickname,
  }) async {
    return _runMessageAction(
      () => _authApiService.requestNicknameChange(
        idUsuario: idUsuario,
        contrasenaActual: contrasenaActual,
        nuevoNickname: nuevoNickname,
      ),
    );
  }

  Future<EmailChangeConfirmResponse?> confirmNicknameChange({
    required int idUsuario,
    required String nuevoNickname,
    required String codigo,
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await _authApiService.confirmNicknameChange(
        idUsuario: idUsuario,
        nuevoNickname: nuevoNickname,
        codigo: codigo,
      );
      currentUser = result.user;
      await _secureStorageService.saveUser(result.user);
      notifyListeners();
      return result;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> requestAccountDeletion() async {
    return _runMessageAction(() => _authApiService.requestAccountDeletion());
  }

  Future<String?> confirmAccountDeletion({required String codigo}) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await _authApiService.confirmAccountDeletion(codigo: codigo);
      await _secureStorageService.clearSession();
      currentUser = null;
      notifyListeners();
      return result.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _runMessageAction(Future<dynamic> Function() action) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await action();
      return result.message as String;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncPushTokenForCurrentUser() async {
    final userId = currentUser?.id;
    if (userId == null) {
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    try {
      final permissionGranted = await _ensurePushPermission();
      if (!permissionGranted) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _registerPushToken(
        userId: userId,
        token: token,
      );
    } catch (e, st) {
      debugPrint('Error sincronizando token push: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<bool> _ensurePushPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _registerPushToken({
    required int userId,
    required String token,
  }) async {
    try {
      await _userApiService.registerPushToken(
        idUsuario: userId,
        token: token,
        plataforma: Platform.isIOS ? 'IOS' : 'ANDROID',
        deviceId: null,
      );
    } catch (e, st) {
      debugPrint('Error registrando token push en backend: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  void dispose() {
    _pushTokenRefreshSubscription?.cancel();
    super.dispose();
  }
}

enum _SessionRefreshResult { success, invalid, offline }
import 'dart:async';
import 'dart:io';

import 'package:eternal_xi/core/storage/secure_storage_service.dart';
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
      final accessToken = await _secureStorageService.getAccessToken();
      final userId = await _secureStorageService.getUserId();
      final nickname = await _secureStorageService.getNickname();
      final correo = await _secureStorageService.getCorreo();
      final nivel = await _secureStorageService.getNivel();
      final fotoRaw = await _secureStorageService.getFoto();

      if (accessToken == null || userId == null) {
        currentUser = null;
        return false;
      }

      final fotoTrim = fotoRaw?.trim();
      currentUser = UserModel(
        id: int.tryParse(userId) ?? 0,
        correo: correo ?? '',
        nickname: nickname ?? '',
        nivel: int.tryParse(nivel ?? '1') ?? 1,
        foto: (fotoTrim == null || fotoTrim.isEmpty) ? null : fotoTrim,
      );

      await _syncPushTokenForCurrentUser();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
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
    await _secureStorageService.clearSession();
    currentUser = null;
    notifyListeners();
  }

  void setCurrentUser(UserModel? user) {
    currentUser = user;
    notifyListeners();
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
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final result = await _authApiService.register(
        correo: correo,
        nickname: nickname,
        contrasena: contrasena,
      );
      return result.message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
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
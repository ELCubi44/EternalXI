import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/models/user_model.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:flutter/material.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    required UserApiService userApiService,
    required SecureStorageService secureStorageService,
  }) : _userApiService = userApiService,
       _secureStorageService = secureStorageService;

  final UserApiService _userApiService;
  final SecureStorageService _secureStorageService;

  UserModel? user;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<bool> loadProfile(int id) async {
    _setLoading(true);
    errorMessage = null;
    successMessage = null;
    try {
      user = await _userApiService.getUserById(id);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required int id,
    required String nickname,
  }) async {
    _setLoading(true);
    errorMessage = null;
    successMessage = null;
    try {
      final nivel = user?.nivel ?? 1;
      user = await _userApiService.updateUser(
        id: id,
        nickname: nickname,
        nivel: nivel,
      );
      await _secureStorageService.saveUser(user!);
      successMessage = 'Perfil actualizado correctamente';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadProfilePhoto({
    required int id,
    required String filePath,
  }) async {
    _setLoading(true);
    errorMessage = null;
    successMessage = null;
    try {
      await _userApiService.uploadProfilePhoto(id: id, filePath: filePath);
      user = await _userApiService.getUserById(id);
      await _secureStorageService.saveUser(user!);
      successMessage = 'Foto de perfil actualizada';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

}

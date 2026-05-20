import 'package:eternal_xi/data/models/update_user_preferences_request.dart';
import 'package:eternal_xi/data/models/user_preferences_response.dart';
import 'package:eternal_xi/data/models/user_resources_response.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

class UserPreferencesController extends ChangeNotifier {
  UserPreferencesController({
    required UserApiService userApiService,
    required SecureStorageService secureStorageService,
    UserThemePreference initialThemeMode = UserThemePreference.system,
  }) : _userApiService = userApiService,
       _secureStorageService = secureStorageService,
       _localThemeMode = initialThemeMode;

  final UserApiService _userApiService;
  final SecureStorageService _secureStorageService;
  UserThemePreference _localThemeMode;

  int? _userId;
  UserResourcesResponse? resources;
  UserPreferencesResponse? preferences;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  int get fichas => resources?.fichas ?? 0;

  ThemeMode get appThemeMode {
    final effectiveTheme = preferences?.themeMode ?? _localThemeMode;
    switch (effectiveTheme) {
      case UserThemePreference.system:
        return ThemeMode.system;
      case UserThemePreference.light:
        return ThemeMode.light;
      case UserThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  UserThemePreference get currentThemePreference =>
      preferences?.themeMode ?? _localThemeMode;

  Locale? get appLocale {
    switch (preferences?.languageCode ?? UserLanguagePreference.system) {
      case UserLanguagePreference.system:
        return null;
      case UserLanguagePreference.es:
        return const Locale('es');
      case UserLanguagePreference.en:
        return const Locale('en');
    }
  }

  void syncWithUser(int? userId) {
    if (_userId == userId) {
      return;
    }
    _userId = userId;
    if (userId == null) {
      resources = null;
      errorMessage = null;
      isLoading = false;
      isSaving = false;
      notifyListeners();
      return;
    }
    loadAll();
  }

  Future<void> loadAll() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _userApiService.getUserResources(userId),
        _userApiService.getUserPreferences(userId),
      ]);
      resources = results[0] as UserResourcesResponse;
      preferences = results[1] as UserPreferencesResponse;
      await _persistThemeMode(preferences!.themeMode);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreferences({
    required UserThemePreference themeMode,
    required UserLanguagePreference languageCode,
  }) async {
    final userId = _userId;
    if (userId == null) {
      errorMessage = 'No hay sesion activa.';
      notifyListeners();
      return false;
    }
    final current = preferences;
    if (current != null &&
        current.themeMode == themeMode &&
        current.languageCode == languageCode) {
      return true;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (currentThemePreference != themeMode) {
        await _applyThemeLocally(themeMode);
      }
      preferences = await _userApiService.updateUserPreferences(
        userId,
        UpdateUserPreferencesRequest(
          themeMode: themeMode,
          languageCode: languageCode,
        ),
      );
      await _persistThemeMode(preferences!.themeMode);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setThemeDark() => _applyThemeLocally(UserThemePreference.dark);

  Future<void> setThemeLight() => _applyThemeLocally(UserThemePreference.light);

  Future<void> setThemeSystem() =>
      _applyThemeLocally(UserThemePreference.system);

  Future<void> _applyThemeLocally(UserThemePreference preference) async {
    _localThemeMode = preference;
    if (preferences != null) {
      preferences = UserPreferencesResponse(
        idUsuario: preferences!.idUsuario,
        themeMode: preference,
        languageCode: preferences!.languageCode,
      );
    }
    await _persistThemeMode(preference);
    notifyListeners();
  }

  Future<void> _persistThemeMode(UserThemePreference preference) async {
    _localThemeMode = preference;
    await _secureStorageService.saveThemeMode(_themeToStorage(preference));
  }

  static UserThemePreference themeFromStorage(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'dark':
        return UserThemePreference.dark;
      case 'light':
        return UserThemePreference.light;
      default:
        return UserThemePreference.system;
    }
  }

  static String _themeToStorage(UserThemePreference preference) {
    switch (preference) {
      case UserThemePreference.dark:
        return 'dark';
      case UserThemePreference.light:
        return 'light';
      case UserThemePreference.system:
        return 'system';
    }
  }
}

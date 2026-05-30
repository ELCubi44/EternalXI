import 'package:eternal_xi/app/localization/app_locale.dart';
import 'package:eternal_xi/core/localization/app_locale_resolver.dart';
import 'package:eternal_xi/core/network/api_client.dart';
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
    required ApiClient apiClient,
    UserThemePreference initialThemeMode = UserThemePreference.system,
    UserLanguagePreference initialLanguageCode = UserLanguagePreference.system,
  }) : _userApiService = userApiService,
       _secureStorageService = secureStorageService,
       _apiClient = apiClient,
       _localThemeMode = initialThemeMode,
       _localLanguageCode = initialLanguageCode {
    syncApiLocale();
  }

  final UserApiService _userApiService;
  final SecureStorageService _secureStorageService;
  final ApiClient _apiClient;
  UserThemePreference _localThemeMode;
  UserLanguagePreference _localLanguageCode;

  int? _userId;
  UserResourcesResponse? resources;
  UserPreferencesResponse? preferences;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  int get fichas => resources?.fichas ?? 0;

  UserThemePreference get storedThemePreference =>
      preferences?.themeMode ?? _localThemeMode;

  UserLanguagePreference get storedLanguagePreference =>
      preferences?.languageCode ?? _localLanguageCode;

  /// Valor mostrado en el selector (sin opción "Sistema").
  UserThemePreference get uiThemeSelection {
    final stored = storedThemePreference;
    if (stored != UserThemePreference.system) {
      return stored;
    }
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark
        ? UserThemePreference.dark
        : UserThemePreference.light;
  }

  UserLanguagePreference get uiLanguageSelection {
    final stored = storedLanguagePreference;
    if (stored != UserLanguagePreference.system) {
      return stored;
    }
    final tag = AppLocaleResolver.apiLanguageTag(
      preference: UserLanguagePreference.system,
    );
    return tag == 'en' ? UserLanguagePreference.en : UserLanguagePreference.es;
  }

  ThemeMode get appThemeMode {
    switch (storedThemePreference) {
      case UserThemePreference.system:
        return ThemeMode.system;
      case UserThemePreference.light:
        return ThemeMode.light;
      case UserThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  UserThemePreference get currentThemePreference => storedThemePreference;

  Locale? get appLocale {
    switch (storedLanguagePreference) {
      case UserLanguagePreference.system:
        return null;
      case UserLanguagePreference.es:
        return const Locale('es');
      case UserLanguagePreference.en:
        return const Locale('en');
    }
  }

  String get resolvedLanguageTag => AppLocaleResolver.apiLanguageTag(
    preference: storedLanguagePreference,
  );

  void syncApiLocale() {
    final language = resolvedLanguageTag;
    _apiClient.setAcceptLanguage(language);
    AppLocale.languageCode = language.startsWith('en') ? 'en' : 'es';
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
      syncApiLocale();
      await _persistThemeMode(preferences!.themeMode);
      await _persistLanguageCode(preferences!.languageCode);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTheme(UserThemePreference themeMode) async {
    if (themeMode == UserThemePreference.system) {
      return false;
    }
    return updatePreferences(
      themeMode: themeMode,
      languageCode: storedLanguagePreference,
    );
  }

  Future<bool> updateLanguage(UserLanguagePreference languageCode) async {
    if (languageCode == UserLanguagePreference.system) {
      return false;
    }
    return updatePreferences(
      themeMode: storedThemePreference,
      languageCode: languageCode,
    );
  }

  Future<bool> updatePreferences({
    required UserThemePreference themeMode,
    required UserLanguagePreference languageCode,
  }) async {
    final userId = _userId;
    if (userId == null) {
      await _applyLocalPreferences(themeMode, languageCode);
      return true;
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
      await _applyLocalPreferences(themeMode, languageCode);
      preferences = await _userApiService.updateUserPreferences(
        userId,
        UpdateUserPreferencesRequest(
          themeMode: themeMode,
          languageCode: languageCode,
        ),
      );
      syncApiLocale();
      await _persistThemeMode(preferences!.themeMode);
      await _persistLanguageCode(preferences!.languageCode);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _applyLocalPreferences(
    UserThemePreference themeMode,
    UserLanguagePreference languageCode,
  ) async {
    _localThemeMode = themeMode;
    _localLanguageCode = languageCode;
    if (preferences != null) {
      preferences = UserPreferencesResponse(
        idUsuario: preferences!.idUsuario,
        themeMode: themeMode,
        languageCode: languageCode,
      );
    }
    await _persistThemeMode(themeMode);
    await _persistLanguageCode(languageCode);
    syncApiLocale();
    notifyListeners();
  }

  Future<void> setThemeDark() => updateTheme(UserThemePreference.dark);

  Future<void> setThemeLight() => updateTheme(UserThemePreference.light);

  Future<void> _persistThemeMode(UserThemePreference preference) async {
    _localThemeMode = preference;
    await _secureStorageService.saveThemeMode(_themeToStorage(preference));
  }

  Future<void> _persistLanguageCode(UserLanguagePreference preference) async {
    _localLanguageCode = preference;
    await _secureStorageService.saveLanguageCode(
      _languageToStorage(preference),
    );
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

  static UserLanguagePreference languageFromStorage(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'en':
        return UserLanguagePreference.en;
      case 'es':
        return UserLanguagePreference.es;
      default:
        return UserLanguagePreference.system;
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

  static String _languageToStorage(UserLanguagePreference preference) {
    switch (preference) {
      case UserLanguagePreference.en:
        return 'en';
      case UserLanguagePreference.es:
        return 'es';
      case UserLanguagePreference.system:
        return 'system';
    }
  }
}

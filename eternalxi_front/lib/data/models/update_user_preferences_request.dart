import 'package:eternal_xi/data/models/user_preferences_response.dart';

class UpdateUserPreferencesRequest {
  const UpdateUserPreferencesRequest({
    required this.themeMode,
    required this.languageCode,
  });

  final UserThemePreference themeMode;
  final UserLanguagePreference languageCode;

  Map<String, dynamic> toJson() {
    return {
      'themeMode': _themeToApi(themeMode),
      'languageCode': _languageToApi(languageCode),
    };
  }

  static String _themeToApi(UserThemePreference value) {
    switch (value) {
      case UserThemePreference.system:
        return 'SYSTEM';
      case UserThemePreference.light:
        return 'LIGHT';
      case UserThemePreference.dark:
        return 'DARK';
    }
  }

  static String _languageToApi(UserLanguagePreference value) {
    switch (value) {
      case UserLanguagePreference.system:
        return 'SYSTEM';
      case UserLanguagePreference.es:
        return 'es';
      case UserLanguagePreference.en:
        return 'en';
    }
  }
}

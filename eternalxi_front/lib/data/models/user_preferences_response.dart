enum UserThemePreference { system, light, dark }

enum UserLanguagePreference { system, es, en }

class UserPreferencesResponse {
  const UserPreferencesResponse({
    required this.idUsuario,
    required this.themeMode,
    required this.languageCode,
  });

  final int idUsuario;
  final UserThemePreference themeMode;
  final UserLanguagePreference languageCode;

  factory UserPreferencesResponse.fromJson(Map<String, dynamic> json) {
    return UserPreferencesResponse(
      idUsuario: _asInt(json['idUsuario']),
      themeMode: _themeFromApi(json['themeMode']?.toString()),
      languageCode: _languageFromApi(json['languageCode']?.toString()),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static UserThemePreference _themeFromApi(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'LIGHT':
        return UserThemePreference.light;
      case 'DARK':
        return UserThemePreference.dark;
      case 'SYSTEM':
      default:
        return UserThemePreference.system;
    }
  }

  static UserLanguagePreference _languageFromApi(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ES':
        return UserLanguagePreference.es;
      case 'EN':
        return UserLanguagePreference.en;
      case 'SYSTEM':
      default:
        return UserLanguagePreference.system;
    }
  }
}

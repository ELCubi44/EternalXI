import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local del tema (modo claro/oscuro).
class ThemePreferencesStorage {
  ThemePreferencesStorage(this._prefs);

  static const _themeKey = 'app_theme_mode';

  final SharedPreferences _prefs;

  static Future<ThemePreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemePreferencesStorage(prefs);
  }

  String? readThemeMode() => _prefs.getString(_themeKey);

  Future<void> writeThemeMode(String value) =>
      _prefs.setString(_themeKey, value);
}

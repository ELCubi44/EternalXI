import 'package:eternal_xi/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _tokenTypeKey = 'tokenType';
  static const _userIdKey = 'userId';
  static const _nicknameKey = 'nickname';
  static const _correoKey = 'correo';
  static const _nivelKey = 'nivel';
  static const _fotoKey = 'foto';
  static const _themeModeKey = 'themeMode';
  static const _languageCodeKey = 'languageCode';
  static String _progressCacheKey(int userId) => 'progressCache_$userId';
  static String _seenProgressEventsKey(int userId) =>
      'seenProgressEvents_$userId';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
    required UserModel user,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
    await _storage.write(key: _userIdKey, value: user.id.toString());
    await _storage.write(key: _nicknameKey, value: user.nickname);
    await _storage.write(key: _correoKey, value: user.correo);
    await _storage.write(key: _nivelKey, value: user.nivel.toString());
    await _storage.write(key: _fotoKey, value: user.foto ?? '');
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    String tokenType = 'Bearer',
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
  }

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<String?> getNickname() => _storage.read(key: _nicknameKey);

  Future<String?> getCorreo() => _storage.read(key: _correoKey);

  Future<String?> getNivel() => _storage.read(key: _nivelKey);

  Future<String?> getFoto() => _storage.read(key: _fotoKey);

  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userIdKey, value: user.id.toString());
    await _storage.write(key: _nicknameKey, value: user.nickname);
    await _storage.write(key: _correoKey, value: user.correo);
    await _storage.write(key: _nivelKey, value: user.nivel.toString());
    await _storage.write(key: _fotoKey, value: user.foto ?? '');
  }

  /// Borra solo datos de sesión; conserva tema, idioma y caché de progreso.
  Future<void> clearAuthSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenTypeKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _nicknameKey),
      _storage.delete(key: _correoKey),
      _storage.delete(key: _nivelKey),
      _storage.delete(key: _fotoKey),
    ]);
  }

  Future<void> clearSession() => _storage.deleteAll();

  Future<void> saveThemeMode(String themeMode) {
    return _storage.write(key: _themeModeKey, value: themeMode);
  }

  Future<String?> getThemeMode() => _storage.read(key: _themeModeKey);

  Future<void> saveLanguageCode(String languageCode) {
    return _storage.write(key: _languageCodeKey, value: languageCode);
  }

  Future<String?> getLanguageCode() => _storage.read(key: _languageCodeKey);

  Future<void> saveProgressCache(int userId, String json) {
    return _storage.write(key: _progressCacheKey(userId), value: json);
  }

  Future<String?> loadProgressCache(int userId) {
    return _storage.read(key: _progressCacheKey(userId));
  }

  Future<void> saveSeenProgressEventIds(int userId, Set<int> ids) {
    final raw = ids.map((e) => e.toString()).join(',');
    return _storage.write(key: _seenProgressEventsKey(userId), value: raw);
  }

  Future<Set<int>> loadSeenProgressEventIds(int userId) async {
    final raw = await _storage.read(key: _seenProgressEventsKey(userId));
    if (raw == null || raw.trim().isEmpty) {
      return <int>{};
    }
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
  }
}

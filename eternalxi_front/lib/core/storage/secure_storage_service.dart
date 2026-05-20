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

  Future<void> clearSession() => _storage.deleteAll();

  Future<void> saveThemeMode(String themeMode) {
    return _storage.write(key: _themeModeKey, value: themeMode);
  }

  Future<String?> getThemeMode() => _storage.read(key: _themeModeKey);
}

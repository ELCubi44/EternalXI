/// Tag publico unico derivado del id de usuario (p. ej. #623423).
abstract final class UserPublicTag {
  UserPublicTag._();

  static const _multiplier = 7919;
  static const _offset = 104729;
  static const _mod = 900000;
  static const _base = 100000;

  static int codeForUserId(int userId) {
    if (userId <= 0) return _base;
    return _base + ((userId * _multiplier + _offset) % _mod);
  }

  static String format(int userId) => '#${codeForUserId(userId)}';

  static int? parseCode(String raw) {
    var value = raw.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (!RegExp(r'^\d{5,7}$').hasMatch(value)) {
      return null;
    }
    return int.tryParse(value);
  }
}

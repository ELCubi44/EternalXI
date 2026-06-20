class ApiConstants {
  static const String baseUrl = 'https://api.eternalxi.com/api/v1';

  static const auth = '/auth';
  static const users = '/users';
  static const leagues = '/leagues';
  static const accountDeletion = '/account/deletion';
  static const clashSave = '/clash/save';

  /// URL de la imagen de perfil; [cacheBuster] evita caché tras subir una foto nueva.
  static String userProfilePhotoUrl(int userId, {required int cacheBuster}) {
    return '$baseUrl$users/$userId/photo?v=$cacheBuster';
  }
}

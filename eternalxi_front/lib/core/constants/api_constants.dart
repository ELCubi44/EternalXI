class ApiConstants {
  static const String baseUrl = 'http://217.154.184.202:8080/api/v1';

  static const auth = '/auth';
  static const users = '/users';
  static const leagues = '/leagues';

  /// URL de la imagen de perfil; [cacheBuster] evita caché tras subir una foto nueva.
  static String userProfilePhotoUrl(int userId, {required int cacheBuster}) {
    return '$baseUrl$users/$userId/photo?v=$cacheBuster';
  }
}

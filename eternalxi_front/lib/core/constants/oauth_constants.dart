/// IDs OAuth configurables. Rellena [googleWebClientId] desde Firebase Console
/// (OAuth 2.0 Web client) para que Google Sign-In devuelva idToken en Android.
class OAuthConstants {
  OAuthConstants._();

  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}

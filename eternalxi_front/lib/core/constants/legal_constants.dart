class LegalConstants {
  LegalConstants._();

  static const String legalBaseUrl = 'https://api.eternalxi.com/api/v1/legal';

  static const String privacyPolicyUrl = '$legalBaseUrl/privacy-policy.html';
  static const String termsOfServiceUrl = '$legalBaseUrl/terms-of-service.html';
  static const String communityGuidelinesUrl =
      '$legalBaseUrl/community-guidelines.html';
  static const String accountDeletionUrl = '$legalBaseUrl/account-deletion.html';
  static const int minimumAgeYears = 13;
}

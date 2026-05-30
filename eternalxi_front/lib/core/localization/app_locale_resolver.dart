import 'package:eternal_xi/data/models/user_preferences_response.dart';
import 'package:flutter/widgets.dart';

/// Idioma efectivo para peticiones al backend (`Accept-Language`).
abstract final class AppLocaleResolver {
  AppLocaleResolver._();

  static String apiLanguageTag({
    UserLanguagePreference preference = UserLanguagePreference.system,
    Locale? systemLocale,
  }) {
    switch (preference) {
      case UserLanguagePreference.es:
        return 'es';
      case UserLanguagePreference.en:
        return 'en';
      case UserLanguagePreference.system:
        final locale =
            systemLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
        return locale.languageCode.toLowerCase() == 'en' ? 'en' : 'es';
    }
  }
}

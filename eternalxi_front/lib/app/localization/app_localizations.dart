import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('es'), Locale('en')];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    if (localizations == null) {
      return AppLocalizations(const Locale('es'));
    }
    return localizations;
  }

  static Locale localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) {
      return const Locale('es');
    }
    final code = locale.languageCode.toLowerCase();
    for (final item in supportedLocales) {
      if (item.languageCode == code) {
        return item;
      }
    }
    return const Locale('es');
  }

  static const _values = <String, Map<String, String>>{
    'es': {
      'appTitle': 'Eternal XI',
      'profileTokens': 'Recompensas',
      'preferencesTitle': 'Preferencias',
      'themeModeLabel': 'Tema',
      'languageLabel': 'Idioma',
      'systemOption': 'Sistema',
      'lightOption': 'Claro',
      'darkOption': 'Oscuro',
      'spanishOption': 'Español',
      'englishOption': 'Inglés',
      'preferencesUpdated': 'Preferencias actualizadas',
      'preferencesLoadError': 'No se pudieron cargar las preferencias',
      'preferencesSaveError': 'No se pudieron guardar las preferencias',
      'retry': 'Reintentar',
      'savingPreferences': 'Guardando preferencias...',
    },
    'en': {
      'appTitle': 'Eternal XI',
      'profileTokens': 'Rewards',
      'preferencesTitle': 'Preferences',
      'themeModeLabel': 'Theme',
      'languageLabel': 'Language',
      'systemOption': 'System',
      'lightOption': 'Light',
      'darkOption': 'Dark',
      'spanishOption': 'Spanish',
      'englishOption': 'English',
      'preferencesUpdated': 'Preferences updated',
      'preferencesLoadError': 'Could not load preferences',
      'preferencesSaveError': 'Could not save preferences',
      'retry': 'Retry',
      'savingPreferences': 'Saving preferences...',
    },
  };

  String _t(String key) {
    final languageCode = locale.languageCode.toLowerCase();
    return _values[languageCode]?[key] ?? _values['es']![key]!;
  }

  String get appTitle => _t('appTitle');
  String get profileTokens => _t('profileTokens');
  String get preferencesTitle => _t('preferencesTitle');
  String get themeModeLabel => _t('themeModeLabel');
  String get languageLabel => _t('languageLabel');
  String get systemOption => _t('systemOption');
  String get lightOption => _t('lightOption');
  String get darkOption => _t('darkOption');
  String get spanishOption => _t('spanishOption');
  String get englishOption => _t('englishOption');
  String get preferencesUpdated => _t('preferencesUpdated');
  String get preferencesLoadError => _t('preferencesLoadError');
  String get preferencesSaveError => _t('preferencesSaveError');
  String get retry => _t('retry');
  String get savingPreferences => _t('savingPreferences');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

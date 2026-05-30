import 'package:eternal_xi/app/localization/app_localizations.dart';

abstract final class GameLabels {
  GameLabels._();

  static String positionLabel(
    String value, {
    String localeCode = 'es',
    AppLocalizations? l10n,
  }) {
    final code = value.trim().toUpperCase();
    final isEn = (l10n?.locale.languageCode ?? localeCode).startsWith('en');
    switch (code) {
      case 'POR':
      case 'GK':
        return isEn ? 'Goalkeeper' : 'Portero';
      case 'DEF':
        return isEn ? 'Defender' : 'Defensa';
      case 'MED':
      case 'MC':
        return isEn ? 'Midfielder' : 'Mediocentro';
      case 'DEL':
      case 'FW':
        return isEn ? 'Forward' : 'Delantero';
      default:
        return code;
    }
  }

  static String playerStyleLabel(
    String value, {
    String localeCode = 'es',
    AppLocalizations? l10n,
  }) {
    final code = value.trim().toUpperCase();
    final isEn = (l10n?.locale.languageCode ?? localeCode).startsWith('en');
    switch (code) {
      case 'PICARO':
        return isEn ? 'Trickster' : 'Pícaro';
      case 'PRECISO':
        return isEn ? 'Precise' : 'Preciso';
      case 'POTENTE':
        return isEn ? 'Powerful' : 'Potente';
      case 'VALIENTE':
        return isEn ? 'Brave' : 'Valiente';
      case 'AGIL':
        return isEn ? 'Agile' : 'Ágil';
      default:
        return code;
    }
  }

  static String achievementCategoryLabel(
    String value, {
    String localeCode = 'es',
    AppLocalizations? l10n,
  }) {
    final code = value.trim().toUpperCase();
    final isEn = (l10n?.locale.languageCode ?? localeCode).startsWith('en');
    switch (code) {
      case 'LEAGUE':
        return isEn ? 'Leagues' : 'Ligas';
      case 'PERFORMANCE':
        return isEn ? 'Performance' : 'Rendimiento';
      case 'MARKET':
        return isEn ? 'Market' : 'Mercado';
      case 'CARDS':
        return isEn ? 'Cards' : 'Cartas';
      case 'REWARDS':
        return isEn ? 'Rewards' : 'Recompensas';
      default:
        return code;
    }
  }

  static String supertechniqueTypeLabel(
    String? value, {
    String localeCode = 'es',
    AppLocalizations? l10n,
  }) {
    final code = (value ?? '').trim().toUpperCase();
    final isEn = (l10n?.locale.languageCode ?? localeCode).startsWith('en');
    switch (code) {
      case 'OFENSIVA':
      case 'ATTACK':
        return isEn ? 'Attack' : 'Ofensiva';
      case 'DEFENSIVA':
      case 'DEFENSE':
        return isEn ? 'Defense' : 'Defensiva';
      case 'PORTERO':
      case 'GOALKEEPER':
        return isEn ? 'Goalkeeper' : 'Portero';
      default:
        return code.isEmpty ? '-' : code;
    }
  }
}

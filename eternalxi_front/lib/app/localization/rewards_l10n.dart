import 'package:flutter/material.dart';

/// Textos del módulo de recompensas / tienda de puntos (es + en).
class RewardsL10n {
  RewardsL10n(this._en);

  final bool _en;

  factory RewardsL10n.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return RewardsL10n(code == 'en');
  }

  String get shopSubtitle =>
      _en ? 'Packs, cards and coach' : 'Sobres, cartas y entrenador';

  String get noUserSession => _en
      ? 'Could not identify the current user.'
      : 'No se pudo identificar el usuario actual.';

  String get yourLeagues => _en ? 'Your leagues' : 'Tus ligas';

  String get noLeaguesHint => _en
      ? 'You are not in any league. Create one or join with a code.'
      : 'No participas en ninguna liga. Crea una o únete con código.';

  String get selectLeagueTitle =>
      _en ? 'Select a league' : 'Selecciona una liga';

  String get selectLeagueBody => _en
      ? 'Each league has its own reward points, packs, cards and coach.'
      : 'Cada liga tiene sus propios puntos de recompensa, sobres, cartas y entrenador.';

  String participants(int n) => _en ? '$n participants' : '$n participantes';

  String get youAdmin => _en ? 'You manage' : 'Administras';

  String get enter => _en ? 'Enter' : 'Entrar';

  String get tabPacks => _en ? 'Packs' : 'Sobres';

  String get tabCoach => _en ? 'Coach' : 'Entrenador';

  String get tabCards => _en ? 'Cards' : 'Cartas';

  String get tabHistory => _en ? 'History' : 'Historial';

  String get points => _en ? 'Points' : 'Puntos';

  String get cardsAvailable =>
      _en ? 'Available cards' : 'Cartas disponibles';

  String get spin => _en ? 'Spin' : 'Girar';

  String get openPack => _en ? 'Open pack' : 'Abrir sobre';

  String get close => _en ? 'Close' : 'Cerrar';

  String get continueLabel => _en ? 'Continue' : 'Continuar';

  String get useCard => _en ? 'Use card' : 'Usar carta';

  String get viewMyCards => _en ? 'View my cards' : 'Ver mis cartas';

  String get ok => _en ? 'OK' : 'OK';

  String get confirm => _en ? 'Confirm' : 'Confirmar';

  String get filterAll => _en ? 'All' : 'Todas';

  String get filterSell => _en ? 'Sale' : 'Venta';

  String get filterClause => _en ? 'Clause' : 'Cláusula';

  String get filterProtection => _en ? 'Protection' : 'Protección';

  String get filterPoints => _en ? 'Points' : 'Puntos';

  String get filterValue => _en ? 'Value' : 'Valor';

  String get activityEmpty => _en
      ? 'No activity in this league yet.'
      : 'Aún no hay actividad en esta liga.';

  String get actionFailed => _en
      ? 'Could not complete the action. Please try again.'
      : 'No se pudo completar la acción. Inténtalo de nuevo.';

  String get rouletteAlreadyUsed => _en
      ? 'The roulette was already used. Showing the assigned coach.'
      : 'La ruleta ya estaba usada. Se muestra el entrenador asignado.';

  String shopFilterLabel(String key) {
    switch (key) {
      case 'ALL':
        return _en ? 'All' : 'Todo';
      case 'PACK_OPENED':
        return tabPacks;
      case 'COACH_ROULETTE':
        return _en ? 'Roulette' : 'Ruleta';
      case 'CARD_REDEEMED':
        return tabCards;
      default:
        return key;
    }
  }

  String get insufficientPoints =>
      _en ? 'Insufficient points' : 'Puntos insuficientes';

  String get coachRouletteTitle =>
      _en ? 'Coach roulette' : 'Ruleta de entrenador';

  String get yourCoach => _en ? 'Your coach' : 'Tu entrenador';

  String get rouletteUsed => _en ? 'Roulette already used' : 'Ruleta ya utilizada';

  String get coachRouletteHint => _en
      ? 'Get a free coach for this league.'
      : 'Consigue un entrenador libre para esta liga.';

  String moneyRange(String min, String max) =>
      _en ? 'Budget: $min — $max' : 'Dinero: $min — $max';

  String get rewardPointsTooltip =>
      _en ? 'Reward points' : 'Puntos de recompensa';

  String leagueFallbackName(int id) => _en ? 'League $id' : 'Liga $id';
}

extension RewardsL10nContext on BuildContext {
  RewardsL10n get rewardsL10n => RewardsL10n.of(this);
}

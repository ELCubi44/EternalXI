import 'package:eternal_xi/core/utils/league_money_format.dart';

/// Si la demarcación es portero, conviene mostrar la fila/chip de paradas aunque sea 0.
bool leaguePositionIsGoalkeeper(String rawPosicion) {
  final p = rawPosicion.trim().toUpperCase();
  return p == 'POR' || p == 'GK' || p.contains('PORT');
}

/// Paradas: siempre visibles para porteros; en otras posiciones solo si hay dato positivo.
bool leagueShouldShowSavesStat(String rawPosicion, int paradas) {
  if (leaguePositionIsGoalkeeper(rawPosicion)) {
    return true;
  }
  return paradas > 0;
}

/// Texto de paradas: solo dato bruto o puntos oficiales del backend (sin calcular en cliente).
String leagueParadasStatDisplayValue(
  int paradas, {
  double? officialPoints,
}) {
  if (officialPoints == null) {
    return '$paradas';
  }
  final y = officialPoints == officialPoints.roundToDouble()
      ? officialPoints.toInt().toString()
      : officialPoints.toStringAsFixed(1).replaceAll('.', ',');
  if (officialPoints > 0) {
    return '$paradas · +$y pts';
  }
  if (officialPoints < 0) {
    return '$paradas · $y pts';
  }
  return '$paradas · 0 pts';
}

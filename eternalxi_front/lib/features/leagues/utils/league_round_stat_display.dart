/// Etiqueta de impacto de puntos solo si el backend envió el valor (`puntosDesglose`).
String? leagueRoundOfficialPointsLabel(double? points) {
  if (points == null) {
    return null;
  }
  if (points > 0) {
    final n = points == points.roundToDouble()
        ? points.toInt().toString()
        : points.toStringAsFixed(1).replaceAll('.', ',');
    return '+$n';
  }
  if (points < 0) {
    final n = points == points.roundToDouble()
        ? points.toInt().toString()
        : points.toStringAsFixed(1).replaceAll('.', ',');
    return n;
  }
  return '0';
}

/// Valor bruto de stat; si hay puntos oficiales, añade `| +N` (nunca calculado en cliente).
String leagueRoundStatDisplayValue(String raw, {double? officialPoints}) {
  final impact = leagueRoundOfficialPointsLabel(officialPoints);
  if (impact == null) {
    return raw;
  }
  return '$raw | $impact';
}

/// Jornada con partido ya jugado o en curso: stats de partido visibles.
bool leagueRoundMatchStatsAreVisible(String estadoJornada) {
  switch (estadoJornada.trim().toUpperCase()) {
    case 'FINALIZADA':
    case 'EN_CURSO':
    case 'EN CURSO':
      return true;
    default:
      return false;
  }
}

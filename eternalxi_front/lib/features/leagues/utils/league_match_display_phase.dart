import 'package:eternal_xi/app/localization/league_l10n.dart';

/// Fase de presentación del partido en UI (marcador vs horario).
enum LeagueMatchDisplayPhase {
  /// Partido no iniciado: mostrar fecha/hora, no marcador 0-0.
  pending,

  /// En curso: marcador + minuto; puede alimentarse del endpoint live.
  live,

  /// Finalizado: marcador final.
  finished,
}

/// Contrato visible del backend (`estadoVisible` en live): prioridad sobre heurísticas genéricas.
LeagueMatchDisplayPhase leagueMatchDisplayPhaseFromEstadoVisible(String raw) {
  final s = _normalizeEstado(raw);
  switch (s) {
    case 'PENDIENTE':
      return LeagueMatchDisplayPhase.pending;
    case 'EN_JUEGO':
    case 'EN_EMPATE':
      return LeagueMatchDisplayPhase.live;
    case 'FINALIZADO':
      return LeagueMatchDisplayPhase.finished;
    default:
      return leagueMatchDisplayPhaseFromEstado(raw);
  }
}

/// Interpreta `estado` del backend (varias convenciones posibles).
LeagueMatchDisplayPhase leagueMatchDisplayPhaseFromEstado(String raw) {
  final s = _normalizeEstado(raw);
  if (s.isEmpty) {
    return LeagueMatchDisplayPhase.pending;
  }
  const pendingStates = <String>{
    'PENDIENTE',
    'PROGRAMADO',
    'PREVISTO',
    'NO_INICIADO',
    'SCHEDULED',
    'UPCOMING',
    'NS',
    '0',
  };
  const finishedStates = <String>{
    'FINALIZADO',
    'FINALIZADA',
    'TERMINADO',
    'TERMINADA',
    'FIN',
    'JUGADO',
    'JUGADA',
    'COMPLETADO',
    'COMPLETADA',
    'CERRADO',
    'CERRADA',
    'FULL_TIME',
    'FULLTIME',
    'FT',
    '2',
  };
  const liveStates = <String>{
    'EN_JUEGO',
    'ENJUEGO',
    'EN_EMPATE',
    'LIVE',
    'EN_CURSO',
    'DIRECTO',
    'JUGANDO',
    'PLAYING',
    '1',
  };
  if (pendingStates.contains(s)) {
    return LeagueMatchDisplayPhase.pending;
  }
  if (s.contains('FINAL') ||
      s.contains('TERMIN') ||
      s.contains('JUGAD') ||
      s.contains('COMPLET') ||
      s.contains('CERRAD') ||
      finishedStates.contains(s)) {
    return LeagueMatchDisplayPhase.finished;
  }
  if (s.contains('JUEGO') ||
      s.contains('CURSO') ||
      s.contains('DIRECTO') ||
      liveStates.contains(s)) {
    return LeagueMatchDisplayPhase.live;
  }
  return LeagueMatchDisplayPhase.pending;
}

String _normalizeEstado(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  var out = trimmed.toUpperCase();
  const accents = {
    'Á': 'A',
    'À': 'A',
    'Ä': 'A',
    'Â': 'A',
    'É': 'E',
    'È': 'E',
    'Ë': 'E',
    'Ê': 'E',
    'Í': 'I',
    'Ì': 'I',
    'Ï': 'I',
    'Î': 'I',
    'Ó': 'O',
    'Ò': 'O',
    'Ö': 'O',
    'Ô': 'O',
    'Ú': 'U',
    'Ù': 'U',
    'Ü': 'U',
    'Û': 'U',
    'Ñ': 'N',
  };
  accents.forEach((k, v) => out = out.replaceAll(k, v));
  out = out
      .replaceAll(' ', '_')
      .replaceAll('-', '_')
      .replaceAll('.', '_')
      .replaceAll('/', '_');
  while (out.contains('__')) {
    out = out.replaceAll('__', '_');
  }
  return out;
}

String leagueMatchPhaseLabel(LeagueMatchDisplayPhase phase, LeagueL10n ll) {
  switch (phase) {
    case LeagueMatchDisplayPhase.pending:
      return ll.matchPhaseScheduled;
    case LeagueMatchDisplayPhase.live:
      return ll.matchPhaseLive;
    case LeagueMatchDisplayPhase.finished:
      return ll.matchPhaseFinished;
  }
}

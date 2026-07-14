import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';

enum LeagueMatchEventImportance { phase, highlight, minor }

bool isGoalMatchEvent(LeagueMatchEvent e) {
  final t = normalizedLeagueMatchEventType(e);
  return (t == 'GOL' || t.contains('GOL')) && !t.contains('ENCAJ');
}

bool isPhaseMarkerMatchEvent(LeagueMatchEvent e) {
  if (leagueMatchEventIsFullTimeMarker(e)) {
    return true;
  }
  final t = normalizedLeagueMatchEventType(e);
  if (t.contains('DESCANSO') ||
      t.contains('HT') ||
      t.contains('HALF_TIME') ||
      t.contains('MEDIO_TIEMPO') ||
      t.contains('INTERVAL')) {
    return true;
  }
  if (t.contains('INICIO_SEGUNDA_PARTE') ||
      t.contains('SEGUNDA_PARTE') ||
      t.contains('SECOND_HALF') ||
      t.contains('2ND_HALF') ||
      t.contains('REANUD')) {
    return true;
  }
  if (t.contains('INICIO') && !t.contains('SEGUNDA')) {
    return true;
  }
  final text = e.texto.trim().toUpperCase();
  return text.contains('DESCANSO') ||
      text.contains('MEDIO TIEMPO') ||
      text.contains('INICIO DEL PARTIDO') ||
      text.contains('COMIENZA EL PARTIDO') ||
      text.contains('SEGUNDA PARTE');
}

bool isHighlightMatchEvent(LeagueMatchEvent e) {
  if (isPhaseMarkerMatchEvent(e)) {
    return false;
  }
  if (isLoanGroupedEvent(e) || isLoanIndividualEvent(e)) {
    return true;
  }
  if (leagueMatchEventTipoCambioSustitucion(e)) {
    return true;
  }
  if (isGoalMatchEvent(e) ||
      isRedCardMatchEvent(e) ||
      isInjuryMatchEvent(e)) {
    return true;
  }
  final t = normalizedLeagueMatchEventType(e);
  if (t.contains('PARADA') ||
      t.contains('OCASION') ||
      t.contains('PENALTI') ||
      (t.contains('TARJETA') && t.contains('AMARILL'))) {
    return true;
  }
  if (t.contains('ASISTENCIA')) {
    return true;
  }
  return false;
}

LeagueMatchEventImportance classifyLeagueMatchEventImportance(LeagueMatchEvent e) {
  if (isPhaseMarkerMatchEvent(e)) {
    return LeagueMatchEventImportance.phase;
  }
  if (isHighlightMatchEvent(e)) {
    return LeagueMatchEventImportance.highlight;
  }
  return LeagueMatchEventImportance.minor;
}

/// La asistencia va integrada en la tarjeta del gol si comparten minuto.
bool shouldSuppressAssistInSummary(
  List<LeagueMatchEvent> ordered,
  LeagueMatchEvent event,
) {
  final t = normalizedLeagueMatchEventType(event);
  if (!t.contains('ASISTENCIA')) {
    return false;
  }
  for (final g in ordered) {
    if (!isGoalMatchEvent(g) || g.minuto != event.minuto) {
      continue;
    }
    if (g.idLigaJugadorSecundario == event.idLigaJugadorPrincipal &&
        g.idLigaJugadorPrincipal == event.idLigaJugadorSecundario) {
      return true;
    }
  }
  return false;
}

String? assistPlayerNameForGoal(
  List<LeagueMatchEvent> ordered,
  LeagueMatchEvent goal,
) {
  for (final e in ordered) {
    if (!shouldSuppressAssistInSummary(ordered, e)) {
      continue;
    }
    if (e.minuto != goal.minuto) {
      continue;
    }
    if (goal.idLigaJugadorSecundario == e.idLigaJugadorPrincipal) {
      final name = e.jugadorPrincipal.trim();
      return name.isEmpty ? null : name;
    }
  }
  final sec = goal.jugadorSecundario.trim();
  return sec.isEmpty ? null : sec;
}

bool isSecondHalfStartMarkerEvent(LeagueMatchEvent e) {
  final t = normalizedLeagueMatchEventType(e);
  if (t.contains('INICIO_SEGUNDA_PARTE') ||
      t.contains('SECOND_HALF') ||
      t.contains('2ND_HALF') ||
      (t.contains('REANUD') && !t.contains('PARTIDO'))) {
    return true;
  }
  if (t.contains('SEGUNDA_PARTE') || t.contains('SEGUNDA PARTE')) {
    return true;
  }
  final text = e.texto.trim().toUpperCase();
  return text.contains('INICIO DE LA SEGUNDA PARTE') ||
      text.contains('EMPIEZA LA SEGUNDA PARTE') ||
      text.contains('SEGUNDA PARTE');
}

bool isHalftimeBreakMarkerEvent(LeagueMatchEvent e) {
  if (isSecondHalfStartMarkerEvent(e)) {
    return false;
  }
  final t = normalizedLeagueMatchEventType(e);
  if (t.contains('DESCANSO') ||
      t.contains('HT') ||
      t.contains('HALF_TIME') ||
      t.contains('MEDIO_TIEMPO') ||
      t.contains('INTERVAL')) {
    return true;
  }
  final text = e.texto.trim().toUpperCase();
  return text.contains('DESCANSO') || text.contains('MEDIO TIEMPO');
}

int eventTotalGameSeconds(LeagueMatchEvent e) {
  final m = e.minuto < 0 ? 0 : e.minuto;
  final s = e.segundo.clamp(0, 59);
  return m * 60 + s;
}

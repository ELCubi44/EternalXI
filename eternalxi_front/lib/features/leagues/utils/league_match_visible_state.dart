import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_match_detail_payload.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_match_lineup_models.dart';
import 'package:eternal_xi/data/models/league_match_live_payload.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';
import 'package:flutter/foundation.dart';

/// Prioridad con **live** (una sola fuente de verdad para listado, hero y polling):
/// 1) `estadoReal` **no vacío**: FINALIZADO → siempre finalizado; PENDIENTE → pendiente;
///    EN_JUEGO / EN_EMPATE / etc. → en juego (no se deja pisar por `estadoVisible`).
/// 2) Si `estadoReal` vacío: `estadoVisible` como matiz del directo.
/// 3) Si aún no hay señal: `estadoReal` vuelve a interpretarse por si acaso.
/// 4) Detalle (`estadoPartido`) y 5) resumen del listado.
LeagueMatchDisplayPhase resolveLeagueMatchDisplayPhase({
  LeagueMatchLivePayload? live,
  String? detailEstado,
  String? summaryEstado,
}) {
  if (live != null) {
    final rs = live.estadoReal.trim();
    if (rs.isNotEmpty) {
      final rp = leagueMatchDisplayPhaseFromEstado(rs);
      if (rp == LeagueMatchDisplayPhase.finished) {
        return LeagueMatchDisplayPhase.finished;
      }
      if (rp == LeagueMatchDisplayPhase.pending) {
        return LeagueMatchDisplayPhase.pending;
      }
      if (rp == LeagueMatchDisplayPhase.live) {
        return LeagueMatchDisplayPhase.live;
      }
    }

    final vs = live.estadoVisible.trim();
    if (vs.isNotEmpty) {
      return leagueMatchDisplayPhaseFromEstadoVisible(vs);
    }

    if (rs.isNotEmpty) {
      return leagueMatchDisplayPhaseFromEstado(rs);
    }
  }

  final d = detailEstado?.trim() ?? '';
  if (d.isNotEmpty) {
    final p = leagueMatchDisplayPhaseFromEstado(d);
    if (p != LeagueMatchDisplayPhase.pending) {
      return p;
    }
  }
  return leagueMatchDisplayPhaseFromEstado(summaryEstado ?? '');
}

/// Marcador visible: si hay live, siempre goles mostrados del live; si no, detalle/resumen.
int resolveLeagueMatchScoreLocal({
  LeagueMatchLivePayload? live,
  LeagueMatchDetailPayload? detail,
  required LeagueMatchSummary summary,
}) {
  if (live != null) {
    return live.golesLocalMostrados;
  }
  return detail?.golesLocal ?? summary.golesLocal;
}

int resolveLeagueMatchScoreVisitante({
  LeagueMatchLivePayload? live,
  LeagueMatchDetailPayload? detail,
  required LeagueMatchSummary summary,
}) {
  if (live != null) {
    return live.golesVisitanteMostrados;
  }
  return detail?.golesVisitante ?? summary.golesVisitante;
}

/// Orden cronológico estable (minuto, segundo solo para desempate, id).
int compareLeagueMatchEventsChrono(LeagueMatchEvent a, LeagueMatchEvent b) {
  final minComp = a.minuto.compareTo(b.minuto);
  if (minComp != 0) {
    return minComp;
  }
  final secComp = a.segundo.compareTo(b.segundo);
  if (secComp != 0) {
    return secComp;
  }
  return a.idEvento.compareTo(b.idEvento);
}

/// Fin de partido: tipo `FINAL` (y variantes habituales) o texto de cierre sin jugador principal.
bool leagueMatchEventIsFullTimeMarker(LeagueMatchEvent e) {
  final t = e.tipo.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
  if (t == 'FINAL' ||
      t == 'FIN' ||
      t == 'FT' ||
      t == 'FULL_TIME' ||
      t.contains('FINAL_PARTIDO') ||
      t.contains('FIN_DEL_PARTIDO') ||
      t.contains('FIN_DE_PARTIDO') ||
      t.contains('FIN_PARTIDO')) {
    return true;
  }
  final text = e.texto.trim().toUpperCase();
  if (text.contains('FINAL DEL PARTIDO') ||
      text.contains('FIN DEL PARTIDO') ||
      (text == 'FINAL' && e.idLigaJugadorPrincipal <= 0)) {
    return true;
  }
  return false;
}

/// Tras ordenar, corta en el primer evento de fin de partido **incluido**;
/// no se muestran eventos posteriores aunque el backend los envíe.
List<LeagueMatchEvent> applyLeagueMatchTimelineDisplayRules(
  List<LeagueMatchEvent> events,
) {
  if (events.isEmpty) {
    return events;
  }
  final sorted = List<LeagueMatchEvent>.from(events)
    ..sort(compareLeagueMatchEventsChrono);
  for (var i = 0; i < sorted.length; i++) {
    if (leagueMatchEventIsFullTimeMarker(sorted[i])) {
      return sorted.sublist(0, i + 1);
    }
  }
  return sorted;
}

/// Cronología unificada:
/// - En **juego** con live: solo `eventosVisibles` (aunque esté vacío; no mezclar detalle).
/// - **Finalizado** con live: `eventosVisibles` si no está vacío; si no, `detail.eventos`.
/// - Sin live: eventos del detalle persistido.
/// - Siempre se aplica [applyLeagueMatchTimelineDisplayRules] (corte tras fin de partido).
List<LeagueMatchEvent> resolveLeagueMatchTimelineEvents({
  LeagueMatchLivePayload? live,
  LeagueMatchDetailPayload? detail,
  String? summaryEstado,
}) {
  final phase = resolveLeagueMatchDisplayPhase(
    live: live,
    detailEstado: detail?.estadoPartido,
    summaryEstado: summaryEstado ?? '',
  );

  List<LeagueMatchEvent> raw;
  if (live != null) {
    if (phase == LeagueMatchDisplayPhase.live) {
      raw = List<LeagueMatchEvent>.from(live.eventosVisibles);
    } else if (phase == LeagueMatchDisplayPhase.finished) {
      if (live.eventosVisibles.isNotEmpty) {
        raw = List<LeagueMatchEvent>.from(live.eventosVisibles);
      } else {
        raw = List<LeagueMatchEvent>.from(detail?.eventos ?? const []);
      }
    } else {
      raw = List<LeagueMatchEvent>.from(detail?.eventos ?? const []);
      final preMatchFromLive = live.eventosVisibles
          .where(_isLoanPreMatchInfoEvent)
          .toList(growable: false);
      if (preMatchFromLive.isNotEmpty) {
        final merged = <LeagueMatchEvent>[...raw];
        for (final e in preMatchFromLive) {
          final exists = merged.any(
            (m) =>
                m.minuto == e.minuto &&
                m.segundo == e.segundo &&
                m.tipo == e.tipo &&
                m.idLigaJugadorPrincipal == e.idLigaJugadorPrincipal &&
                m.texto == e.texto,
          );
          if (!exists) {
            merged.add(e);
          }
        }
        raw = merged;
      }
    }
  } else {
    raw = List<LeagueMatchEvent>.from(detail?.eventos ?? const []);
  }

  if (kDebugMode) {
    final src = live != null
        ? (phase == LeagueMatchDisplayPhase.live
              ? 'live.eventosVisibles'
              : (phase == LeagueMatchDisplayPhase.finished &&
                        live.eventosVisibles.isNotEmpty
                    ? 'live.eventosVisibles'
                    : 'detail.eventos'))
        : 'detail.eventos';
    debugPrint('[match-timeline][source] phase=$phase lista=$src count=${raw.length}');
    for (final e in raw) {
      debugPrint(
        '[match-timeline][event] id=${e.idEvento} min=${e.minuto} sec=${e.segundo} type=${normalizedLeagueMatchEventType(e)} player=${e.idLigaJugadorPrincipal} text="${e.texto}"',
      );
    }
  }
  final renderable = applyLeagueMatchTimelineDisplayRules(raw);
  if (kDebugMode) {
    debugPrint(
      '[match-timeline][render-list] total=${renderable.length} ids=${renderable.map((e) => e.idEvento).join(",")}',
    );
  }
  return renderable;
}

bool _isLoanPreMatchInfoEvent(LeagueMatchEvent e) {
  return isAnyLoanEvent(e);
}

/// Minuto a mostrar en cabecera/listado cuando el partido está en juego.
/// Los segundos del backend solo sirven para orden interno; **nunca** se muestran en UI.
String? resolveLiveMinuteLabel({
  LeagueMatchLivePayload? live,
  required LeagueMatchDisplayPhase phase,
}) {
  if (live == null || phase != LeagueMatchDisplayPhase.live) {
    return null;
  }
  return '${live.minutoActual}′';
}

/// `idLigaEquipoGanador` en API es **id de equipo** (`equipos.id`), no `liga_equipos`.
int? resolveWinningEquipoId({
  required int idLigaEquipoGanador,
  required bool empate,
  required int idEquipoLocal,
  required int idEquipoVisitante,
}) {
  if (empate) {
    return null;
  }
  final g = idLigaEquipoGanador;
  if (g <= 0) {
    return null;
  }
  if (g == idEquipoLocal) {
    return idEquipoLocal;
  }
  if (g == idEquipoVisitante) {
    return idEquipoVisitante;
  }
  return null;
}

/// Roster para cronología: prioriza alineaciones del live si vienen; si no, las del detalle.
class LeagueMatchRoster {
  const LeagueMatchRoster({
    required this.localPlayerIds,
    required this.awayPlayerIds,
    required this.playersById,
  });

  final Set<int> localPlayerIds;
  final Set<int> awayPlayerIds;
  final Map<int, LeagueSquadPlayer> playersById;
}

LeagueMatchRoster buildLeagueMatchRoster({
  required LeagueMatchDetailPayload detail,
  LeagueMatchLivePayload? live,
}) {
  final locSide = _pickLineupSide(live?.lineupLocal, detail.lineupLocal);
  final visSide = _pickLineupSide(
    live?.lineupVisitante,
    detail.lineupVisitante,
  );

  final titL = locSide?.titulares ?? const <LeagueSquadPlayer>[];
  final subL = locSide?.suplentes ?? const <LeagueSquadPlayer>[];
  final titV = visSide?.titulares ?? const <LeagueSquadPlayer>[];
  final subV = visSide?.suplentes ?? const <LeagueSquadPlayer>[];

  final localIds = <int>{
    for (final p in titL) p.idLigaJugador,
    for (final p in subL) p.idLigaJugador,
  }..removeWhere((id) => id <= 0);

  final awayIds = <int>{
    for (final p in titV) p.idLigaJugador,
    for (final p in subV) p.idLigaJugador,
  }..removeWhere((id) => id <= 0);

  final playersById = <int, LeagueSquadPlayer>{
    for (final p in titL) p.idLigaJugador: p,
    for (final p in subL) p.idLigaJugador: p,
    for (final p in titV) p.idLigaJugador: p,
    for (final p in subV) p.idLigaJugador: p,
  }..removeWhere((k, _) => k <= 0);

  return LeagueMatchRoster(
    localPlayerIds: localIds,
    awayPlayerIds: awayIds,
    playersById: playersById,
  );
}

LeagueMatchLineupSide? _pickLineupSide(
  LeagueMatchLineupSide? liveSide,
  LeagueMatchLineupSide? detailSide,
) {
  if (liveSide != null && !liveSide.isEmpty) {
    return liveSide;
  }
  return detailSide;
}

/// Polling del live: en juego o empate en juego siempre; pendiente solo cerca del inicio; finalizado no.
bool shouldPollLeagueMatchLive({
  required LeagueMatchDisplayPhase phase,
  required DateTime? kickoff,
}) {
  if (phase == LeagueMatchDisplayPhase.finished) {
    return false;
  }
  if (phase == LeagueMatchDisplayPhase.live) {
    return true;
  }
  if (phase != LeagueMatchDisplayPhase.pending) {
    return false;
  }
  if (kickoff == null) {
    return true;
  }
  final now = DateTime.now();
  final untilKickoff = kickoff.difference(now);
  if (!untilKickoff.isNegative && untilKickoff.inMinutes <= 180) {
    return true;
  }
  final k = kickoff.toLocal();
  final n = now.toLocal();
  return k.year == n.year && k.month == n.month && k.day == n.day;
}

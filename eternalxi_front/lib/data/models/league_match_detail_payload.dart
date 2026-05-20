import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_match_lineup_models.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';

/// Contrato real: `LeagueMatchDetailResponse` (Spring), JSON camelCase en raíz.
///
/// Claves usadas:
/// * Equipo local: `idEquipoLocal`, `nombreEquipoLocal`, `golesLocal`, …
/// * Equipo visitante: `idEquipoVisitante`, `nombreEquipoVisitante`, `golesVisitante`, …
/// * Titulares / suplentes: `titularesLocal`, `suplentesLocal`, `titularesVisitante`, `suplentesVisitante`
/// * Eventos: `eventos`
///
/// El campo de estado persistido en detalle es `estado` (no mezclar con `estadoVisible` del live).

class LeagueMatchDetailPayload {
  const LeagueMatchDetailPayload({
    required this.raw,
    required this.summary,
    this.lineupLocal,
    this.lineupVisitante,
    this.eventos = const [],
  });

  final Map<String, dynamic> raw;
  final LeagueMatchSummary summary;
  final LeagueMatchLineupSide? lineupLocal;
  final LeagueMatchLineupSide? lineupVisitante;
  final List<LeagueMatchEvent> eventos;

  LeagueMatchDisplayPhase get displayPhase =>
      leagueMatchDisplayPhaseFromEstado(estadoPartido);

  bool get isFinished => displayPhase == LeagueMatchDisplayPhase.finished;

  bool get isPending => displayPhase == LeagueMatchDisplayPhase.pending;

  bool get isLive => displayPhase == LeagueMatchDisplayPhase.live;

  List<LeagueSquadPlayer> get titularesLocal =>
      lineupLocal?.titulares ?? const [];

  List<LeagueSquadPlayer> get suplentesLocal =>
      lineupLocal?.suplentes ?? const [];

  List<LeagueSquadPlayer> get titularesVisitante =>
      lineupVisitante?.titulares ?? const [];

  List<LeagueSquadPlayer> get suplentesVisitante =>
      lineupVisitante?.suplentes ?? const [];

  Set<int> get localPlayerIds => {
    ...titularesLocal.map((p) => p.idLigaJugador).where((id) => id > 0),
    ...suplentesLocal.map((p) => p.idLigaJugador).where((id) => id > 0),
  };

  Set<int> get awayPlayerIds => {
    ...titularesVisitante.map((p) => p.idLigaJugador).where((id) => id > 0),
    ...suplentesVisitante.map((p) => p.idLigaJugador).where((id) => id > 0),
  };

  bool get hasRenderableLineup {
    final l = lineupLocal;
    final v = lineupVisitante;
    return (l != null && !l.isEmpty) || (v != null && !v.isEmpty);
  }

  int get golesLocal => readLeagueInt(raw, const ['golesLocal']);

  int get golesVisitante => readLeagueInt(raw, const ['golesVisitante']);

  /// Estado persistido del partido en detalle (no `estadoVisible` del directo).
  String get estadoPartido => readLeagueString(raw, const [
    'estado',
    'status',
    'estadoPartido',
    'estado_partido',
    'matchStatus',
    'match_status',
    'fase',
  ]);

  /// Semántica real: id de equipo (`equipos.id`), no `liga_equipos.id`.
  int get idLigaEquipoGanador => readLeagueInt(raw, const [
    'idLigaEquipoGanador',
    'id_liga_equipo_ganador',
  ]);

  bool get empate => readLeagueBool(raw, const ['empate']);

  int? get idJornadaDetalle {
    final v = readLeagueInt(raw, const ['idJornada', 'id_jornada']);
    return v > 0 ? v : null;
  }

  int? get numeroJornadaDetalle {
    final v = readLeagueInt(raw, const [
      'numeroJornada',
      'numero_jornada',
      'numero',
    ]);
    return v > 0 ? v : null;
  }

  DateTime? get inicioPartidoDetalle => pickLeagueMatchKickoffFromMap(raw);

  factory LeagueMatchDetailPayload.fromMap(
    Map<String, dynamic> map,
    LeagueMatchSummary fallbackSummary,
  ) {
    final summary = _summaryFromBackendDetail(map, fallbackSummary);
    final localSide = LeagueMatchLineupSide.tryParseFromMap(
      map,
      titularesKey: 'titularesLocal',
      suplentesKey: 'suplentesLocal',
      formacionKeys: const [
        'formacionLocal',
        'formacion_local',
        'alineacionLocal',
        'alineacion_local',
      ],
      entrenadorKeys: const ['entrenadorLocal', 'entrenador_local'],
    );
    final visitSide = LeagueMatchLineupSide.tryParseFromMap(
      map,
      titularesKey: 'titularesVisitante',
      suplentesKey: 'suplentesVisitante',
      formacionKeys: const [
        'formacionVisitante',
        'formacion_visitante',
        'alineacionVisitante',
        'alineacion_visitante',
      ],
      entrenadorKeys: const ['entrenadorVisitante', 'entrenador_visitante'],
    );

    return LeagueMatchDetailPayload(
      raw: map,
      summary: summary,
      lineupLocal: localSide,
      lineupVisitante: visitSide,
      eventos: _parseEventos(map),
    );
  }

  /// Fusiona `LeagueMatchDetailResponse` con el resumen del calendario (escudos y fechas que el detalle no incluye).
  static LeagueMatchSummary _summaryFromBackendDetail(
    Map<String, dynamic> map,
    LeagueMatchSummary fb,
  ) {
    final idPartido = readLeagueInt(map, const ['idPartido']);
    final idLocal = readLeagueInt(map, const ['idEquipoLocal']);
    final idVis = readLeagueInt(map, const ['idEquipoVisitante']);
    final nombreLocal = readLeagueString(map, const ['nombreEquipoLocal']);
    final nombreVis = readLeagueString(map, const ['nombreEquipoVisitante']);
    final fecha = pickLeagueMatchKickoffFromMap(map) ?? fb.fechaPartido;
    final gl = readLeagueInt(map, const ['golesLocal']);
    final gv = readLeagueInt(map, const ['golesVisitante']);
    final estado = readLeagueString(map, const [
      'estado',
      'status',
      'estadoPartido',
      'estado_partido',
      'matchStatus',
      'match_status',
      'fase',
    ]);
    final idJ = readLeagueInt(map, const ['idJornada', 'id_jornada']);
    final numJ = readLeagueInt(map, const [
      'numeroJornada',
      'numero_jornada',
      'numero',
    ]);

    return LeagueMatchSummary(
      idPartido: idPartido > 0 ? idPartido : fb.idPartido,
      idEquipoLocal: idLocal > 0 ? idLocal : fb.idEquipoLocal,
      idEquipoVisitante: idVis > 0 ? idVis : fb.idEquipoVisitante,
      nombreLocal: nombreLocal.isNotEmpty ? nombreLocal : fb.nombreLocal,
      nombreVisitante: nombreVis.isNotEmpty ? nombreVis : fb.nombreVisitante,
      fotoEscudoLocal: fb.fotoEscudoLocal,
      fotoEscudoVisitante: fb.fotoEscudoVisitante,
      fechaPartido: fecha,
      golesLocal: gl,
      golesVisitante: gv,
      estado: estado.isNotEmpty ? estado : fb.estado,
      idJornada: idJ > 0 ? idJ : fb.idJornada,
      numeroJornada: numJ > 0 ? numJ : fb.numeroJornada,
    );
  }

  static List<LeagueMatchEvent> _parseEventos(Map<String, dynamic> map) {
    final raw = map['eventos'];
    if (raw is! List) {
      return const [];
    }
    final out = <LeagueMatchEvent>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final row = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueMatchEvent.fromBackend(row));
    }
    return out;
  }
}

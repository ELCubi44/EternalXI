import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_match_lineup_models.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';

/// Respuesta de `GET .../matches/{idPartido}/live`.
class LeagueMatchLivePayload {
  const LeagueMatchLivePayload({
    required this.raw,
    required this.idPartido,
    required this.idLiga,
    required this.idJornada,
    required this.numeroJornada,
    required this.inicioJornada,
    required this.inicioPartido,
    required this.estadoReal,
    required this.estadoVisible,
    required this.enDirecto,
    required this.minutoActual,
    required this.segundoActual,
    required this.golesLocalMostrados,
    required this.golesVisitanteMostrados,
    required this.eventosVisibles,
    required this.idLigaEquipoLocal,
    required this.idEquipoLocal,
    required this.nombreEquipoLocal,
    required this.idLigaEquipoVisitante,
    required this.idEquipoVisitante,
    required this.nombreEquipoVisitante,
    required this.idLigaEquipoGanador,
    required this.empate,
    this.lineupLocal,
    this.lineupVisitante,
  });

  final Map<String, dynamic> raw;
  final int idPartido;
  final int idLiga;
  final int idJornada;
  final int numeroJornada;
  final DateTime? inicioJornada;
  final DateTime? inicioPartido;
  final String estadoReal;
  final String estadoVisible;
  final bool enDirecto;
  final int minutoActual;
  final int segundoActual;
  final int golesLocalMostrados;
  final int golesVisitanteMostrados;
  final List<LeagueMatchEvent> eventosVisibles;

  final int idLigaEquipoLocal;
  final int idEquipoLocal;
  final String nombreEquipoLocal;
  final int idLigaEquipoVisitante;
  final int idEquipoVisitante;
  final String nombreEquipoVisitante;

  /// En la práctica del backend, contiene **equipos.id**, no `liga_equipos.id`.
  final int idLigaEquipoGanador;
  final bool empate;

  final LeagueMatchLineupSide? lineupLocal;
  final LeagueMatchLineupSide? lineupVisitante;

  bool get hasRenderableLineup {
    final l = lineupLocal;
    final v = lineupVisitante;
    return (l != null && !l.isEmpty) || (v != null && !v.isEmpty);
  }

  /// Misma regla que [resolveLeagueMatchDisplayPhase] para la parte **solo live**
  /// (sin detalle/resumen del partido).
  LeagueMatchDisplayPhase get displayPhase {
    final rs = estadoReal.trim();
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
    final vs = estadoVisible.trim();
    if (vs.isNotEmpty) {
      return leagueMatchDisplayPhaseFromEstadoVisible(vs);
    }
    if (rs.isNotEmpty) {
      return leagueMatchDisplayPhaseFromEstado(rs);
    }
    return LeagueMatchDisplayPhase.pending;
  }

  factory LeagueMatchLivePayload.fromJson(Map<String, dynamic> json) {
    final eventos = <LeagueMatchEvent>[];
    final rawEv = json['eventosVisibles'] ?? json['eventos_visibles'];
    if (rawEv is List) {
      for (final e in rawEv) {
        if (e is! Map) {
          continue;
        }
        final row = e is Map<String, dynamic>
            ? e
            : Map<String, dynamic>.from(e);
        try {
          eventos.add(LeagueMatchEvent.fromBackend(row));
        } catch (_) {
          // Evento con forma distinta al DTO estándar: omitir
        }
      }
    }

    final locSide = LeagueMatchLineupSide.tryParseFromMap(
      json,
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
    final visSide = LeagueMatchLineupSide.tryParseFromMap(
      json,
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

    return LeagueMatchLivePayload(
      raw: json,
      idPartido: readLeagueInt(json, const ['idPartido', 'id_partido']),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idJornada: readLeagueInt(json, const ['idJornada', 'id_jornada']),
      numeroJornada: readLeagueInt(json, const [
        'numeroJornada',
        'numero_jornada',
        'numero',
      ]),
      inicioJornada: parseLeagueKickoffInstant(
        json['inicioJornada'] ?? json['inicio_jornada'],
      ),
      inicioPartido: parseLeagueKickoffInstant(
        json['inicioPartido'] ?? json['inicio_partido'],
      ),
      estadoReal: readLeagueString(json, const ['estadoReal', 'estado_real']),
      estadoVisible: readLeagueString(json, const [
        'estadoVisible',
        'estado_visible',
      ]),
      enDirecto: readLeagueBool(json, const [
        'enDirecto',
        'en_directo',
        'directo',
      ]),
      minutoActual: readLeagueInt(json, const [
        'minutoActual',
        'minuto_actual',
        'minuto',
      ]),
      segundoActual: readLeagueInt(json, const [
        'segundoActual',
        'segundo_actual',
        'segundo',
      ]),
      golesLocalMostrados: readLeagueInt(json, const [
        'golesLocalMostrados',
        'goles_local_mostrados',
      ]),
      golesVisitanteMostrados: readLeagueInt(json, const [
        'golesVisitanteMostrados',
        'goles_visitante_mostrados',
      ]),
      eventosVisibles: eventos,
      idLigaEquipoLocal: readLeagueInt(json, const [
        'idLigaEquipoLocal',
        'id_liga_equipo_local',
      ]),
      idEquipoLocal: readLeagueInt(json, const [
        'idEquipoLocal',
        'id_equipo_local',
      ]),
      nombreEquipoLocal: readLeagueString(json, const [
        'nombreEquipoLocal',
        'nombre_equipo_local',
      ]),
      idLigaEquipoVisitante: readLeagueInt(json, const [
        'idLigaEquipoVisitante',
        'id_liga_equipo_visitante',
      ]),
      idEquipoVisitante: readLeagueInt(json, const [
        'idEquipoVisitante',
        'id_equipo_visitante',
      ]),
      nombreEquipoVisitante: readLeagueString(json, const [
        'nombreEquipoVisitante',
        'nombre_equipo_visitante',
      ]),
      idLigaEquipoGanador: readLeagueInt(json, const [
        'idLigaEquipoGanador',
        'id_liga_equipo_ganador',
      ]),
      empate: readLeagueBool(json, const ['empate']),
      lineupLocal: locSide,
      lineupVisitante: visSide,
    );
  }
}

import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_editable_lineup.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_lineup_empty_slot.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';

/// Respuesta de `GET /leagues/{idLiga}/participants/{idLigaParticipante}/squad?idUsuario=`.
class LeagueParticipantSquadPayload {
  const LeagueParticipantSquadPayload({
    required this.idLiga,
    required this.idLigaParticipante,
    required this.idUsuarioParticipante,
    required this.nickname,
    required this.alineacion,
    required this.plantilla,
    this.entrenadorRaiz,
    this.entrenadorActivoRaiz = false,
    this.formacionEfectivaRaiz = '',
  });

  final int idLiga;
  final int idLigaParticipante;
  final int idUsuarioParticipante;
  final String nickname;
  final LeagueParticipantSavedLineupPayload alineacion;
  final List<LeagueSquadPlayer> plantilla;

  /// `entrenadorAsignado` a nivel raíz del JSON (contrato; no dentro de [alineacion]).
  final LeagueCoachAssignment? entrenadorRaiz;
  final bool entrenadorActivoRaiz;

  /// `formacionEfectiva` a nivel raíz del JSON (contrato; no dentro de [alineacion]).
  final String formacionEfectivaRaiz;

  factory LeagueParticipantSquadPayload.fromJson(Map<String, dynamic> json) {
    final alMap = json['alineacion'] ?? json['lineup'];
    return LeagueParticipantSquadPayload(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      idUsuarioParticipante: readLeagueInt(json, const [
        'idUsuarioParticipante',
        'id_usuario_participante',
        'idUsuario',
      ]),
      nickname: readLeagueString(json, const ['nickname', 'nick', 'alias']),
      alineacion: alMap is Map
          ? LeagueParticipantSavedLineupPayload.fromJson(
              alMap is Map<String, dynamic>
                  ? alMap
                  : Map<String, dynamic>.from(alMap),
            )
          : const LeagueParticipantSavedLineupPayload(disponible: false),
      plantilla: _parsePlantilla(json['plantilla']),
      entrenadorRaiz: LeagueCoachAssignment.maybeFromJson(
        json['entrenadorAsignado'] ?? json['coach'] ?? json['assignment'],
      ),
      entrenadorActivoRaiz: readLeagueBool(json, const [
        'entrenadorActivo',
        'entrenador_activo',
      ]),
      formacionEfectivaRaiz: readLeagueString(json, const [
        'formacionEfectiva',
        'formacion_efectiva',
      ]),
    );
  }

  static List<LeagueSquadPlayer> _parsePlantilla(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <LeagueSquadPlayer>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final row = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueSquadPlayer.fromJson(row));
    }
    return out;
  }

  /// Convierte la última alineación guardada al formato que usa [LeagueSquadLineupPanel].
  LeagueEditableLineup? toEditableLineupOrNull() {
    if (!alineacion.disponible) {
      return null;
    }
    final t = alineacion.titulares
        .map((p) => p.idLigaJugador)
        .where((id) => id > 0)
        .toList();
    final r = alineacion.reservas
        .map((p) => p.idLigaJugador)
        .where((id) => id > 0)
        .toList();
    final coach = entrenadorRaiz ?? alineacion.entrenadorAsignado;
    final coachActive =
        coach != null &&
        (entrenadorActivoRaiz || alineacion.entrenadorActivo);
    final rootForm = formacionEfectivaRaiz.trim();
    final formacionLineup = alineacion.formacion.trim();
    final formacionCoach = coach?.formacion?.trim() ?? '';
    final formacionEfectiva = rootForm.isNotEmpty
        ? rootForm
        : (formacionLineup.isNotEmpty
            ? formacionLineup
            : (formacionCoach.isNotEmpty ? formacionCoach : '4-3-3'));
    return LeagueEditableLineup(
      idLiga: idLiga,
      idLigaParticipante: idLigaParticipante,
      idJornada: alineacion.idJornadaOrigen,
      numeroJornada: alineacion.numeroJornadaOrigen,
      editableHasta: null,
      bloqueada: true,
      desdeAlineacionGuardada: true,
      titulares: t,
      reservas: r,
      idCapitan: alineacion.idCapitan > 0 ? alineacion.idCapitan : null,
      entrenadorAsignado: coach,
      entrenadorActivo: coachActive,
      formacionEfectiva: formacionEfectiva,
      emptySlots: alineacion.emptySlots,
    );
  }
}

class LeagueParticipantSavedLineupPayload {
  const LeagueParticipantSavedLineupPayload({
    required this.disponible,
    this.idJornadaOrigen = 0,
    this.numeroJornadaOrigen = 0,
    this.formacion = '4-3-3',
    this.idCapitan = 0,
    this.titulares = const [],
    this.reservas = const [],
    this.emptySlots = const [],
    this.entrenadorAsignado,
    this.entrenadorActivo = false,
  });

  final bool disponible;
  final int idJornadaOrigen;
  final int numeroJornadaOrigen;
  final String formacion;
  final int idCapitan;
  final List<LeagueSquadPlayer> titulares;
  final List<LeagueSquadPlayer> reservas;
  final List<LeagueLineupEmptySlot> emptySlots;
  final LeagueCoachAssignment? entrenadorAsignado;
  final bool entrenadorActivo;

  factory LeagueParticipantSavedLineupPayload.fromJson(
    Map<String, dynamic> json,
  ) {
    final disp = readLeagueBool(json, const [
      'disponible',
      'available',
      'alineacionDisponible',
      'alineacion_disponible',
      'lineupAvailable',
      'lineup_available',
    ]);
    return LeagueParticipantSavedLineupPayload(
      disponible: disp,
      idJornadaOrigen: readLeagueInt(json, const [
        'idJornadaOrigen',
        'id_jornada_origen',
        'idJornada',
        'id_jornada',
      ]),
      numeroJornadaOrigen: readLeagueInt(json, const [
        'numeroJornadaOrigen',
        'numero_jornada_origen',
        'numeroJornada',
        'numero_jornada',
        'numero',
      ]),
      formacion: readLeagueString(json, const [
        'formacion',
        'formación',
        'formation',
      ]),
      idCapitan: readLeagueInt(json, const ['idCapitan', 'id_capitan']),
      titulares: _parsePlayers(json['titulares']),
      reservas: _parsePlayers(json['reservas']),
      emptySlots: LeagueLineupEmptySlot.listFromJson(
        json['emptySlots'] ?? json['empty_slots'],
      ),
      entrenadorAsignado: LeagueCoachAssignment.maybeFromJson(
        json['entrenadorAsignado'] ?? json['coach'] ?? json['assignment'],
      ),
      entrenadorActivo: readLeagueBool(json, const [
        'entrenadorActivo',
        'entrenador_activo',
      ]),
    );
  }

  static List<LeagueSquadPlayer> _parsePlayers(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <LeagueSquadPlayer>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final row = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueSquadPlayer.fromJson(row));
    }
    return out;
  }
}

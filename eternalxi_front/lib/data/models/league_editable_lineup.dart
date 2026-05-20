import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_lineup_empty_slot.dart';

/// Respuesta de `GET /leagues/{idLiga}/lineup?idUsuario=`.
class LeagueEditableLineup {
  const LeagueEditableLineup({
    required this.idLiga,
    required this.idLigaParticipante,
    required this.idJornada,
    required this.numeroJornada,
    this.editableHasta,
    required this.bloqueada,
    required this.desdeAlineacionGuardada,
    required this.titulares,
    required this.reservas,
    this.idCapitan,
    this.entrenadorAsignado,
    this.entrenadoresDisponibles = const [],
    this.entrenadorActivo = false,
    this.formacionEfectiva = '4-3-3',
    this.emptySlots = const [],
  });

  final int idLiga;
  final int idLigaParticipante;
  final int idJornada;
  final int numeroJornada;
  final DateTime? editableHasta;
  final bool bloqueada;
  final bool desdeAlineacionGuardada;
  final List<int> titulares;
  final List<int> reservas;
  final int? idCapitan;
  final LeagueCoachAssignment? entrenadorAsignado;
  final List<LeagueCoachAssignment> entrenadoresDisponibles;
  final bool entrenadorActivo;
  final String formacionEfectiva;
  final List<LeagueLineupEmptySlot> emptySlots;

  factory LeagueEditableLineup.fromJson(Map<String, dynamic> json) {
    final formacionRaw = readLeagueString(json, const [
      'formacionEfectiva',
      'formacion_efectiva',
      'formation',
    ], fallback: '4-3-3');
    final formacionTrim = formacionRaw.trim();
    return LeagueEditableLineup(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      idJornada: readLeagueInt(json, const ['idJornada', 'id_jornada']),
      numeroJornada: readLeagueInt(json, const [
        'numeroJornada',
        'numero_jornada',
        'numero',
      ]),
      editableHasta: _readInstant(json, const [
        'editableHasta',
        'editable_hasta',
      ]),
      bloqueada: readLeagueBool(json, const ['bloqueada', 'locked']),
      desdeAlineacionGuardada: readLeagueBool(json, const [
        'desdeAlineacionGuardada',
        'desde_alineacion_guardada',
      ]),
      titulares: _readIdList(json, const ['titulares']),
      reservas: _readIdList(json, const ['reservas']),
      idCapitan: _readNullableId(json, const ['idCapitan', 'id_capitan']),
      entrenadorAsignado: LeagueCoachAssignment.maybeFromJson(
        json['entrenadorAsignado'],
      ),
      entrenadoresDisponibles: LeagueCoachAssignment.listFromJson(
        json['entrenadoresDisponibles'] ?? json['entrenadores'],
      ),
      entrenadorActivo: readLeagueBool(json, const [
        'entrenadorActivo',
        'entrenador_activo',
      ]),
      formacionEfectiva: formacionTrim.isEmpty ? '4-3-3' : formacionTrim,
      emptySlots: LeagueLineupEmptySlot.listFromJson(json['emptySlots']),
    );
  }
}

DateTime? _readInstant(Map<String, dynamic> json, List<String> keys) {
  Object? v;
  for (final k in keys) {
    if (json.containsKey(k)) {
      v = json[k];
      break;
    }
  }
  if (v == null) {
    return null;
  }
  if (v is DateTime) {
    return v;
  }
  final s = v.toString().trim();
  if (s.isEmpty) {
    return null;
  }
  return DateTime.tryParse(s);
}

List<int> _readIdList(Map<String, dynamic> json, List<String> keys) {
  Object? v;
  for (final k in keys) {
    if (json.containsKey(k)) {
      v = json[k];
      break;
    }
  }
  if (v is! List) {
    return const [];
  }
  final out = <int>[];
  for (final e in v) {
    if (e is int && e > 0) {
      out.add(e);
    } else if (e is double) {
      final r = e.round();
      if (r > 0) {
        out.add(r);
      }
    } else if (e is String) {
      final p = int.tryParse(e.trim());
      if (p != null && p > 0) {
        out.add(p);
      }
    }
  }
  return out;
}

int? _readNullableId(Map<String, dynamic> json, List<String> keys) {
  Object? v;
  for (final k in keys) {
    if (json.containsKey(k)) {
      v = json[k];
      break;
    }
  }
  if (v == null) {
    return null;
  }
  if (v is int) {
    return v <= 0 ? null : v;
  }
  if (v is double) {
    final r = v.round();
    return r <= 0 ? null : r;
  }
  if (v is String) {
    final p = int.tryParse(v.trim());
    if (p == null || p <= 0) {
      return null;
    }
    return p;
  }
  return null;
}

import 'package:eternal_xi/data/models/league_json_read.dart';

/// Datos del entrenador asignado en squad / lineup (`entrenadorAsignado`).
class LeagueCoachAssignment {
  const LeagueCoachAssignment({
    this.idEntrenador,
    this.entrenadorNombre,
    this.entrenadorPila,
    this.formacion,
    this.foto,
    this.idEquipo,
    this.equipoNombre,
    this.bonusPuntos = 0,
    this.puntosEntrenadorJornada = 0,
    this.activo = false,
  });

  final int? idEntrenador;
  final String? entrenadorNombre;
  final String? entrenadorPila;
  final String? formacion;
  final String? foto;
  final int? idEquipo;
  final String? equipoNombre;

  /// Bonus fijo del entrenador (configuración). No son puntos de jornada.
  final int bonusPuntos;

  /// Puntos fantasy del entrenador en una jornada concreta (historial / detalle).
  final int puntosEntrenadorJornada;
  final bool activo;

  /// Parseo defensivo: si no hay objeto válido, devuelve `null`.
  static LeagueCoachAssignment? maybeFromJson(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! Map) {
      return null;
    }
    final json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    if (json.isEmpty) {
      return null;
    }
    return LeagueCoachAssignment.fromJson(json);
  }

  static List<LeagueCoachAssignment> listFromJson(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <LeagueCoachAssignment>[];
    for (final row in raw) {
      final parsed = maybeFromJson(row);
      if (parsed != null) {
        out.add(parsed);
      }
    }
    return out;
  }

  factory LeagueCoachAssignment.fromJson(Map<String, dynamic> json) {
    return LeagueCoachAssignment(
      idEntrenador: _readNullableInt(json, const [
        'idEntrenador',
        'id_entrenador',
        'entrenadorId',
      ]),
      entrenadorNombre: _readNullableString(json, const [
        'entrenadorNombre',
        'entrenador_nombre',
        'nombre',
      ]),
      entrenadorPila: _readNullableString(json, const [
        'entrenadorPila',
        'entrenador_pila',
        'pila',
      ]),
      formacion: _readNullableString(json, const [
        'formacion',
        'formación',
        'formation',
      ]),
      foto: _readNullableString(json, const [
        'fotoUrl',
        'foto_url',
        'foto',
        'imagen',
        'urlFoto',
      ]),
      idEquipo: _readNullableInt(json, const ['idEquipo', 'id_equipo']),
      equipoNombre: _readNullableString(json, const [
        'equipoNombre',
        'equipo_nombre',
        'nombreEquipo',
      ]),
      bonusPuntos: readLeagueInt(json, const [
        'bonusPuntos',
        'bonus_puntos',
      ]),
      puntosEntrenadorJornada: readLeagueInt(json, const [
        'puntosEntrenadorJornada',
        'puntos_entrenador_jornada',
        'coachRoundPoints',
        'coach_round_points',
        'puntosJornadaEntrenador',
        'puntos_jornada_entrenador',
      ]),
      activo: readLeagueBool(json, const ['activo', 'active']),
    );
  }
}

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
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
    return v;
  }
  if (v is double) {
    return v.round();
  }
  if (v is String) {
    return int.tryParse(v.trim());
  }
  return null;
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
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
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

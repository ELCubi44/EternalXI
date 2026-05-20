import 'package:eternal_xi/data/models/league_json_read.dart';

/// Entrenador en ruleta / resumen de recompensas.
class RewardCoachItem {
  const RewardCoachItem({
    required this.idEntrenador,
    required this.nombre,
    required this.pila,
    required this.foto,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
  });

  final int idEntrenador;
  final String nombre;
  final String pila;
  final String? foto;
  final int? idEquipo;
  final String? nombreEquipo;
  final String? fotoEquipo;

  String get displayName {
    final pi = pila.trim();
    final no = nombre.trim();
    if (pi.isNotEmpty && no.isNotEmpty) {
      return '$no $pi';
    }
    if (pi.isNotEmpty) {
      return pi;
    }
    if (no.isNotEmpty) {
      return no;
    }
    return 'Entrenador';
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final s = parts.first;
      return s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
    }
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.last.isNotEmpty ? parts.last[0] : '';
    return ('$a$b').toUpperCase();
  }

  factory RewardCoachItem.fromJson(Map<String, dynamic> json) {
    return RewardCoachItem(
      idEntrenador: readLeagueInt(json, const ['idEntrenador', 'id_entrenador']),
      nombre: readLeagueString(json, const ['nombre', 'entrenadorNombre']),
      pila: readLeagueString(json, const ['pila', 'entrenadorPila']),
      foto: _readNullableString(json, const ['foto', 'fotoUrl', 'foto_url']),
      idEquipo: _readNullableInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: _readNullableString(json, const [
        'nombreEquipo',
        'nombre_equipo',
        'equipoNombre',
      ]),
      fotoEquipo: _readNullableString(json, const [
        'fotoEquipo',
        'foto_equipo',
        'escudoEquipo',
      ]),
    );
  }
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  final s = readLeagueString(json, keys);
  final t = s.trim();
  return t.isEmpty ? null : t;
}

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
  final v = readLeagueInt(json, keys);
  return v <= 0 ? null : v;
}

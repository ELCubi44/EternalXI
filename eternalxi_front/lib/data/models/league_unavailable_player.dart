import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueUnavailablePlayer {
  const LeagueUnavailablePlayer({
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.fotoJugador,
    required this.posicion,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.estado,
    required this.lesionadoHasta,
    required this.sancionadoHasta,
    required this.disponibleDesde,
    required this.idJornadaDisponible,
    required this.numeroJornadaDisponible,
    required this.textoDisponibilidad,
  });

  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String? pila;
  final String? fotoJugador;
  final String posicion;
  final int idEquipo;
  final String nombreEquipo;
  final String estado;
  final DateTime? lesionadoHasta;
  final DateTime? sancionadoHasta;
  final DateTime? disponibleDesde;
  final int? idJornadaDisponible;
  final int? numeroJornadaDisponible;
  final String textoDisponibilidad;

  String get displayName {
    final nick = pila?.trim() ?? '';
    if (nick.isNotEmpty) {
      return nick;
    }
    final full = nombre.trim();
    return full.isEmpty ? '—' : full;
  }

  bool get isInjured => estado.trim().toUpperCase() == 'LESIONADO';
  bool get isSuspended => estado.trim().toUpperCase() == 'SANCIONADO';

  DateTime? get unavailableUntil {
    if (isInjured) {
      return lesionadoHasta;
    }
    if (isSuspended) {
      return sancionadoHasta;
    }
    return disponibleDesde;
  }

  factory LeagueUnavailablePlayer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(List<String> keys) {
      final raw = readLeagueString(json, keys).trim();
      if (raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    int? parseNullableInt(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) {
          continue;
        }
        final value = json[key];
        if (value == null) {
          return null;
        }
        return readLeagueInt(json, [key]);
      }
      return null;
    }

    String? parseNullableString(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) {
          continue;
        }
        final value = json[key];
        if (value == null) {
          return null;
        }
        final parsed = readLeagueString(json, [key]).trim();
        return parsed.isEmpty ? null : parsed;
      }
      return null;
    }

    return LeagueUnavailablePlayer(
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: parseNullableString(const ['pila']),
      fotoJugador: parseNullableString(const ['fotoJugador', 'foto_jugador']),
      posicion: readLeagueString(json, const ['posicion']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
      ]),
      estado: readLeagueString(json, const ['estado']),
      lesionadoHasta: parseDate(const ['lesionadoHasta', 'lesionado_hasta']),
      sancionadoHasta: parseDate(const ['sancionadoHasta', 'sancionado_hasta']),
      disponibleDesde: parseDate(const ['disponibleDesde', 'disponible_desde']),
      idJornadaDisponible: parseNullableInt(const [
        'idJornadaDisponible',
        'id_jornada_disponible',
      ]),
      numeroJornadaDisponible: parseNullableInt(const [
        'numeroJornadaDisponible',
        'numero_jornada_disponible',
      ]),
      textoDisponibilidad: readLeagueString(json, const [
        'textoDisponibilidad',
        'texto_disponibilidad',
      ]),
    );
  }
}

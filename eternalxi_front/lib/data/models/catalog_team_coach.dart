import 'package:eternal_xi/core/utils/league_coach_photo.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Entrenador de catálogo (`entrenador` en `/catalog/teams/.../squad`).
class CatalogTeamCoach {
  const CatalogTeamCoach({
    required this.id,
    required this.nombre,
    required this.pila,
    required this.formacion,
    required this.foto,
    this.fotoUrl,
    required this.idEquipo,
    required this.idTemporada,
    required this.bonusPuntos,
    required this.activo,
  });

  final int id;
  final String nombre;
  final String pila;
  final String formacion;
  final String foto;
  final String? fotoUrl;
  final int idEquipo;
  final int idTemporada;
  final int bonusPuntos;
  final bool activo;

  String displayPrimaryName() {
    final nick = pila.trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final full = nombre.trim();
    return full.isEmpty ? 'Entrenador' : full;
  }

  /// Nombre completo para listados (prioriza [nombre]).
  String displayNombreCompleto() {
    final full = nombre.trim();
    if (full.isNotEmpty) {
      return full;
    }
    final nick = pila.trim();
    return nick.isEmpty ? 'Entrenador' : nick;
  }

  String? resolvedFotoUrl() {
    return LeagueCoachPhoto.resolveUrl(
      idEntrenador: id > 0 ? id : null,
      foto: foto,
      fotoUrl: fotoUrl,
    );
  }

  /// Parseo defensivo; devuelve `null` si no hay datos útiles.
  static CatalogTeamCoach? maybeFromJson(dynamic raw) {
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
    final id = readLeagueInt(json, const ['id', 'idEntrenador']);
    if (id <= 0 &&
        readLeagueString(json, const ['nombre', 'pila']).trim().isEmpty) {
      return null;
    }
    return CatalogTeamCoach.fromJson(json);
  }

  factory CatalogTeamCoach.fromJson(Map<String, dynamic> json) {
    return CatalogTeamCoach(
      id: readLeagueInt(json, const ['id', 'idEntrenador', 'id_entrenador']),
      nombre: readLeagueString(json, const [
        'nombre',
        'name',
        'entrenadorNombre',
        'entrenador_nombre',
        'nombreCompleto',
        'nombre_completo',
      ]),
      pila: readLeagueString(json, const ['pila', 'nick', 'alias']),
      formacion: readLeagueString(json, const [
        'formacion',
        'formación',
        'formation',
      ]),
      foto: readLeagueString(json, const ['foto', 'imagen', 'urlFoto']),
      fotoUrl: _readOptionalString(json, const ['fotoUrl', 'foto_url']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      idTemporada: readLeagueInt(json, const ['idTemporada', 'id_temporada']),
      bonusPuntos: readLeagueInt(json, const ['bonusPuntos', 'bonus_puntos']),
      activo: readLeagueBool(json, const ['activo', 'active']),
    );
  }
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  final value = readLeagueString(json, keys).trim();
  return value.isEmpty ? null : value;
}

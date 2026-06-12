import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/catalog_team_summary.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Jugador real de un equipo del catálogo (`GET /catalog/teams/{idEquipo}/players`).
class CatalogTeamPlayer {
  const CatalogTeamPlayer({
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.posicion,
    required this.valoracion,
    required this.valor,
    required this.dorsal,
    required this.fotoJugador,
    this.fotoUrl,
    this.estado,
    this.idUsuarioDueno,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
  });

  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String posicion;
  final double valoracion;
  final double valor;
  final int dorsal;
  final String fotoJugador;
  final String? fotoUrl;
  final String? estado;
  final int? idUsuarioDueno;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;

  String displayName() {
    final nick = pila.trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final full = nombre.trim();
    return full.isEmpty ? 'Jugador' : full;
  }

  String? resolvedFotoJugadorUrl() {
    final preferred = fotoUrl?.trim() ?? '';
    if (preferred.isNotEmpty) {
      final resolvedPreferred = resolveApiAssetUrl(preferred);
      if (resolvedPreferred != null) {
        return resolvedPreferred;
      }
    }
    return LeagueAssetUrls.resolvePlayerPhotoUrl(
      idJugador: idJugador,
      rawFoto: fotoJugador,
    );
  }

  String? resolvedFotoEquipoUrl() {
    return LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: fotoEquipo,
    );
  }

  /// URL absoluta para fotos de catálogo; rechaza rutas `/opt/eternalxi/...`.
  static String? resolvedCatalogAssetUrl(String? raw) {
    return resolveApiAssetUrl(raw);
  }

  /// Roster de `/catalog/teams/{id}/squad` (con `idLigaJugador` si llega con contexto de liga).
  factory CatalogTeamPlayer.fromSquadRosterJson(
    Map<String, dynamic> json, {
    required CatalogTeamSummary equipo,
  }) {
    return CatalogTeamPlayer(
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: readLeagueInt(json, const ['id', 'idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      pila: readLeagueString(json, const [
        'pila',
        'apodo',
        'nick',
        'alias',
      ]),
      posicion: readLeagueString(json, const [
        'posicion',
        'posición',
        'demarcacion',
        'demarcación',
        'rol',
      ]),
      valoracion: readLeagueDouble(json, const [
        'valoracion',
        'valoración',
        'valoracionActual',
        'valoracion_actual',
        'rating',
        'overall',
        'media',
      ]),
      valor: _readCatalogMarketValue(json),
      dorsal: readLeagueInt(json, const ['dorsal', 'numero', 'número', 'num']),
      fotoJugador: readLeagueString(json, const [
        'fotoJugador',
        'foto_jugador',
        'fotoJugadorUrl',
        'foto_jugador_url',
        'foto',
        'imagen',
        'urlFoto',
      ]),
      fotoUrl: _readOptionalString(json, const ['fotoUrl', 'foto_url']),
      estado: _readOptionalString(json, const ['estado', 'status']),
      idUsuarioDueno: _readOptionalInt(json, const [
        'idUsuarioDueno',
        'id_usuario_dueno',
      ]),
      idEquipo: equipo.id > 0
          ? equipo.id
          : readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: equipo.nombre.trim().isNotEmpty
          ? equipo.nombre
          : readLeagueString(json, const [
              'nombreEquipo',
              'nombre_equipo',
              'equipo',
            ]),
      fotoEquipo: equipo.foto.trim().isNotEmpty
          ? equipo.foto
          : readLeagueString(json, const [
              'fotoEquipo',
              'foto_equipo',
              'escudoEquipo',
            ]),
    );
  }

  factory CatalogTeamPlayer.fromJson(Map<String, dynamic> json) {
    return CatalogTeamPlayer(
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      pila: readLeagueString(json, const [
        'pila',
        'apodo',
        'nick',
        'alias',
        'nombreVisible',
        'nombre_visible',
      ]),
      posicion: readLeagueString(json, const [
        'posicion',
        'posición',
        'demarcacion',
        'demarcación',
        'rol',
      ]),
      valoracion: readLeagueDouble(json, const [
        'valoracion',
        'valoración',
        'valoracionActual',
        'valoracion_actual',
        'rating',
        'overall',
        'media',
      ]),
      valor: _readCatalogMarketValue(json),
      dorsal: readLeagueInt(json, const ['dorsal', 'numero', 'número', 'num']),
      fotoJugador: readLeagueString(json, const [
        'fotoJugador',
        'foto_jugador',
        'fotoJugadorUrl',
        'foto_jugador_url',
        'foto',
        'imagen',
        'urlFoto',
      ]),
      fotoUrl: _readOptionalString(json, const ['fotoUrl', 'foto_url']),
      estado: _readOptionalString(json, const ['estado', 'status']),
      idUsuarioDueno: _readOptionalInt(json, const [
        'idUsuarioDueno',
        'id_usuario_dueno',
      ]),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo', 'equipoId']),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
        'equipo',
        'club',
      ]),
      fotoEquipo: readLeagueString(json, const [
        'fotoEquipo',
        'foto_equipo',
        'escudoEquipo',
        'escudo_equipo',
      ]),
    );
  }
}

String? resolveApiAssetUrl(String? raw) => LeagueAssetUrls.buildBackendImageUrl(raw);

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  final value = readLeagueString(json, keys).trim();
  return value.isEmpty ? null : value;
}

int? _readOptionalInt(Map<String, dynamic> json, List<String> keys) {
  final value = readLeagueInt(json, keys);
  return value > 0 ? value : null;
}

double _readCatalogMarketValue(Map<String, dynamic> json) {
  final effective = readLeagueOptionalDouble(json, const [
    'valorMercadoEfectivo',
    'valor_mercado_efectivo',
  ]);
  if (effective != null && effective > 0) {
    return effective;
  }
  return readLeagueDouble(json, const ['valor', 'precio', 'marketValue']);
}

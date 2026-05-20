import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueHomeFeed {
  const LeagueHomeFeed({
    required this.noticiasLesiones,
    required this.goleadores,
    required this.asistidores,
    required this.porteriasCero,
  });

  final List<LeagueHomeInjuryNews> noticiasLesiones;
  final List<LeagueHomeTopPlayer> goleadores;
  final List<LeagueHomeTopPlayer> asistidores;
  final List<LeagueHomeTopPlayer> porteriasCero;

  factory LeagueHomeFeed.fromJson(Map<String, dynamic> json) {
    return LeagueHomeFeed(
      noticiasLesiones: _readList(
        json,
        const ['noticiasLesiones', 'noticias_lesiones'],
        LeagueHomeInjuryNews.fromJson,
      ),
      goleadores: _readList(
        json,
        const ['goleadores'],
        LeagueHomeTopPlayer.fromJson,
      ),
      asistidores: _readList(
        json,
        const ['asistidores'],
        LeagueHomeTopPlayer.fromJson,
      ),
      porteriasCero: _readList(
        json,
        const ['porteriasCero', 'porterias_cero'],
        LeagueHomeTopPlayer.fromJson,
      ),
    );
  }

  static List<T> _readList<T>(
    Map<String, dynamic> json,
    List<String> keys,
    T Function(Map<String, dynamic>) mapFn,
  ) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is! List) {
        continue;
      }
      final out = <T>[];
      for (final row in raw) {
        if (row is! Map) {
          continue;
        }
        final m = row is Map<String, dynamic>
            ? row
            : Map<String, dynamic>.from(row);
        out.add(mapFn(m));
      }
      return out;
    }
    return const [];
  }
}

class LeagueHomeTopPlayer {
  const LeagueHomeTopPlayer({
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.nombreMostrado,
    required this.posicion,
    required this.valoracion,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoJugador,
    required this.fotoEquipo,
    required this.total,
    this.probabilidadTitular,
    this.motivoTitularidad,
    this.idPartidoProbabilidad,
    this.calculadoEnProbabilidad,
  });

  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String nombreMostrado;
  final String posicion;
  final double valoracion;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoJugador;
  final String fotoEquipo;
  final int total;

  final int? probabilidadTitular;
  final String? motivoTitularidad;
  final int? idPartidoProbabilidad;
  final DateTime? calculadoEnProbabilidad;

  factory LeagueHomeTopPlayer.fromJson(Map<String, dynamic> json) {
    return LeagueHomeTopPlayer(
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: readLeagueString(json, const ['pila']),
      nombreMostrado: readLeagueString(json, const [
        'nombreMostrado',
        'nombre_mostrado',
      ]),
      posicion: readLeagueString(json, const ['posicion']),
      valoracion: readLeagueDouble(json, const ['valoracion']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
      ]),
      fotoJugador: readLeagueString(json, const ['fotoJugador', 'foto_jugador']),
      fotoEquipo: readLeagueString(json, const ['fotoEquipo', 'foto_equipo']),
      total: readLeagueInt(json, const ['total']),
      probabilidadTitular: readLeagueOptionalProbabilityTitular(json),
      motivoTitularidad: readLeagueOptionalNonEmptyString(json, const [
        'motivoTitularidad',
        'motivo_titularidad',
      ]),
      idPartidoProbabilidad: readLeagueOptionalPositiveInt(json, const [
        'idPartidoProbabilidad',
        'id_partido_probabilidad',
      ]),
      calculadoEnProbabilidad: readLeagueOptionalDateTime(json, const [
        'calculadoEnProbabilidad',
        'calculado_en_probabilidad',
      ]),
    );
  }

  String displayName() {
    final shown = nombreMostrado.trim();
    if (shown.isNotEmpty) {
      return shown;
    }
    final nick = pila.trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final full = nombre.trim();
    return full.isEmpty ? '—' : full;
  }

  String? resolvedFotoEquipoUrl() {
    return LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: fotoEquipo,
    );
  }

  String? resolvedFotoJugadorUrl() {
    return LeagueAssetUrls.resolvePlayerPhotoUrl(
      idJugador: idJugador,
      rawFoto: fotoJugador,
    );
  }
}

class LeagueHomeInjuryNews {
  const LeagueHomeInjuryNews({
    required this.idEvento,
    required this.idPartido,
    required this.idJornada,
    required this.numeroJornada,
    required this.inicioPartido,
    required this.minuto,
    required this.segundo,
    required this.tipo,
    required this.texto,
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.nombreMostrado,
    required this.fotoJugador,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
    required this.lesionadoHasta,
    required this.lesionActiva,
  });

  final int idEvento;
  final int idPartido;
  final int idJornada;
  final int numeroJornada;
  final DateTime? inicioPartido;
  final int minuto;
  final int segundo;
  final String tipo;
  final String texto;
  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String nombreMostrado;
  final String fotoJugador;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;
  final DateTime? lesionadoHasta;
  final bool lesionActiva;

  factory LeagueHomeInjuryNews.fromJson(Map<String, dynamic> json) {
    return LeagueHomeInjuryNews(
      idEvento: readLeagueInt(json, const ['idEvento', 'id_evento']),
      idPartido: readLeagueInt(json, const ['idPartido', 'id_partido']),
      idJornada: readLeagueInt(json, const ['idJornada', 'id_jornada']),
      numeroJornada: readLeagueInt(json, const [
        'numeroJornada',
        'numero_jornada',
      ]),
      inicioPartido: _readDate(json, const ['inicioPartido', 'inicio_partido']),
      minuto: readLeagueInt(json, const ['minuto']),
      segundo: readLeagueInt(json, const ['segundo']),
      tipo: readLeagueString(json, const ['tipo']),
      texto: readLeagueString(json, const ['texto']),
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: readLeagueString(json, const ['pila']),
      nombreMostrado: readLeagueString(json, const [
        'nombreMostrado',
        'nombre_mostrado',
      ]),
      fotoJugador: readLeagueString(json, const ['fotoJugador', 'foto_jugador']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
      ]),
      fotoEquipo: readLeagueString(json, const ['fotoEquipo', 'foto_equipo']),
      lesionadoHasta: _readDate(json, const [
        'lesionadoHasta',
        'lesionado_hasta',
      ]),
      lesionActiva: readLeagueBool(json, const [
        'lesionActiva',
        'lesion_activa',
      ]),
    );
  }

  String displayName() {
    final shown = nombreMostrado.trim();
    if (shown.isNotEmpty) {
      return shown;
    }
    final nick = pila.trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final full = nombre.trim();
    return full.isEmpty ? '—' : full;
  }

  String? resolvedFotoEquipoUrl() {
    return LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: fotoEquipo,
    );
  }

  String? resolvedFotoJugadorUrl() {
    return LeagueAssetUrls.resolvePlayerPhotoUrl(
      idJugador: idJugador,
      rawFoto: fotoJugador,
    );
  }

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    final raw = readLeagueString(json, keys).trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}

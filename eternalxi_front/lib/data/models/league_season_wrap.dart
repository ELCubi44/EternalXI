import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueSeasonWrapPlayer {
  const LeagueSeasonWrapPlayer({
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.nombreMostrado,
    required this.fotoJugador,
    required this.valor,
  });

  final int idJugador;
  final String nombre;
  final String pila;
  final String nombreMostrado;
  final String fotoJugador;
  final int valor;

  String? get photoUrl => LeagueAssetUrls.resolvePlayerPhotoUrl(
    idJugador: idJugador,
    rawFoto: fotoJugador,
  );

  factory LeagueSeasonWrapPlayer.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const LeagueSeasonWrapPlayer(
        idJugador: 0,
        nombre: '',
        pila: '',
        nombreMostrado: '',
        fotoJugador: '',
        valor: 0,
      );
    }
    return LeagueSeasonWrapPlayer(
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: readLeagueString(json, const ['pila']),
      nombreMostrado: readLeagueString(json, const [
        'nombreMostrado',
        'nombre_mostrado',
      ]),
      fotoJugador: readLeagueString(json, const ['fotoJugador', 'foto_jugador']),
      valor: readLeagueInt(json, const ['valor', 'total']),
    );
  }

  bool get hasData => idJugador > 0 && valor > 0;
}

class LeagueSeasonWrap {
  const LeagueSeasonWrap({
    required this.temporadaCompleta,
    required this.archivada,
    required this.mostrarCinematica,
    required this.posicion,
    required this.totalParticipantes,
    required this.puntosEfectivos,
    required this.nombreLiga,
    this.maxPuntos,
    this.maxGoleador,
    this.maxAsistente,
  });

  final bool temporadaCompleta;
  final bool archivada;
  final bool mostrarCinematica;
  final int posicion;
  final int totalParticipantes;
  final int puntosEfectivos;
  final String nombreLiga;
  final LeagueSeasonWrapPlayer? maxPuntos;
  final LeagueSeasonWrapPlayer? maxGoleador;
  final LeagueSeasonWrapPlayer? maxAsistente;

  factory LeagueSeasonWrap.fromJson(Map<String, dynamic> json) {
    LeagueSeasonWrapPlayer? readPlayer(Object? raw) {
      if (raw is! Map) return null;
      final m = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      final p = LeagueSeasonWrapPlayer.fromJson(m);
      return p.hasData ? p : null;
    }

    return LeagueSeasonWrap(
      temporadaCompleta: readLeagueBool(json, const [
        'temporadaCompleta',
        'temporada_completa',
      ]),
      archivada: readLeagueBool(json, const ['archivada']),
      mostrarCinematica: readLeagueBool(json, const [
        'mostrarCinematica',
        'mostrar_cinematica',
      ]),
      posicion: readLeagueInt(json, const ['posicion']),
      totalParticipantes: readLeagueInt(json, const [
        'totalParticipantes',
        'total_participantes',
      ]),
      puntosEfectivos: readLeagueInt(json, const [
        'puntosEfectivos',
        'puntos_efectivos',
      ]),
      nombreLiga: readLeagueString(json, const ['nombreLiga', 'nombre_liga']),
      maxPuntos: readPlayer(json['maxPuntos'] ?? json['max_puntos']),
      maxGoleador: readPlayer(json['maxGoleador'] ?? json['max_goleador']),
      maxAsistente: readPlayer(json['maxAsistente'] ?? json['max_asistente']),
    );
  }
}

class UserPublicLeaguePlayerStat {
  const UserPublicLeaguePlayerStat({
    required this.nombre,
    required this.foto,
    required this.total,
  });

  final String nombre;
  final String foto;
  final int total;

  String? get photoUrl => LeagueAssetUrls.buildBackendImageUrl(foto);

  factory UserPublicLeaguePlayerStat.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const UserPublicLeaguePlayerStat(nombre: '', foto: '', total: 0);
    }
    return UserPublicLeaguePlayerStat(
      nombre: readLeagueString(json, const ['nombre']),
      foto: readLeagueString(json, const ['foto']),
      total: readLeagueInt(json, const ['total', 'valor']),
    );
  }

  bool get hasData => nombre.trim().isNotEmpty && total > 0;
}

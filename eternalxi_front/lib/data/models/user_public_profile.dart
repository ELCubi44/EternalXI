import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/core/utils/user_public_tag.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_season_wrap.dart';

class UserPublicProfile {
  const UserPublicProfile({
    required this.id,
    required this.nickname,
    required this.foto,
    required this.nivel,
    required this.tagCode,
    required this.relacionAmistad,
    this.idAmistad,
    required this.soySolicitante,
    required this.stats,
    this.jugadorFavorito,
    required this.ligas,
  });

  final int id;
  final String nickname;
  final String foto;
  final int nivel;
  final int tagCode;
  final String relacionAmistad;
  final int? idAmistad;
  final bool soySolicitante;
  final UserPublicStats stats;
  final UserPublicFavoritePlayer? jugadorFavorito;
  final List<UserPublicLeagueSummary> ligas;

  String get tagLabel => UserPublicTag.format(id);

  bool get isFriend => relacionAmistad == 'ACEPTADA';
  bool get isPendingOutgoing =>
      relacionAmistad == 'PENDIENTE' && soySolicitante;
  bool get isPendingIncoming =>
      relacionAmistad == 'PENDIENTE' && !soySolicitante;

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) {
    final favRaw = json['jugadorFavorito'] ?? json['jugador_favorito'];
    UserPublicFavoritePlayer? fav;
    if (favRaw is Map) {
      final m = favRaw is Map<String, dynamic>
          ? favRaw
          : Map<String, dynamic>.from(favRaw);
      fav = UserPublicFavoritePlayer.fromJson(m);
    }

    final statsRaw = json['stats'];
    final stats = statsRaw is Map
        ? UserPublicStats.fromJson(
            statsRaw is Map<String, dynamic>
                ? statsRaw
                : Map<String, dynamic>.from(statsRaw),
          )
        : const UserPublicStats();

    final ligasRaw = json['ligas'] ?? json['leagues'];
    final ligas = <UserPublicLeagueSummary>[];
    if (ligasRaw is List) {
      for (final e in ligasRaw) {
        if (e is! Map) continue;
        ligas.add(
          UserPublicLeagueSummary.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
          ),
        );
      }
    }

    final id = readLeagueInt(json, const ['id']);
    return UserPublicProfile(
      id: id,
      nickname: readLeagueString(json, const ['nickname']),
      foto: readLeagueString(json, const ['foto']),
      nivel: readLeagueInt(json, const ['nivel']),
      tagCode: readLeagueInt(json, const ['tagCode', 'tag_code']),
      relacionAmistad: readLeagueString(json, const [
        'relacionAmistad',
        'relacion_amistad',
      ]),
      idAmistad: readLeagueNullableInt(json, const ['idAmistad', 'id_amistad']),
      soySolicitante: readLeagueBool(json, const [
        'soySolicitante',
        'soy_solicitante',
      ]),
      stats: stats,
      jugadorFavorito: fav,
      ligas: ligas,
    );
  }
}

class UserPublicStats {
  const UserPublicStats({
    this.ligasGanadas = 0,
    this.goles = 0,
    this.asistencias = 0,
    this.porteriasCero = 0,
    this.lesiones = 0,
    this.sanciones = 0,
  });

  final int ligasGanadas;
  final int goles;
  final int asistencias;
  final int porteriasCero;
  final int lesiones;
  final int sanciones;

  factory UserPublicStats.fromJson(Map<String, dynamic> json) {
    return UserPublicStats(
      ligasGanadas: readLeagueInt(json, const [
        'ligasGanadas',
        'ligas_ganadas',
      ]),
      goles: readLeagueInt(json, const ['goles']),
      asistencias: readLeagueInt(json, const ['asistencias']),
      porteriasCero: readLeagueInt(json, const [
        'porteriasCero',
        'porterias_cero',
      ]),
      lesiones: readLeagueInt(json, const ['lesiones']),
      sanciones: readLeagueInt(json, const ['sanciones']),
    );
  }
}

class UserPublicFavoritePlayer {
  const UserPublicFavoritePlayer({
    required this.idJugador,
    required this.nombre,
    required this.foto,
    required this.equipo,
  });

  final int idJugador;
  final String nombre;
  final String foto;
  final String equipo;

  String? get photoUrl => LeagueAssetUrls.resolvePlayerPhotoUrl(
    idJugador: idJugador,
    rawFoto: foto,
  );

  factory UserPublicFavoritePlayer.fromJson(Map<String, dynamic> json) {
    return UserPublicFavoritePlayer(
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      foto: readLeagueString(json, const ['foto']),
      equipo: readLeagueString(json, const ['equipo']),
    );
  }
}

class UserPublicLeagueSummary {
  const UserPublicLeagueSummary({
    required this.idLiga,
    required this.nombreLiga,
    required this.idLigaParticipante,
    required this.estadoLiga,
    required this.puntosFantasy,
    required this.posicionFinal,
    required this.totalParticipantes,
    this.maxGoleador,
    this.maxAsistente,
    this.maxPorteriasCero,
  });

  final int idLiga;
  final String nombreLiga;
  final int idLigaParticipante;
  final String estadoLiga;
  final int puntosFantasy;
  final int posicionFinal;
  final int totalParticipantes;
  final UserPublicLeaguePlayerStat? maxGoleador;
  final UserPublicLeaguePlayerStat? maxAsistente;
  final UserPublicLeaguePlayerStat? maxPorteriasCero;

  factory UserPublicLeagueSummary.fromJson(Map<String, dynamic> json) {
    UserPublicLeaguePlayerStat? readStat(Object? raw) {
      if (raw is! Map) return null;
      final m = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      final s = UserPublicLeaguePlayerStat.fromJson(m);
      return s.hasData ? s : null;
    }

    return UserPublicLeagueSummary(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      nombreLiga: readLeagueString(json, const ['nombreLiga', 'nombre_liga']),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      estadoLiga: readLeagueString(json, const ['estadoLiga', 'estado_liga']),
      puntosFantasy: readLeagueInt(json, const [
        'puntosFantasy',
        'puntos_fantasy',
      ]),
      posicionFinal: readLeagueInt(json, const [
        'posicionFinal',
        'posicion_final',
      ]),
      totalParticipantes: readLeagueInt(json, const [
        'totalParticipantes',
        'total_participantes',
      ]),
      maxGoleador: readStat(json['maxGoleador'] ?? json['max_goleador']),
      maxAsistente: readStat(json['maxAsistente'] ?? json['max_asistente']),
      maxPorteriasCero: readStat(
        json['maxPorteriasCero'] ?? json['max_porterias_cero'],
      ),
    );
  }
}

int? readLeagueNullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw == null) continue;
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
  }
  return null;
}

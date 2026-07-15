import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class EligibleFavoritePlayer {
  const EligibleFavoritePlayer({
    required this.idJugador,
    required this.nombre,
    required this.foto,
    required this.idEquipo,
    required this.equipo,
    required this.fotoEquipo,
  });

  final int idJugador;
  final String nombre;
  final String foto;
  final int idEquipo;
  final String equipo;
  final String fotoEquipo;

  String? get photoUrl => LeagueAssetUrls.resolvePlayerPhotoUrl(
        idJugador: idJugador,
        rawFoto: foto,
      );

  String? get teamBadgeUrl => LeagueAssetUrls.resolveTeamBadgeUrl(
        idEquipo: idEquipo,
        rawFoto: fotoEquipo,
      );

  factory EligibleFavoritePlayer.fromJson(Map<String, dynamic> json) {
    return EligibleFavoritePlayer(
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      foto: readLeagueString(json, const ['foto']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      equipo: readLeagueString(json, const ['equipo']),
      fotoEquipo: readLeagueString(json, const ['fotoEquipo', 'foto_equipo']),
    );
  }
}

class FavoritePickerTeamGroup {
  FavoritePickerTeamGroup({
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
  });

  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;
  final List<EligibleFavoritePlayer> players = [];
}

List<FavoritePickerTeamGroup> groupEligibleFavoritePlayersByTeam(
  List<EligibleFavoritePlayer> players,
) {
  final byTeam = <int, FavoritePickerTeamGroup>{};
  for (final player in players) {
    final group = byTeam.putIfAbsent(
      player.idEquipo,
      () => FavoritePickerTeamGroup(
        idEquipo: player.idEquipo,
        nombreEquipo: player.equipo,
        fotoEquipo: player.fotoEquipo,
      ),
    );
    group.players.add(player);
  }
  final groups = byTeam.values.toList()
    ..sort((a, b) => a.nombreEquipo.compareTo(b.nombreEquipo));
  for (final group in groups) {
    group.players.sort((a, b) => a.nombre.compareTo(b.nombre));
  }
  return groups;
}

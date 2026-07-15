import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class EligibleFavoritePlayer {
  const EligibleFavoritePlayer({
    required this.idJugador,
    required this.nombre,
    required this.foto,
    required this.equipo,
  });

  final int idJugador;
  final String nombre;
  final String foto;
  final String equipo;

  String? get photoUrl => LeagueAssetUrls.buildBackendImageUrl(foto) ??
      (idJugador > 0 ? LeagueAssetUrls.playerPhoto(idJugador).toString() : null);

  factory EligibleFavoritePlayer.fromJson(Map<String, dynamic> json) {
    return EligibleFavoritePlayer(
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      foto: readLeagueString(json, const ['foto']),
      equipo: readLeagueString(json, const ['equipo']),
    );
  }
}

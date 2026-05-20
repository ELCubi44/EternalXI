import 'package:eternal_xi/data/models/catalog_team_coach.dart';
import 'package:eternal_xi/data/models/catalog_team_player.dart';
import 'package:eternal_xi/data/models/catalog_team_summary.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Respuesta de `GET /catalog/teams/{idEquipo}/squad`.
class CatalogTeamSquad {
  const CatalogTeamSquad({
    required this.equipo,
    required this.jugadores,
    this.entrenador,
  });

  final CatalogTeamSummary equipo;
  final CatalogTeamCoach? entrenador;
  final List<CatalogTeamPlayer> jugadores;

  factory CatalogTeamSquad.fromJson(Map<String, dynamic> json) {
    final equipoRaw = json['equipo'];
    if (equipoRaw is! Map) {
      throw const FormatException('Respuesta squad: falta objeto equipo.');
    }
    final equipoMap = equipoRaw is Map<String, dynamic>
        ? equipoRaw
        : Map<String, dynamic>.from(equipoRaw);
    final equipo = CatalogTeamSummary.fromJson(equipoMap);

    final jugadoresRaw = json['jugadores'];
    final jugadoresList = readLeagueListMap(jugadoresRaw);
    final jugadores = jugadoresList
        .map(
          (row) => CatalogTeamPlayer.fromSquadRosterJson(row, equipo: equipo),
        )
        .toList(growable: false);

    return CatalogTeamSquad(
      equipo: equipo,
      entrenador: CatalogTeamCoach.maybeFromJson(json['entrenador']),
      jugadores: jugadores,
    );
  }
}

import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/screens/catalog_team_players_screen.dart';
import 'package:eternal_xi/features/leagues/screens/league_participant_squad_screen.dart';
import 'package:eternal_xi/features/leagues/screens/league_player_profile_screen.dart';
import 'package:eternal_xi/features/leagues/screens/participant_lineup_history_screen.dart';
import 'package:eternal_xi/features/leagues/screens/participant_lineup_round_detail_screen.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:flutter/material.dart';

/// Navegación apilada dentro de la liga (no rutas GoRouter).
abstract final class LeagueInnerNavigation {
  LeagueInnerNavigation._();

  static Future<void> openPlayerProfile({
    required BuildContext context,
    required LeagueSquadPlayer player,
    int? leagueId,
    int? idLigaJugador,
    int? idUsuario,
    int? idJornada,
    bool? isOwnPlayerHint,
    bool? isMarketPlayerHint,
    bool? isNightMarketPlayerHint,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LeaguePlayerProfileScreen(
          player: player,
          leagueId: leagueId,
          idLigaJugador: idLigaJugador ?? player.idLigaJugador,
          idUsuario: idUsuario,
          idJornada: idJornada,
          isOwnPlayerHint: isOwnPlayerHint,
          isMarketPlayerHint: isMarketPlayerHint,
          isNightMarketPlayerHint: isNightMarketPlayerHint,
        ),
      ),
    );
  }

  /// Abre plantilla + última alineación guardada del participante (solo lectura).
  static Future<void> openParticipantSquad({
    required BuildContext context,
    required int leagueId,
    required int idUsuarioViewer,
    required int idUsuarioTarget,
    required int idLigaParticipante,
    required String nickname,
    int? idJornadaForSquad,
  }) {
    if (idUsuarioViewer > 0 && idUsuarioViewer == idUsuarioTarget) {
      final shell = LeagueShellData.maybeOf(context);
      shell?.selectTab(2);
      return Future.value();
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LeagueParticipantSquadScreen(
          leagueId: leagueId,
          idUsuarioViewer: idUsuarioViewer,
          idUsuarioTarget: idUsuarioTarget,
          idLigaParticipante: idLigaParticipante,
          nickname: nickname,
          idJornadaForSquad: idJornadaForSquad,
        ),
      ),
    );
  }

  static Future<void> openParticipantLineupHistory({
    required BuildContext context,
    required int idLiga,
    required int idLigaParticipante,
    required int idUsuarioSolicitante,
    int? idUsuarioParticipante,
    String? nickname,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ParticipantLineupHistoryScreen(
          idLiga: idLiga,
          idLigaParticipante: idLigaParticipante,
          idUsuarioSolicitante: idUsuarioSolicitante,
          idUsuarioParticipante: idUsuarioParticipante,
          nickname: nickname,
        ),
      ),
    );
  }

  static Future<void> openParticipantLineupRoundDetail({
    required BuildContext context,
    required int idLiga,
    required int idLigaParticipante,
    required int idUsuarioSolicitante,
    required int idJornada,
    int? idUsuarioParticipante,
    String? nickname,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ParticipantLineupRoundDetailScreen(
          idLiga: idLiga,
          idLigaParticipante: idLigaParticipante,
          idUsuarioSolicitante: idUsuarioSolicitante,
          idJornada: idJornada,
          idUsuarioParticipante: idUsuarioParticipante,
          nickname: nickname,
        ),
      ),
    );
  }

  /// Plantilla de catálogo enriquecida (equipo + entrenador + jugadores).
  static Future<void> openCatalogTeamSquad({
    required BuildContext context,
    required int idEquipo,
    String? nombreEquipo,
    String? fotoEquipo,
    int? seasonId,
    int? idLiga,
    int? idUsuario,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CatalogTeamPlayersScreen(
          idEquipo: idEquipo,
          nombreEquipo: nombreEquipo,
          fotoEquipo: fotoEquipo,
          seasonId: seasonId,
          idLiga: idLiga,
          idUsuario: idUsuario,
        ),
      ),
    );
  }

  /// Alias de [openCatalogTeamSquad] para llamadas existentes.
  static Future<void> openCatalogTeamPlayers({
    required BuildContext context,
    required int idEquipo,
    String? nombreEquipo,
    String? fotoEquipo,
    int? seasonId,
    int? idLiga,
    int? idUsuario,
  }) {
    return openCatalogTeamSquad(
      context: context,
      idEquipo: idEquipo,
      nombreEquipo: nombreEquipo,
      fotoEquipo: fotoEquipo,
      seasonId: seasonId,
      idLiga: idLiga,
      idUsuario: idUsuario,
    );
  }
}

import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_player.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';

/// Error al construir plantilla rival desde datos locales.
class ClashRivalSquadBuildException implements Exception {
  ClashRivalSquadBuildException(this.message);

  final String message;

  @override
  String toString() => 'ClashRivalSquadBuildException: $message';
}

/// Adapta equipos rivales locales al modelo de partido 7v7.
class ClashRivalSquadBuilder {
  const ClashRivalSquadBuilder._();

  static List<MatchSquadPlayer> buildSquad(ClashRivalTeam team) {
    if (!team.hasCompleteLineup) {
      throw ClashRivalSquadBuildException(
        'El equipo rival ${team.id} no tiene alineación 7v7 completa',
      );
    }

    final byPosition = {
      for (final player in team.lineup7v7) player.position: player,
    };
    final players = <MatchSquadPlayer>[];

    for (var i = 0; i < ClashPosition.values.length; i++) {
      final position = ClashPosition.values[i];
      final rival = byPosition[position];
      if (rival == null) {
        throw ClashRivalSquadBuildException(
          'Falta posición ${position.name} en ${team.id}',
        );
      }
      players.add(_mapPlayer(rival, i));
    }

    return players;
  }

  static List<MatchSquadPlayer> buildSquadOrFallback({
    ClashRivalTeam? team,
    int basePower = 120,
  }) {
    if (team == null) {
      return MatchSquadBuilder.buildRivalSquad(basePower: basePower);
    }
    try {
      return buildSquad(team);
    } on ClashRivalSquadBuildException {
      return MatchSquadBuilder.buildRivalSquad(
        basePower: team.recommendedPower,
      );
    }
  }

  static MatchSquadPlayer _mapPlayer(ClashRivalPlayer rival, int index) {
    final (x, y) = MatchPitchLayout.coordsForIndex(index, MatchTeamSide.rival);
    final stats = rival.effectiveStats;
    return MatchSquadPlayer(
      index: index,
      side: MatchTeamSide.rival,
      cardId: rival.id,
      playerId: rival.playerId ?? 92000 + index,
      position: rival.position,
      label: _shortLabel(rival.name),
      homeX: x,
      homeY: y,
      baseStats: stats,
      power: stats.power,
      currentStamina: stats.stamina,
      style: rival.style,
      superTechniques: rival.superTechniques,
      maxPt: stats.techniquePoints,
      currentPt: stats.techniquePoints,
    );
  }

  static String _shortLabel(String name) {
    if (name.length <= 8) {
      return name;
    }
    return name.split(' ').first;
  }
}

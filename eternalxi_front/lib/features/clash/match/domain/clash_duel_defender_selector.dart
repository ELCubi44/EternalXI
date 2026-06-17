import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Selección provisional del defensor rival al avanzar (Fase 9).
class ClashDuelDefenderSelector {
  const ClashDuelDefenderSelector._();

  static const _midfieldPriority = [
    ClashPosition.defensiveMidfielder,
    ClashPosition.attackingMidfielder,
    ClashPosition.centreBack,
    ClashPosition.fullBack,
  ];

  static const _areaPriority = [
    ClashPosition.centreBack,
    ClashPosition.fullBack,
    ClashPosition.defensiveMidfielder,
  ];

  /// Devuelve un defensor rival cercano o `null` para avance libre.
  static MatchSquadPlayer? selectForAdvance(
    MatchState state,
    MatchSquadPlayer attacker,
  ) {
    if (state.possession != attacker.side) {
      return null;
    }

    final zone = state.ballZone;
    if (zone == MatchBallZone.ownDefense || zone == MatchBallZone.ownMidfield) {
      return null;
    }

    final priority = switch (zone) {
      MatchBallZone.midfield ||
      MatchBallZone.rivalMidfield => _midfieldPriority,
      MatchBallZone.rivalArea => _areaPriority,
      _ => _midfieldPriority,
    };

    for (final position in priority) {
      final defender = _firstRivalAtPosition(state, position);
      if (defender != null) {
        return defender;
      }
    }

    return _closestRivalDefender(state, attacker);
  }

  static MatchSquadPlayer? _firstRivalAtPosition(
    MatchState state,
    ClashPosition position,
  ) {
    for (final player in state.rivalSquad) {
      if (player.position == position) {
        return player;
      }
    }
    return null;
  }

  static MatchSquadPlayer? _closestRivalDefender(
    MatchState state,
    MatchSquadPlayer attacker,
  ) {
    const defensivePositions = {
      ClashPosition.goalkeeper,
      ClashPosition.centreBack,
      ClashPosition.fullBack,
      ClashPosition.defensiveMidfielder,
    };

    MatchSquadPlayer? best;
    var bestDistance = 999;
    for (final player in state.rivalSquad) {
      if (!defensivePositions.contains(player.position)) {
        continue;
      }
      final distance = (player.index - attacker.index).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = player;
      }
    }
    return best;
  }

  /// Portero del equipo que defiende el tiro.
  static MatchSquadPlayer? selectGoalkeeper(
    MatchState state,
    MatchTeamSide attackingSide,
  ) {
    final defendingSide = attackingSide.opposite();
    final squad = state.squadFor(defendingSide);
    for (final player in squad) {
      if (player.position == ClashPosition.goalkeeper) {
        return player;
      }
    }
    return squad.isNotEmpty ? squad.first : null;
  }

  static ClashDuelStyleResult attackerStyleResult(
    ClashPlayerStyle attacker,
    ClashPlayerStyle defender,
  ) {
    return switch (compareClashStyles(attacker, defender)) {
      ClashStyleMatchup.advantage => ClashDuelStyleResult.advantage,
      ClashStyleMatchup.disadvantage => ClashDuelStyleResult.disadvantage,
      ClashStyleMatchup.neutral => ClashDuelStyleResult.neutral,
    };
  }
}

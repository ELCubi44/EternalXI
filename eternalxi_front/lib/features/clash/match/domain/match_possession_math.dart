import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Fórmulas provisionales de pase y avance (Fase 8).
class MatchPossessionMath {
  const MatchPossessionMath._();

  static const int minPercent = 5;
  static const int maxPercent = 95;

  static int clampPercent(double value) =>
      value.round().clamp(minPercent, maxPercent);

  static int logicalDistance(int fromIndex, int toIndex) {
    return (fromIndex - toIndex).abs();
  }

  static bool isDefenseToStriker(ClashPosition from, ClashPosition to) {
    final defense = {
      ClashPosition.goalkeeper,
      ClashPosition.centreBack,
      ClashPosition.fullBack,
      ClashPosition.defensiveMidfielder,
    };
    return defense.contains(from) && to == ClashPosition.striker;
  }

  static int rivalDefenseQuality(MatchState state) {
    final squad = state.rivalSquad;
    if (squad.isEmpty) {
      return 50;
    }
    final total = squad.fold<int>(0, (sum, p) => sum + p.effectiveDefense);
    return (total / squad.length).round();
  }

  static int passSuccessPercent({
    required MatchSquadPlayer passer,
    required MatchSquadPlayer receiver,
    required MatchBallZone ballZone,
    required int pressure,
    required int rivalDefenseQuality,
  }) {
    final distance = logicalDistance(passer.index, receiver.index);
    var value = 52.0;
    value += passer.effectivePass * 0.32;
    value += receiver.power * 0.08;
    value -= distance * 7.5;
    value -= pressure * 0.22;
    value -= rivalDefenseQuality * 0.12;
    value -= ballZone.order * 2.5;

    if (distance <= 1) {
      value += 12;
    } else if (distance == 2) {
      value += 2;
    } else if (distance >= 4) {
      value -= 10;
    }

    if (isDefenseToStriker(passer.position, receiver.position)) {
      value -= 28;
      if (passer.power + receiver.power < rivalDefenseQuality * 2) {
        value -= 12;
      }
    }

    return clampPercent(value);
  }

  static int advanceSuccessPercent({
    required MatchSquadPlayer carrier,
    required MatchBallZone ballZone,
    required int pressure,
    required int rivalDefenseQuality,
  }) {
    var value = 42.0;
    value += carrier.effectiveDribble * 0.38;
    value -= pressure * 0.28;
    value -= rivalDefenseQuality * 0.18;
    value -= ballZone.order * 6.5;

    if (ballZone == MatchBallZone.rivalArea) {
      value -= 18;
    } else if (ballZone == MatchBallZone.rivalMidfield) {
      value -= 8;
    }

    return clampPercent(value);
  }

  static int adjustPressureAfterPass({
    required bool success,
    required int currentPressure,
    required int passRisk,
  }) {
    if (success) {
      return (currentPressure - 8 + passRisk ~/ 10).clamp(0, 100);
    }
    return (currentPressure + 6).clamp(0, 100);
  }

  static int adjustPressureAfterAdvance({
    required bool success,
    required int currentPressure,
  }) {
    if (success) {
      return (currentPressure + 10).clamp(0, 100);
    }
    return (currentPressure + 4).clamp(0, 100);
  }

  static int possessionRiskForPass(int passPercent) =>
      (100 - passPercent).clamp(0, 100);

  static MatchSquadPlayer? pickRivalInZone(
    MatchState state,
    MatchBallZone zone,
  ) {
    final candidates = state.rivalSquad
        .where((player) => player.homeZone == zone)
        .toList();
    if (candidates.isNotEmpty) {
      return candidates.first;
    }
    return state.rivalSquad.isNotEmpty ? state.rivalSquad[3] : null;
  }

  static MatchSquadPlayer? pickUserInZone(
    MatchState state,
    MatchBallZone zone,
  ) {
    final candidates = state.userSquad
        .where((player) => player.homeZone == zone)
        .toList();
    if (candidates.isNotEmpty) {
      return candidates.first;
    }
    return state.userSquad.isNotEmpty ? state.userSquad[3] : null;
  }

  static MatchTeamSide opposite(MatchTeamSide side) => side.opposite();
}

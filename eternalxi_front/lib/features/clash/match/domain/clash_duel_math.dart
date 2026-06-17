import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Fórmulas de duelos Clash (Fase 9–11).
class ClashDuelMath {
  const ClashDuelMath._();

  static const int styleAdvantageBonus = 8;
  static const int shotAreaBonus = 4;

  static int attackerZoneBonus(MatchBallZone zone) => switch (zone) {
    MatchBallZone.rivalArea => 4,
    MatchBallZone.rivalMidfield => 2,
    MatchBallZone.midfield => 1,
    _ => 0,
  };

  static int defenderPressureBonus(int pressure) =>
      (pressure * 0.08).round().clamp(-2, 10);

  static int styleBonusFor(ClashDuelStyleResult result) {
    if (result == ClashDuelStyleResult.advantage) {
      return styleAdvantageBonus;
    }
    return 0;
  }

  static int computeScore({
    required int effectiveStat,
    required ClashPlayerStyle actorStyle,
    required ClashPlayerStyle opponentStyle,
    ClashSuperTechnique? technique,
    int zoneBonus = 0,
    int pressureBonus = 0,
    int variance = 0,
  }) {
    final actingStyle = technique?.style ?? actorStyle;
    final styleResult = ClashDuelDefenderSelector.attackerStyleResult(
      actingStyle,
      opponentStyle,
    );
    var score = effectiveStat;
    if (technique != null) {
      score += technique.effectivePower;
    }
    score += styleBonusFor(styleResult);
    score += zoneBonus;
    score += pressureBonus;
    score += variance;
    return score;
  }

  static ClashDuelResolution resolveDribbleVsDefense({
    required ClashDuelParticipant attacker,
    required ClashDuelParticipant defender,
    required MatchBallZone ballZone,
    required int pressure,
    required MatchChanceResolver chance,
    ClashSuperTechnique? attackerTechnique,
    ClashSuperTechnique? defenderTechnique,
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final attackerActingStyle = attackerTechnique?.style ?? attacker.style;
    final defenderActingStyle = defenderTechnique?.style ?? defender.style;

    final attackerScore = computeScore(
      effectiveStat: attacker.effectiveStat,
      actorStyle: attacker.style,
      opponentStyle: defenderActingStyle,
      technique: attackerTechnique,
      zoneBonus: attackerZoneBonus(ballZone),
      variance: attackerVariance,
    );
    final defenderScore = computeScore(
      effectiveStat: defender.effectiveStat,
      actorStyle: defender.style,
      opponentStyle: attackerActingStyle,
      technique: defenderTechnique,
      pressureBonus: defenderPressureBonus(pressure),
      variance: defenderVariance,
    );

    return _finishResolution(
      duelType: ClashDuelType.dribbleVsDefense,
      attacker: attacker,
      defender: defender,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      chance: chance,
      attackerTechnique: attackerTechnique,
      defenderTechnique: defenderTechnique,
      dribbleDuel: true,
    );
  }

  static ClashDuelResolution resolveShotVsSave({
    required ClashDuelParticipant shooter,
    required ClashDuelParticipant goalkeeper,
    required MatchBallZone ballZone,
    required int pressure,
    required MatchChanceResolver chance,
    ClashSuperTechnique? shooterTechnique,
    ClashSuperTechnique? goalkeeperTechnique,
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final shooterActingStyle = shooterTechnique?.style ?? shooter.style;
    final keeperActingStyle = goalkeeperTechnique?.style ?? goalkeeper.style;

    final attackerScore = computeScore(
      effectiveStat: shooter.effectiveStat,
      actorStyle: shooter.style,
      opponentStyle: keeperActingStyle,
      technique: shooterTechnique,
      zoneBonus: shotAreaBonus,
      variance: attackerVariance,
    );
    final defenderScore = computeScore(
      effectiveStat: goalkeeper.effectiveStat,
      actorStyle: goalkeeper.style,
      opponentStyle: shooterActingStyle,
      technique: goalkeeperTechnique,
      pressureBonus: defenderPressureBonus(pressure),
      variance: defenderVariance,
    );

    return _finishResolution(
      duelType: ClashDuelType.shotVsSave,
      attacker: shooter,
      defender: goalkeeper,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      chance: chance,
      attackerTechnique: shooterTechnique,
      defenderTechnique: goalkeeperTechnique,
      dribbleDuel: false,
    );
  }

  static ClashDuelResolution _finishResolution({
    required ClashDuelType duelType,
    required ClashDuelParticipant attacker,
    required ClashDuelParticipant defender,
    required int attackerScore,
    required int defenderScore,
    required MatchChanceResolver chance,
    required ClashSuperTechnique? attackerTechnique,
    required ClashSuperTechnique? defenderTechnique,
    required bool dribbleDuel,
  }) {
    final winner = _resolveWinner(
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      attackerSide: attacker.teamSide,
      defenderSide: defender.teamSide,
      chance: chance,
    );
    final attackerWon = winner == attacker.teamSide;
    final eventText = _buildEventText(
      duelType: duelType,
      attacker: attacker,
      defender: defender,
      attackerWon: attackerWon,
      attackerTechnique: attackerTechnique,
      defenderTechnique: defenderTechnique,
    );

    return ClashDuelResolution(
      duelType: duelType,
      attackerSide: attacker.teamSide,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      winner: winner,
      styleBonusApplied: true,
      staminaPenaltyApplied: attacker.stamina < 100 || defender.stamina < 100,
      resolvedByCoin: attackerScore == defenderScore,
      eventText: eventText,
      attackerTechniqueName: attackerTechnique?.name,
      defenderTechniqueName: defenderTechnique?.name,
      attackerPtSpent: attackerTechnique?.ptCost ?? 0,
      defenderPtSpent: defenderTechnique?.ptCost ?? 0,
      attackerUsedNormal: attackerTechnique == null,
      defenderUsedNormal: defenderTechnique == null,
    );
  }

  static String _buildEventText({
    required ClashDuelType duelType,
    required ClashDuelParticipant attacker,
    required ClashDuelParticipant defender,
    required bool attackerWon,
    required ClashSuperTechnique? attackerTechnique,
    required ClashSuperTechnique? defenderTechnique,
  }) {
    if (duelType == ClashDuelType.shotVsSave) {
      if (attackerWon) {
        if (attackerTechnique != null) {
          return '${attacker.label} marca con ${attackerTechnique.name}';
        }
        return '${attacker.label} marca ante ${defender.label}';
      }
      if (defenderTechnique != null) {
        return '${defender.label} detiene ${attackerTechnique?.name ?? 'el tiro de ${attacker.label}'}';
      }
      return '${defender.label} detiene el tiro de ${attacker.label}';
    }

    if (attackerWon) {
      if (attackerTechnique != null) {
        return '${attacker.label} supera a ${defender.label} con ${attackerTechnique.name}';
      }
      return '${attacker.label} supera a ${defender.label}';
    }
    if (defenderTechnique != null) {
      return '${defender.label} frena a ${attacker.label} con ${defenderTechnique.name}';
    }
    return '${defender.label} frena a ${attacker.label}';
  }

  static MatchTeamSide _resolveWinner({
    required int attackerScore,
    required int defenderScore,
    required MatchTeamSide attackerSide,
    required MatchTeamSide defenderSide,
    required MatchChanceResolver chance,
  }) {
    if (attackerScore > defenderScore) {
      return attackerSide;
    }
    if (defenderScore > attackerScore) {
      return defenderSide;
    }
    return chance.coinFlipFavorsUser()
        ? MatchTeamSide.user
        : MatchTeamSide.rival;
  }
}

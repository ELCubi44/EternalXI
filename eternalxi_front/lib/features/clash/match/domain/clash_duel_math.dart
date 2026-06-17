import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Fórmulas de duelos Clash (Fase 9–10).
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

  static ClashDuelResolution resolveDribbleVsDefense({
    required ClashDuelParticipant attacker,
    required ClashDuelParticipant defender,
    required ClashDuelStyleResult attackerStyleResult,
    required MatchBallZone ballZone,
    required int pressure,
    required MatchChanceResolver chance,
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final attackerStyleBonus = styleBonusFor(attackerStyleResult);
    final defenderStyleResult = _defenderStyleResult(attackerStyleResult);
    final defenderStyleBonus = styleBonusFor(defenderStyleResult);

    var attackerScore = attacker.effectiveStat;
    attackerScore += attackerStyleBonus;
    attackerScore += attackerZoneBonus(ballZone);
    attackerScore += attackerVariance;

    var defenderScore = defender.effectiveStat;
    defenderScore += defenderStyleBonus;
    defenderScore += defenderPressureBonus(pressure);
    defenderScore += defenderVariance;

    final winner = _resolveWinner(
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      attackerSide: attacker.teamSide,
      defenderSide: defender.teamSide,
      chance: chance,
    );

    final attackerWon = winner == attacker.teamSide;
    final eventText = attackerWon
        ? '${attacker.label} supera a ${defender.label}'
        : '${defender.label} frena a ${attacker.label}';

    return _buildResolution(
      duelType: ClashDuelType.dribbleVsDefense,
      attackerSide: attacker.teamSide,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      winner: winner,
      attackerStyleBonus: attackerStyleBonus,
      defenderStyleBonus: defenderStyleBonus,
      attacker: attacker,
      defender: defender,
      eventText: eventText,
      chance: chance,
    );
  }

  static ClashDuelResolution resolveShotVsSave({
    required ClashDuelParticipant shooter,
    required ClashDuelParticipant goalkeeper,
    required ClashDuelStyleResult attackerStyleResult,
    required MatchBallZone ballZone,
    required int pressure,
    required MatchChanceResolver chance,
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final shooterStyleBonus = styleBonusFor(attackerStyleResult);
    final keeperStyleResult = _defenderStyleResult(attackerStyleResult);
    final keeperStyleBonus = styleBonusFor(keeperStyleResult);

    var attackerScore = shooter.effectiveStat;
    attackerScore += shooterStyleBonus;
    attackerScore += shotAreaBonus;
    attackerScore += attackerVariance;

    var defenderScore = goalkeeper.effectiveStat;
    defenderScore += keeperStyleBonus;
    defenderScore += defenderPressureBonus(pressure);
    defenderScore += defenderVariance;

    final winner = _resolveWinner(
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      attackerSide: shooter.teamSide,
      defenderSide: goalkeeper.teamSide,
      chance: chance,
    );

    final attackerWon = winner == shooter.teamSide;
    final eventText = attackerWon
        ? '${shooter.label} marca ante ${goalkeeper.label}'
        : '${goalkeeper.label} detiene el tiro de ${shooter.label}';

    return _buildResolution(
      duelType: ClashDuelType.shotVsSave,
      attackerSide: shooter.teamSide,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      winner: winner,
      attackerStyleBonus: shooterStyleBonus,
      defenderStyleBonus: keeperStyleBonus,
      attacker: shooter,
      defender: goalkeeper,
      eventText: eventText,
      chance: chance,
    );
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

  static ClashDuelResolution _buildResolution({
    required ClashDuelType duelType,
    required MatchTeamSide attackerSide,
    required int attackerScore,
    required int defenderScore,
    required MatchTeamSide winner,
    required int attackerStyleBonus,
    required int defenderStyleBonus,
    required ClashDuelParticipant attacker,
    required ClashDuelParticipant defender,
    required String eventText,
    required MatchChanceResolver chance,
  }) {
    final staminaPenaltyApplied =
        attacker.stamina < 100 || defender.stamina < 100;
    final styleBonusApplied = attackerStyleBonus > 0 || defenderStyleBonus > 0;
    final resolvedByCoin = attackerScore == defenderScore;

    return ClashDuelResolution(
      duelType: duelType,
      attackerSide: attackerSide,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      winner: winner,
      styleBonusApplied: styleBonusApplied,
      staminaPenaltyApplied: staminaPenaltyApplied,
      resolvedByCoin: resolvedByCoin,
      eventText: eventText,
    );
  }

  static ClashDuelStyleResult _defenderStyleResult(
    ClashDuelStyleResult attackerResult,
  ) {
    return switch (attackerResult) {
      ClashDuelStyleResult.advantage => ClashDuelStyleResult.disadvantage,
      ClashDuelStyleResult.disadvantage => ClashDuelStyleResult.advantage,
      ClashDuelStyleResult.neutral => ClashDuelStyleResult.neutral,
    };
  }
}

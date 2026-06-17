import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Fórmulas de duelo Regate vs Defensa (Fase 9).
class ClashDuelMath {
  const ClashDuelMath._();

  static const int styleAdvantageBonus = 8;
  static const int styleBonusPercent = 10;

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

    final staminaPenaltyApplied =
        attacker.stamina < 100 || defender.stamina < 100;
    final styleBonusApplied = attackerStyleBonus > 0 || defenderStyleBonus > 0;

    var resolvedByCoin = false;
    late MatchTeamSide winner;
    if (attackerScore > defenderScore) {
      winner = attacker.teamSide;
    } else if (defenderScore > attackerScore) {
      winner = defender.teamSide;
    } else {
      resolvedByCoin = true;
      winner = chance.coinFlipFavorsUser()
          ? MatchTeamSide.user
          : MatchTeamSide.rival;
    }

    final attackerWon = winner == attacker.teamSide;
    final eventText = attackerWon
        ? '${attacker.label} supera a ${defender.label}'
        : '${defender.label} frena a ${attacker.label}';

    return ClashDuelResolution(
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

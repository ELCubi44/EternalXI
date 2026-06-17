import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';

/// Selección provisional de supertécnica rival (Fase 11).
class ClashRivalTechniqueSelector {
  const ClashRivalTechniqueSelector._();

  static ClashDuelActionChoice selectAttacker({
    required MatchSquadPlayer player,
    required ClashDuelType duelType,
    required int effectiveBaseStat,
    required ClashPlayerStyle opponentStyle,
    required MatchBallZone ballZone,
  }) {
    final zoneBonus = duelType == ClashDuelType.shotVsSave
        ? ClashDuelMath.shotAreaBonus
        : ClashDuelMath.attackerZoneBonus(ballZone);
    return _select(
      player: player,
      requiredType: ClashDuelTechniqueRules.attackerTechniqueType(duelType),
      effectiveBaseStat: effectiveBaseStat,
      opponentStyle: opponentStyle,
      pressureBonus: 0,
      zoneBonus: zoneBonus,
    );
  }

  static ClashDuelActionChoice selectDefender({
    required MatchSquadPlayer player,
    required ClashDuelType duelType,
    required int effectiveBaseStat,
    required ClashPlayerStyle opponentStyle,
    required int pressure,
  }) {
    return _select(
      player: player,
      requiredType: ClashDuelTechniqueRules.defenderTechniqueType(duelType),
      effectiveBaseStat: effectiveBaseStat,
      opponentStyle: opponentStyle,
      pressureBonus: ClashDuelMath.defenderPressureBonus(pressure),
      zoneBonus: 0,
    );
  }

  static ClashDuelActionChoice _select({
    required MatchSquadPlayer player,
    required ClashTechniqueType requiredType,
    required int effectiveBaseStat,
    required ClashPlayerStyle opponentStyle,
    required int pressureBonus,
    required int zoneBonus,
  }) {
    final affordable = player.superTechniques
        .where(
          (technique) =>
              technique.type == requiredType &&
              player.currentPt >= technique.ptCost,
        )
        .toList();
    if (affordable.isEmpty) {
      return const ClashDuelActionChoice.normal();
    }

    affordable.sort((a, b) => b.effectivePower.compareTo(a.effectivePower));
    final best = affordable.first;

    final normalStyle = ClashDuelDefenderSelector.attackerStyleResult(
      player.style,
      opponentStyle,
    );
    final normalScore =
        effectiveBaseStat +
        ClashDuelMath.styleBonusFor(normalStyle) +
        pressureBonus +
        zoneBonus;

    final techniqueStyle = ClashDuelDefenderSelector.attackerStyleResult(
      best.style,
      opponentStyle,
    );
    final techniqueScore =
        effectiveBaseStat +
        best.effectivePower +
        ClashDuelMath.styleBonusFor(techniqueStyle) +
        pressureBonus +
        zoneBonus;

    if (techniqueScore > normalScore) {
      return ClashDuelActionChoice.technique(best.id);
    }
    return const ClashDuelActionChoice.normal();
  }

  static ClashSuperTechnique? bestAffordable(
    MatchSquadPlayer player,
    ClashTechniqueType requiredType,
  ) {
    ClashSuperTechnique? best;
    for (final technique in player.superTechniques) {
      if (technique.type != requiredType) {
        continue;
      }
      if (player.currentPt < technique.ptCost) {
        continue;
      }
      if (best == null || technique.effectivePower > best.effectivePower) {
        best = technique;
      }
    }
    return best;
  }
}

import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Resultado numérico de un duelo Clash.
class ClashDuelResolution {
  const ClashDuelResolution({
    required this.duelType,
    required this.attackerSide,
    required this.attackerScore,
    required this.defenderScore,
    required this.winner,
    required this.styleBonusApplied,
    required this.staminaPenaltyApplied,
    required this.resolvedByCoin,
    required this.eventText,
    this.attackerTechniqueName,
    this.defenderTechniqueName,
    this.attackerPtSpent = 0,
    this.defenderPtSpent = 0,
    this.attackerUsedNormal = true,
    this.defenderUsedNormal = true,
  });

  final ClashDuelType duelType;
  final MatchTeamSide attackerSide;
  final int attackerScore;
  final int defenderScore;
  final MatchTeamSide winner;
  final bool styleBonusApplied;
  final bool staminaPenaltyApplied;
  final bool resolvedByCoin;
  final String eventText;
  final String? attackerTechniqueName;
  final String? defenderTechniqueName;
  final int attackerPtSpent;
  final int defenderPtSpent;
  final bool attackerUsedNormal;
  final bool defenderUsedNormal;

  bool get attackerWon => winner == attackerSide;

  bool get isGoal => duelType == ClashDuelType.shotVsSave && attackerWon;

  bool get isSave => duelType == ClashDuelType.shotVsSave && !attackerWon;
}

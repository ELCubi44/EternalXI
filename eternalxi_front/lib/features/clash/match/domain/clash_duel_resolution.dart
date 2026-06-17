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

  bool get attackerWon => winner == attackerSide;

  bool get isGoal => duelType == ClashDuelType.shotVsSave && attackerWon;

  bool get isSave => duelType == ClashDuelType.shotVsSave && !attackerWon;
}

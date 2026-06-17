import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Resultado numérico de un duelo Regate vs Defensa.
class ClashDuelResolution {
  const ClashDuelResolution({
    required this.attackerScore,
    required this.defenderScore,
    required this.winner,
    required this.styleBonusApplied,
    required this.staminaPenaltyApplied,
    required this.resolvedByCoin,
    required this.eventText,
  });

  final int attackerScore;
  final int defenderScore;
  final MatchTeamSide winner;
  final bool styleBonusApplied;
  final bool staminaPenaltyApplied;
  final bool resolvedByCoin;
  final String eventText;

  bool get attackerWon => winner == MatchTeamSide.user;
}

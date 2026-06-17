import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Reglas puras del shell de partido Clash (Fase 7).
class MatchRules {
  const MatchRules._();

  /// Tras un gol, la posesión pasa al equipo que lo recibió (encajó).
  static MatchTeamSide possessionAfterGoal(MatchTeamSide scorer) =>
      scorer.opposite();

  static MatchState applyGoal(MatchState state, MatchTeamSide scorer) {
    final nextScore = state.score.increment(scorer);
    if (nextScore.hasWinner()) {
      return state.copyWith(score: nextScore, status: MatchStatus.finished);
    }

    final nextPossession = possessionAfterGoal(scorer);
    return state.copyWith(
      score: nextScore,
      possession: nextPossession,
      ballHolderIndex: 3,
    );
  }
}

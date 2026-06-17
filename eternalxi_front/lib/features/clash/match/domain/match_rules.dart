import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
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
      ballZone: MatchBallZone.ownMidfield,
      pressure: 22,
      possessionRisk: 18,
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: MatchEventType.goal,
          message: scorer == MatchTeamSide.user
              ? 'Gol de Eternal XI'
              : 'Gol del rival',
        ),
        const MatchEvent(
          type: MatchEventType.kickoff,
          message: 'Saque tras gol',
        ),
      ],
    );
  }
}

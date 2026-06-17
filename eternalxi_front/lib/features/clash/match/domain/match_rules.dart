import 'package:eternal_xi/features/clash/match/domain/clash_halftime_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_goal_details.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Reglas puras del shell de partido Clash (Fase 7).
class MatchRules {
  const MatchRules._();

  /// Tras un gol, la posesión pasa al equipo que lo recibió (encajó).
  static MatchTeamSide possessionAfterGoal(MatchTeamSide scorer) =>
      scorer.opposite();

  static MatchState applyGoal(
    MatchState state,
    MatchTeamSide scorer, {
    String? goalMessage,
    MatchGoalDetails? goalDetails,
  }) {
    final nextScore = state.score.increment(scorer);
    final goalEvent = MatchEvent(
      type: MatchEventType.goal,
      message:
          goalMessage ??
          (scorer == MatchTeamSide.user
              ? 'Gol de Eternal XI'
              : 'Gol del rival'),
      goalDetails:
          goalDetails ?? MatchGoalDetails(scorer: scorer, usedTechnique: false),
    );

    if (nextScore.hasWinner()) {
      return state.copyWith(
        score: nextScore,
        status: MatchStatus.finished,
        eventLog: [...state.eventLog, goalEvent],
      );
    }

    final nextPossession = possessionAfterGoal(scorer);
    final kickoffZone = nextPossession == MatchTeamSide.user
        ? MatchBallZone.ownMidfield
        : MatchBallZone.rivalMidfield;

    final afterKickoff = state.copyWith(
      score: nextScore,
      possession: nextPossession,
      ballHolderIndex: 3,
      ballZone: kickoffZone,
      pressure: 22,
      possessionRisk: 18,
      eventLog: [...state.eventLog, goalEvent],
    );

    if (!ClashHalftimeRules.shouldTriggerHalftime(state, nextScore)) {
      return afterKickoff.copyWith(
        eventLog: [
          ...afterKickoff.eventLog,
          const MatchEvent(
            type: MatchEventType.kickoff,
            message: 'Saque tras gol',
          ),
        ],
      );
    }

    return afterKickoff.copyWith(
      status: MatchStatus.halftime,
      isHalftime: true,
      hasHalftimeOccurred: true,
      halftimeTriggeredAtScore: nextScore,
      eventLog: [
        ...afterKickoff.eventLog,
        const MatchEvent(
          type: MatchEventType.halftimeStarted,
          message: 'Descanso',
        ),
      ],
    );
  }
}

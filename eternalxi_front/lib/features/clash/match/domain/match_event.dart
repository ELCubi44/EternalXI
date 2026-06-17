import 'package:eternal_xi/features/clash/match/domain/match_goal_details.dart';

/// Evento breve del historial de partido.
enum MatchEventType {
  kickoff,
  passSuccess,
  passFail,
  advanceSuccess,
  advanceFail,
  duelStarted,
  duelSuccess,
  duelFail,
  duelTechniqueUsed,
  shotDuelStarted,
  saveMade,
  possessionLost,
  rivalAction,
  goal,
  halftimeStarted,
  halftimeEnded,
  halftimeItemUsed,
}

class MatchEvent {
  const MatchEvent({
    required this.type,
    required this.message,
    this.goalDetails,
  });

  final MatchEventType type;
  final String message;
  final MatchGoalDetails? goalDetails;
}

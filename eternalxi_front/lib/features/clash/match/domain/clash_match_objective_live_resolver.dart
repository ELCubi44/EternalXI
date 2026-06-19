import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_live_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Deriva estado live de objetivos sin cambiar reglas de evaluación final.
class ClashMatchObjectiveLiveResolver {
  const ClashMatchObjectiveLiveResolver._();

  static ClashMatchObjectiveLiveStatus resolve({
    required ClashMatchObjective objective,
    required MatchState state,
  }) {
    return switch (objective.type) {
      ClashMatchObjectiveType.winMatch => _winMatchStatus(state),
      ClashMatchObjectiveType.cleanSheet => _cleanSheetStatus(state),
      ClashMatchObjectiveType.scoreWithShotTechnique =>
        _scoreWithShotTechniqueStatus(state),
      _ => ClashMatchObjectiveLiveStatus.reviewedAtEnd,
    };
  }

  static bool supportsLiveTracking(ClashMatchObjectiveType type) {
    return switch (type) {
      ClashMatchObjectiveType.winMatch ||
      ClashMatchObjectiveType.cleanSheet ||
      ClashMatchObjectiveType.scoreWithShotTechnique => true,
      _ => false,
    };
  }

  static ClashMatchObjectiveLiveStatus _winMatchStatus(MatchState state) {
    if (!state.isFinished) {
      return ClashMatchObjectiveLiveStatus.pending;
    }
    return state.winner == MatchTeamSide.user
        ? ClashMatchObjectiveLiveStatus.completed
        : ClashMatchObjectiveLiveStatus.failed;
  }

  static ClashMatchObjectiveLiveStatus _cleanSheetStatus(MatchState state) {
    if (state.score.rival > 0) {
      return ClashMatchObjectiveLiveStatus.failed;
    }
    if (state.isFinished) {
      return state.winner == MatchTeamSide.user
          ? ClashMatchObjectiveLiveStatus.completed
          : ClashMatchObjectiveLiveStatus.failed;
    }
    return ClashMatchObjectiveLiveStatus.inProgress;
  }

  static ClashMatchObjectiveLiveStatus _scoreWithShotTechniqueStatus(
    MatchState state,
  ) {
    if (_hasUserGoalWithTechnique(state, ClashTechniqueType.shot)) {
      return ClashMatchObjectiveLiveStatus.completed;
    }
    if (state.isFinished) {
      return ClashMatchObjectiveLiveStatus.failed;
    }
    return ClashMatchObjectiveLiveStatus.inProgress;
  }

  static bool _hasUserGoalWithTechnique(
    MatchState state,
    ClashTechniqueType techniqueType,
  ) {
    for (final event in state.eventLog) {
      if (event.type != MatchEventType.goal) {
        continue;
      }
      final details = event.goalDetails;
      if (details == null || details.scorer != MatchTeamSide.user) {
        continue;
      }
      if (details.techniqueType == techniqueType) {
        return true;
      }
    }
    return false;
  }
}

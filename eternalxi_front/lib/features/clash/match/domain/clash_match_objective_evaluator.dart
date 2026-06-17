import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Evalúa objetivos de un partido match (Fase 16).
class ClashMatchObjectiveEvaluator {
  const ClashMatchObjectiveEvaluator._();

  static String rewardKey(String levelId, String objectiveId) =>
      '$levelId:$objectiveId';

  static List<ClashMatchObjectiveProgress> evaluate({
    required List<ClashMatchObjective> objectives,
    required MatchState state,
    required bool userWon,
    ClashStoryProgress? progress,
  }) {
    return objectives
        .map(
          (objective) => _evaluateOne(
            objective: objective,
            state: state,
            userWon: userWon,
            progress: progress,
          ),
        )
        .toList(growable: false);
  }

  static ClashMatchObjectiveProgress _evaluateOne({
    required ClashMatchObjective objective,
    required MatchState state,
    required bool userWon,
    ClashStoryProgress? progress,
  }) {
    final completed = userWon && _isCompleted(objective, state);
    final alreadyClaimed =
        progress?.isObjectiveRewardClaimed(state.levelId, objective.id) ??
        false;
    final rewardPending =
        completed && !objective.rewards.isEmpty && !alreadyClaimed;

    return ClashMatchObjectiveProgress(
      objective: objective,
      completed: completed,
      rewardClaimed: completed && alreadyClaimed,
      rewardPending: rewardPending,
      completedAtEventIndex: completed
          ? _completedEventIndex(objective, state)
          : null,
    );
  }

  static bool _isCompleted(ClashMatchObjective objective, MatchState state) {
    return switch (objective.type) {
      ClashMatchObjectiveType.winMatch => state.winner == MatchTeamSide.user,
      ClashMatchObjectiveType.cleanSheet =>
        state.winner == MatchTeamSide.user && state.score.rival == 0,
      ClashMatchObjectiveType.scoreWithShotTechnique =>
        _hasUserGoalWithTechnique(state, ClashTechniqueType.shot),
      _ => false,
    };
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
      if (details == null) {
        continue;
      }
      if (details.scorer != MatchTeamSide.user) {
        continue;
      }
      if (details.techniqueType == techniqueType) {
        return true;
      }
    }
    return false;
  }

  static int? _completedEventIndex(
    ClashMatchObjective objective,
    MatchState state,
  ) {
    if (objective.type == ClashMatchObjectiveType.scoreWithShotTechnique) {
      for (var i = 0; i < state.eventLog.length; i++) {
        final event = state.eventLog[i];
        if (event.type != MatchEventType.goal) {
          continue;
        }
        final details = event.goalDetails;
        if (details?.scorer == MatchTeamSide.user &&
            details?.techniqueType == ClashTechniqueType.shot) {
          return i;
        }
      }
    }
    return state.eventLog.isEmpty ? null : state.eventLog.length - 1;
  }

  static ClashStoryReward mergeRewards(Iterable<ClashStoryReward> rewards) {
    var gems = 0;
    var coins = 0;
    final items = <ClashStoryItemReward>[];
    final materials = <ClashStoryMaterialReward>[];
    final cardIds = <String>[];

    for (final reward in rewards) {
      gems += reward.gems;
      coins += reward.coins;
      items.addAll(reward.items);
      materials.addAll(reward.materials);
      cardIds.addAll(reward.cardIds);
    }

    return ClashStoryReward(
      gems: gems,
      coins: coins,
      items: items,
      materials: materials,
      cardIds: cardIds,
    );
  }

  static ClashStoryReward rewardsToGrant({
    required String levelId,
    required ClashStoryReward baseVictoryReward,
    required List<ClashMatchObjectiveProgress> objectiveResults,
    required bool grantBaseVictory,
    required ClashStoryProgress progress,
  }) {
    final parts = <ClashStoryReward>[];
    if (grantBaseVictory) {
      parts.add(baseVictoryReward);
    }

    for (final result in objectiveResults) {
      if (!result.completed || result.objective.rewards.isEmpty) {
        continue;
      }
      if (progress.isObjectiveRewardClaimed(levelId, result.objectiveId)) {
        continue;
      }
      parts.add(result.objective.rewards);
    }

    return mergeRewards(parts);
  }
}

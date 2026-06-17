import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Progreso de un objetivo al finalizar (o durante) un partido.
class ClashMatchObjectiveProgress {
  const ClashMatchObjectiveProgress({
    required this.objective,
    required this.completed,
    this.currentValue,
    this.targetValue,
    this.completedAtEventIndex,
    this.rewardClaimed = false,
    this.rewardPending = false,
  });

  final ClashMatchObjective objective;
  final bool completed;
  final int? currentValue;
  final int? targetValue;
  final int? completedAtEventIndex;
  final bool rewardClaimed;
  final bool rewardPending;

  String get objectiveId => objective.id;

  ClashStoryReward get rewards => objective.rewards;

  ClashMatchObjectiveProgress copyWith({
    bool? completed,
    int? currentValue,
    int? targetValue,
    int? completedAtEventIndex,
    bool? rewardClaimed,
    bool? rewardPending,
  }) {
    return ClashMatchObjectiveProgress(
      objective: objective,
      completed: completed ?? this.completed,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      completedAtEventIndex:
          completedAtEventIndex ?? this.completedAtEventIndex,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      rewardPending: rewardPending ?? this.rewardPending,
    );
  }
}

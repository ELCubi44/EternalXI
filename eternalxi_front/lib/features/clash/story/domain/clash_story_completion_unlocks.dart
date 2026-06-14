/// Desbloqueos narrativos al completar un nivel de historia.
class ClashStoryCompletionUnlocks {
  const ClashStoryCompletionUnlocks({
    this.clashTeamUnlocked = false,
    this.firstLineupUnlocked = false,
    this.nextPlayableLevelUnlocked = false,
  });

  final bool clashTeamUnlocked;
  final bool firstLineupUnlocked;
  final bool nextPlayableLevelUnlocked;

  factory ClashStoryCompletionUnlocks.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ClashStoryCompletionUnlocks();
    }
    return ClashStoryCompletionUnlocks(
      clashTeamUnlocked: json['clashTeamUnlocked'] == true,
      firstLineupUnlocked: json['firstLineupUnlocked'] == true,
      nextPlayableLevelUnlocked: json['nextPlayableLevelUnlocked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'clashTeamUnlocked': clashTeamUnlocked,
    'firstLineupUnlocked': firstLineupUnlocked,
    'nextPlayableLevelUnlocked': nextPlayableLevelUnlocked,
  };

  ClashStoryCompletionUnlocks merge(ClashStoryCompletionUnlocks other) {
    return ClashStoryCompletionUnlocks(
      clashTeamUnlocked: clashTeamUnlocked || other.clashTeamUnlocked,
      firstLineupUnlocked: firstLineupUnlocked || other.firstLineupUnlocked,
      nextPlayableLevelUnlocked:
          nextPlayableLevelUnlocked || other.nextPlayableLevelUnlocked,
    );
  }
}

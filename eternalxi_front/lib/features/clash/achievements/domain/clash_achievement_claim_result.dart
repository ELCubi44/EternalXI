import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';

enum ClashAchievementClaimError {
  achievementNotFound,
  notCompleted,
  alreadyClaimed,
  grantFailed,
}

class ClashAchievementClaimResult {
  const ClashAchievementClaimResult({
    required this.success,
    required this.achievementId,
    this.reward,
    this.error,
  });

  final bool success;
  final String achievementId;
  final ClashAchievementReward? reward;
  final ClashAchievementClaimError? error;

  factory ClashAchievementClaimResult.failure({
    required String achievementId,
    required ClashAchievementClaimError error,
  }) {
    return ClashAchievementClaimResult(
      success: false,
      achievementId: achievementId,
      error: error,
    );
  }
}

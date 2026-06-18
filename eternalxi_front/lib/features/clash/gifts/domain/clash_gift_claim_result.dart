import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';

enum ClashGiftClaimError { giftNotFound, alreadyClaimed, expired, grantFailed }

class ClashGiftClaimResult {
  const ClashGiftClaimResult({
    required this.success,
    required this.giftId,
    this.rewards,
    this.error,
  });

  final bool success;
  final String giftId;
  final ClashAchievementReward? rewards;
  final ClashGiftClaimError? error;

  factory ClashGiftClaimResult.failure({
    required String giftId,
    required ClashGiftClaimError error,
  }) {
    return ClashGiftClaimResult(success: false, giftId: giftId, error: error);
  }
}

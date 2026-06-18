import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';

enum ClashDailyMissionClaimError {
  missionNotFound,
  notCompleted,
  alreadyClaimed,
  grantFailed,
}

class ClashDailyMissionClaimResult {
  const ClashDailyMissionClaimResult({
    required this.success,
    required this.missionId,
    this.reward,
    this.error,
  });

  final bool success;
  final String missionId;
  final ClashDailyMissionReward? reward;
  final ClashDailyMissionClaimError? error;

  factory ClashDailyMissionClaimResult.failure({
    required String missionId,
    required ClashDailyMissionClaimError error,
  }) {
    return ClashDailyMissionClaimResult(
      success: false,
      missionId: missionId,
      error: error,
    );
  }
}

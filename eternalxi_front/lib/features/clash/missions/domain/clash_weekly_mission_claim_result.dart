import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';

enum ClashWeeklyMissionClaimError {
  missionNotFound,
  notCompleted,
  alreadyClaimed,
  grantFailed,
}

class ClashWeeklyMissionClaimResult {
  const ClashWeeklyMissionClaimResult({
    required this.success,
    required this.missionId,
    this.reward,
    this.error,
  });

  final bool success;
  final String missionId;
  final ClashWeeklyMissionReward? reward;
  final ClashWeeklyMissionClaimError? error;

  factory ClashWeeklyMissionClaimResult.failure({
    required String missionId,
    required ClashWeeklyMissionClaimError error,
  }) {
    return ClashWeeklyMissionClaimResult(
      success: false,
      missionId: missionId,
      error: error,
    );
  }
}

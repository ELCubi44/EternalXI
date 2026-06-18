import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';

/// Definición de misión diaria desde catálogo JSON (Fase 28).
class ClashDailyMission {
  const ClashDailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.reward,
  });

  final String id;
  final String title;
  final String description;
  final ClashDailyMissionType type;
  final int target;
  final ClashDailyMissionReward reward;

  factory ClashDailyMission.fromJson(Map<String, dynamic> json) {
    final type = ClashDailyMissionType.fromJson(json['type']);
    if (type == null) {
      throw FormatException('Tipo de misión desconocido: ${json['type']}');
    }
    final rewardRaw = json['reward'] as Map<String, dynamic>? ?? const {};
    return ClashDailyMission(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      type: type,
      target: clashRequireInt(json['target'], 'target'),
      reward: ClashDailyMissionReward.fromJson(rewardRaw),
    );
  }
}

/// Progreso de una misión en el día actual.
class ClashDailyMissionProgress {
  const ClashDailyMissionProgress({
    required this.mission,
    required this.current,
    required this.claimed,
  });

  final ClashDailyMission mission;
  final int current;
  final bool claimed;

  bool get isCompleted => current >= mission.target;
  bool get canClaim => isCompleted && !claimed;
}

/// Resumen agregado del día.
class ClashDailyMissionsSummary {
  const ClashDailyMissionsSummary({
    required this.totalMissions,
    required this.completedCount,
    required this.claimedCount,
    required this.claimableCount,
  });

  final int totalMissions;
  final int completedCount;
  final int claimedCount;
  final int claimableCount;
}

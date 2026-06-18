import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_type.dart';

/// Definición de misión semanal desde catálogo JSON (Fase 30).
class ClashWeeklyMission {
  const ClashWeeklyMission({
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
  final ClashWeeklyMissionType type;
  final int target;
  final ClashWeeklyMissionReward reward;

  factory ClashWeeklyMission.fromJson(Map<String, dynamic> json) {
    final type = ClashWeeklyMissionType.fromJson(json['type']);
    if (type == null) {
      throw FormatException(
        'Tipo de misión semanal desconocido: ${json['type']}',
      );
    }
    final rewardRaw = json['reward'] as Map<String, dynamic>? ?? const {};
    return ClashWeeklyMission(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      type: type,
      target: clashRequireInt(json['target'], 'target'),
      reward: ClashWeeklyMissionReward.fromJson(rewardRaw),
    );
  }
}

/// Progreso de una misión en la semana actual.
class ClashWeeklyMissionProgress {
  const ClashWeeklyMissionProgress({
    required this.mission,
    required this.current,
    required this.claimed,
  });

  final ClashWeeklyMission mission;
  final int current;
  final bool claimed;

  bool get isCompleted => current >= mission.target;
  bool get canClaim => isCompleted && !claimed;
}

/// Resumen agregado de la semana.
class ClashWeeklyMissionsSummary {
  const ClashWeeklyMissionsSummary({
    required this.totalMissions,
    required this.completedCount,
    required this.claimedCount,
    required this.claimableCount,
    required this.weekKey,
  });

  final int totalMissions;
  final int completedCount;
  final int claimedCount;
  final int claimableCount;
  final String weekKey;
}

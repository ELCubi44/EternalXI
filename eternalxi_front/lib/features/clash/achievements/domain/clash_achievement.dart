import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Definición de logro desde catálogo JSON (Fase 29).
class ClashAchievement {
  const ClashAchievement({
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
  final ClashAchievementType type;
  final int target;
  final ClashAchievementReward reward;

  factory ClashAchievement.fromJson(Map<String, dynamic> json) {
    final type = ClashAchievementType.fromJson(json['type']);
    if (type == null) {
      throw FormatException('Tipo de logro desconocido: ${json['type']}');
    }
    final rewardRaw = json['reward'] as Map<String, dynamic>? ?? const {};
    return ClashAchievement(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      type: type,
      target: clashRequireInt(json['target'], 'target'),
      reward: ClashAchievementReward.fromJson(rewardRaw),
    );
  }
}

/// Progreso de un logro permanente.
class ClashAchievementProgress {
  const ClashAchievementProgress({
    required this.achievement,
    required this.current,
    required this.claimed,
  });

  final ClashAchievement achievement;
  final int current;
  final bool claimed;

  bool get isCompleted => current >= achievement.target;
  bool get canClaim => isCompleted && !claimed;
}

/// Resumen agregado de logros.
class ClashAchievementsSummary {
  const ClashAchievementsSummary({
    required this.totalAchievements,
    required this.completedCount,
    required this.claimedCount,
    required this.claimableCount,
  });

  final int totalAchievements;
  final int completedCount;
  final int claimedCount;
  final int claimableCount;
}

/// Filtro de lista en UI.
enum ClashAchievementFilter { all, inProgress, completed, claimed }

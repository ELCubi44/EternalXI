import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';

class ClashCharacterEventStage {
  const ClashCharacterEventStage({
    required this.id,
    required this.title,
    required this.type,
    required this.firstClearRewards,
    required this.repeatRewards,
    this.storyText = '',
    this.recommendedPower,
    this.rivalTeamId,
    this.cardXpReward = 0,
  });

  final String id;
  final String title;
  final ClashCharacterEventStageType type;
  final String storyText;
  final int? recommendedPower;
  final String? rivalTeamId;
  final int cardXpReward;
  final ClashCharacterEventReward firstClearRewards;
  final ClashCharacterEventReward repeatRewards;

  factory ClashCharacterEventStage.fromJson(Map<String, dynamic> json) {
    return ClashCharacterEventStage(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      type: ClashCharacterEventStageType.fromJson(json['type']),
      storyText: json['storyText']?.toString() ?? '',
      recommendedPower: json['recommendedPower'] == null
          ? null
          : clashAsInt(json['recommendedPower']),
      rivalTeamId: clashOptionalString(json['rivalTeamId']),
      cardXpReward: clashAsInt(json['cardXpReward']),
      firstClearRewards: ClashCharacterEventReward.fromJson(
        Map<String, dynamic>.from(
          json['firstClearRewards'] as Map? ?? const {},
        ),
      ),
      repeatRewards: ClashCharacterEventReward.fromJson(
        Map<String, dynamic>.from(json['repeatRewards'] as Map? ?? const {}),
      ),
    );
  }
}

enum ClashCharacterEventStageStatus { locked, available, completed }

class ClashCharacterEventStageProgress {
  const ClashCharacterEventStageProgress({
    required this.stage,
    required this.status,
    required this.clearCount,
    required this.canPlay,
  });

  final ClashCharacterEventStage stage;
  final ClashCharacterEventStageStatus status;
  final int clearCount;
  final bool canPlay;
}

import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_status.dart';

class ClashCharacterEvent {
  const ClashCharacterEvent({
    required this.id,
    required this.title,
    required this.characterName,
    required this.description,
    required this.status,
    required this.stages,
    this.featuredCardId,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String characterName;
  final String description;
  final ClashCharacterEventAvailability status;
  final String? featuredCardId;
  final bool isPinned;
  final List<ClashCharacterEventStage> stages;

  factory ClashCharacterEvent.fromJson(Map<String, dynamic> json) {
    final stagesRaw = json['stages'] as List? ?? const [];
    return ClashCharacterEvent(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      characterName: clashRequireString(json['characterName'], 'characterName'),
      description: clashRequireString(json['description'], 'description'),
      status: ClashCharacterEventAvailability.fromJson(json['status']),
      featuredCardId: clashOptionalString(json['featuredCardId']),
      isPinned: json['isPinned'] == true,
      stages: stagesRaw
          .map(
            (item) => ClashCharacterEventStage.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ClashCharacterEventSummary {
  const ClashCharacterEventSummary({
    required this.event,
    required this.completedStages,
    required this.totalStages,
    required this.isAvailable,
  });

  final ClashCharacterEvent event;
  final int completedStages;
  final int totalStages;
  final bool isAvailable;
}

class ClashCharacterEventStageCompletionResult {
  const ClashCharacterEventStageCompletionResult({
    required this.eventId,
    required this.stageId,
    required this.firstClear,
    required this.rewardsGranted,
    this.newlyGrantedCardIds = const [],
    this.cardXpResults = const [],
  });

  final String eventId;
  final String stageId;
  final bool firstClear;
  final ClashCharacterEventReward rewardsGranted;
  final List<String> newlyGrantedCardIds;
  final List<ClashCardXpResult> cardXpResults;
}

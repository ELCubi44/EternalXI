import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_completion_unlocks.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_scene.dart';

/// Nivel jugable o narrativo dentro de un capítulo Clash.
class ClashStoryLevel {
  const ClashStoryLevel({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.order,
    required this.type,
    required this.energyCost,
    required this.rewards,
    required this.scenes,
    this.recommendedPower,
    this.requiredPlayers = const [],
    this.requiredPositions = const [],
    this.guestCards = const [],
    this.completionUnlocks = const ClashStoryCompletionUnlocks(),
  });

  final String id;
  final String chapterId;
  final String title;
  final String description;
  final int order;
  final ClashStoryLevelType type;
  final int energyCost;
  final int? recommendedPower;
  final ClashStoryReward rewards;
  final List<int> requiredPlayers;
  final List<ClashPosition> requiredPositions;
  final List<ClashStoryGuestCard> guestCards;
  final List<ClashStoryScene> scenes;
  final ClashStoryCompletionUnlocks completionUnlocks;

  factory ClashStoryLevel.fromJson(Map<String, dynamic> json) {
    final positionsRaw = json['requiredPositions'] as List? ?? const [];
    final playersRaw = json['requiredPlayers'] as List? ?? const [];
    final guestsRaw = json['guestCards'] as List? ?? const [];
    final scenesRaw = json['scenes'] as List? ?? const [];

    return ClashStoryLevel(
      id: clashRequireString(json['id'], 'id'),
      chapterId: clashRequireString(json['chapterId'], 'chapterId'),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      order: clashRequireInt(json['order'], 'order'),
      type: ClashStoryLevelType.fromJson(
        clashRequireString(json['type'], 'type'),
      ),
      energyCost: clashAsInt(json['energyCost'], fallback: 1),
      recommendedPower: json['recommendedPower'] == null
          ? null
          : clashAsInt(json['recommendedPower']),
      rewards: ClashStoryReward.fromJson(
        Map<String, dynamic>.from(json['rewards'] as Map? ?? const {}),
      ),
      requiredPlayers: playersRaw.map(clashAsInt).toList(growable: false),
      requiredPositions: positionsRaw
          .map((value) => ClashPosition.fromJson(value.toString()))
          .toList(growable: false),
      guestCards: guestsRaw
          .map(
            (item) => ClashStoryGuestCard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      scenes:
          scenesRaw
              .map(
                (item) => ClashStoryScene.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => a.order.compareTo(b.order)),
      completionUnlocks: ClashStoryCompletionUnlocks.fromJson(
        json['completionUnlocks'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'title': title,
    'description': description,
    'order': order,
    'type': type.toJson(),
    'energyCost': energyCost,
    if (recommendedPower != null) 'recommendedPower': recommendedPower,
    'rewards': rewards.toJson(),
    'requiredPlayers': requiredPlayers,
    'requiredPositions': requiredPositions
        .map((position) => position.toJson())
        .toList(),
    'guestCards': guestCards.map((card) => card.toJson()).toList(),
    'scenes': scenes.map((scene) => scene.toJson()).toList(),
    'completionUnlocks': completionUnlocks.toJson(),
  };
}

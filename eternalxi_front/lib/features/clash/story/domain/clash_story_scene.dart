import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_scene_type.dart';

/// Escena narrativa dentro de un nivel de historia Clash.
class ClashStoryScene {
  const ClashStoryScene({
    required this.id,
    required this.order,
    required this.type,
    required this.text,
    this.speaker,
    this.imagePath,
    this.backgroundPath,
    this.trigger,
    this.isSkippable = true,
  });

  final String id;
  final int order;
  final ClashStorySceneType type;
  final String? speaker;
  final String text;
  final String? imagePath;
  final String? backgroundPath;
  final String? trigger;
  final bool isSkippable;

  factory ClashStoryScene.fromJson(Map<String, dynamic> json) {
    return ClashStoryScene(
      id: clashRequireString(json['id'], 'id'),
      order: clashRequireInt(json['order'], 'order'),
      type: ClashStorySceneType.fromJson(
        clashRequireString(json['type'], 'type'),
      ),
      speaker: clashOptionalString(json['speaker']),
      text: clashRequireString(json['text'], 'text'),
      imagePath: clashOptionalString(json['imagePath']),
      backgroundPath: clashOptionalString(json['backgroundPath']),
      trigger: clashOptionalString(json['trigger']),
      isSkippable: json['isSkippable'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'type': type.toJson(),
    if (speaker != null) 'speaker': speaker,
    'text': text,
    if (imagePath != null) 'imagePath': imagePath,
    if (backgroundPath != null) 'backgroundPath': backgroundPath,
    if (trigger != null) 'trigger': trigger,
    'isSkippable': isSkippable,
  };
}

/// Carta invitada temporal para requisitos narrativos futuros.
class ClashStoryGuestCard {
  const ClashStoryGuestCard({
    required this.cardId,
    required this.position,
    required this.playerId,
  });

  final String cardId;
  final ClashPosition position;
  final int playerId;

  factory ClashStoryGuestCard.fromJson(Map<String, dynamic> json) {
    return ClashStoryGuestCard(
      cardId: clashRequireString(json['cardId'], 'cardId'),
      position: ClashPosition.fromJson(
        clashRequireString(json['position'], 'position'),
      ),
      playerId: clashRequireInt(json['playerId'], 'playerId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'position': position.toJson(),
    'playerId': playerId,
  };
}

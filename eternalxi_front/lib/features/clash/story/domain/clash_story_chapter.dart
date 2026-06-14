import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';

/// Capítulo de historia Clash con niveles ordenados.
class ClashStoryChapter {
  const ClashStoryChapter({
    required this.id,
    required this.sagaId,
    required this.title,
    required this.description,
    required this.order,
    required this.levels,
  });

  final String id;
  final String sagaId;
  final String title;
  final String description;
  final int order;
  final List<ClashStoryLevel> levels;

  factory ClashStoryChapter.fromJson(Map<String, dynamic> json) {
    final levelsRaw = json['levels'] as List? ?? const [];
    return ClashStoryChapter(
      id: clashRequireString(json['id'], 'id'),
      sagaId: clashRequireString(json['sagaId'], 'sagaId'),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      order: clashRequireInt(json['order'], 'order'),
      levels:
          levelsRaw
              .map(
                (item) => ClashStoryLevel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sagaId': sagaId,
    'title': title,
    'description': description,
    'order': order,
    'levels': levels.map((level) => level.toJson()).toList(),
  };
}

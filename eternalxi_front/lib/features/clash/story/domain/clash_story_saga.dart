import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Saga o arco narrativo de Clash.
class ClashStorySaga {
  const ClashStorySaga({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.chapterIds,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final List<String> chapterIds;
  final bool isUnlocked;

  factory ClashStorySaga.fromJson(Map<String, dynamic> json) {
    final chapterIdsRaw = json['chapterIds'] as List? ?? const [];
    return ClashStorySaga(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      order: clashRequireInt(json['order'], 'order'),
      chapterIds: chapterIdsRaw
          .map((id) => id.toString())
          .toList(growable: false),
      isUnlocked: json['isUnlocked'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'order': order,
    'chapterIds': chapterIds,
    'isUnlocked': isUnlocked,
  };
}

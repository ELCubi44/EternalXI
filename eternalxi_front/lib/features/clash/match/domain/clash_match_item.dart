import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_type.dart';

/// Definición de un objeto usable en el descanso.
class ClashMatchItem {
  const ClashMatchItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.amount,
    required this.targetCount,
    this.category,
  });

  final String id;
  final String name;
  final String description;
  final ClashMatchItemType type;
  final int amount;
  final int targetCount;
  final String? category;

  factory ClashMatchItem.fromJson(Map<String, dynamic> json) {
    return ClashMatchItem(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      type: ClashMatchItemType.fromJson(json['type']),
      amount: clashRequireInt(json['amount'], 'amount'),
      targetCount: clashRequireInt(json['targetCount'], 'targetCount'),
      category: clashOptionalString(json['category']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.toJson(),
    'amount': amount,
    'targetCount': targetCount,
    if (category != null) 'category': category,
  };
}

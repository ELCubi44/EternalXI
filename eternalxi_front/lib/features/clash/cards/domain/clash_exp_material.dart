import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Material consumible que otorga EXP a una carta (Fase 18).
class ClashExpMaterial {
  const ClashExpMaterial({
    required this.id,
    required this.name,
    required this.description,
    required this.xpAmount,
    this.rarity,
    this.iconKey,
  });

  final String id;
  final String name;
  final String description;
  final int xpAmount;
  final String? rarity;
  final String? iconKey;

  factory ClashExpMaterial.fromJson(Map<String, dynamic> json) {
    return ClashExpMaterial(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      xpAmount: clashRequireInt(json['xpAmount'], 'xpAmount'),
      rarity: clashOptionalString(json['rarity']),
      iconKey: clashOptionalString(json['iconKey']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'xpAmount': xpAmount,
    if (rarity != null) 'rarity': rarity,
    if (iconKey != null) 'iconKey': iconKey,
  };
}

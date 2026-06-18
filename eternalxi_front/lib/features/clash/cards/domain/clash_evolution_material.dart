import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Material consumible para evolucionar una carta (Fase 20).
class ClashEvolutionMaterial {
  const ClashEvolutionMaterial({
    required this.id,
    required this.name,
    required this.description,
    required this.targetRarity,
    this.iconKey,
  });

  final String id;
  final String name;
  final String description;
  final ClashRarity targetRarity;
  final String? iconKey;

  factory ClashEvolutionMaterial.fromJson(Map<String, dynamic> json) {
    return ClashEvolutionMaterial(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      targetRarity: ClashRarity.fromJson(json['targetRarity']),
      iconKey: clashOptionalString(json['iconKey']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'targetRarity': targetRarity.toJson(),
    if (iconKey != null) 'iconKey': iconKey,
  };
}

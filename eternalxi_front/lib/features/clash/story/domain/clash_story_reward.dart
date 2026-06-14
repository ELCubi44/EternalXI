import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Recompensa simple de un nivel de historia (economía local, sin backend).
class ClashStoryReward {
  const ClashStoryReward({
    this.gems = 0,
    this.coins = 0,
    this.items = const [],
    this.cardIds = const [],
    this.materials = const [],
    this.starterRosterKey,
  });

  /// Clave especial: entrega todas las cartas N iniciales de Eternal XI.
  static const eternalXiStarterRosterKey = 'eternal_xi_starter_n';

  final int gems;
  final int coins;
  final List<ClashStoryItemReward> items;
  final List<String> cardIds;
  final List<ClashStoryMaterialReward> materials;

  /// Si no es null, sustituye [cardIds] por el roster inicial Eternal XI N.
  final String? starterRosterKey;

  bool get isEmpty =>
      gems <= 0 &&
      coins <= 0 &&
      items.isEmpty &&
      cardIds.isEmpty &&
      materials.isEmpty &&
      starterRosterKey == null;

  factory ClashStoryReward.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? const [];
    final materialsRaw = json['materials'] as List? ?? const [];
    final cardsRaw = json['cards'] as List? ?? const [];

    return ClashStoryReward(
      gems: clashAsInt(json['gems']),
      coins: clashAsInt(json['coins']),
      items: itemsRaw
          .map(
            (item) => ClashStoryItemReward.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      cardIds: cardsRaw.map((id) => id.toString()).toList(growable: false),
      materials: materialsRaw
          .map(
            (item) => ClashStoryMaterialReward.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      starterRosterKey: clashOptionalString(json['starterRosterKey']),
    );
  }

  Map<String, dynamic> toJson() => {
    'gems': gems,
    'coins': coins,
    'items': items.map((item) => item.toJson()).toList(),
    'cards': cardIds,
    'materials': materials.map((item) => item.toJson()).toList(),
    if (starterRosterKey != null) 'starterRosterKey': starterRosterKey,
  };
}

class ClashStoryItemReward {
  const ClashStoryItemReward({
    required this.id,
    required this.name,
    required this.quantity,
  });

  final String id;
  final String name;
  final int quantity;

  factory ClashStoryItemReward.fromJson(Map<String, dynamic> json) {
    return ClashStoryItemReward(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      quantity: clashAsInt(json['quantity'], fallback: 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
  };
}

class ClashStoryMaterialReward {
  const ClashStoryMaterialReward({
    required this.id,
    required this.name,
    required this.quantity,
  });

  final String id;
  final String name;
  final int quantity;

  factory ClashStoryMaterialReward.fromJson(Map<String, dynamic> json) {
    return ClashStoryMaterialReward(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      quantity: clashAsInt(json['quantity'], fallback: 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
  };
}

import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';

/// Libro consumible que sube el nivel de una supertécnica (Fase 19).
class ClashTechniqueBook {
  const ClashTechniqueBook({
    required this.id,
    required this.name,
    required this.description,
    required this.levelUpSteps,
    this.compatibleType,
    this.rarity,
  });

  final String id;
  final String name;
  final String description;
  final int levelUpSteps;
  final ClashTechniqueType? compatibleType;
  final String? rarity;

  factory ClashTechniqueBook.fromJson(Map<String, dynamic> json) {
    final typeRaw = clashOptionalString(json['compatibleType']);
    return ClashTechniqueBook(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      levelUpSteps: clashRequireInt(json['levelUpSteps'], 'levelUpSteps'),
      compatibleType: typeRaw == null
          ? null
          : ClashTechniqueType.fromJson(typeRaw),
      rarity: clashOptionalString(json['rarity']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'levelUpSteps': levelUpSteps,
    if (compatibleType != null) 'compatibleType': compatibleType!.toJson(),
    if (rarity != null) 'rarity': rarity,
  };

  bool isCompatibleWith(ClashTechniqueType type) {
    return compatibleType == null || compatibleType == type;
  }
}

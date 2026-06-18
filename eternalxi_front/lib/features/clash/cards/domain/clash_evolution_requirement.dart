import 'clash_rarity.dart';

/// Requisitos para un paso de evolución N→R o R→SR.
class ClashEvolutionRequirement {
  const ClashEvolutionRequirement({
    required this.fromRarity,
    required this.toRarity,
    required this.minLevel,
    required this.requiredMaterials,
    this.coinCost,
  });

  final ClashRarity fromRarity;
  final ClashRarity toRarity;
  final int minLevel;
  final Map<String, int> requiredMaterials;
  final int? coinCost;
}

import 'clash_evolution_requirement.dart';
import 'clash_rarity.dart';

/// Tabla provisional de requisitos de evolución (Fase 20).
class ClashEvolutionTables {
  const ClashEvolutionTables._();

  static const insigniaR = 'insignia-r';
  static const insigniaSr = 'insignia-sr';

  static const requirements = <ClashEvolutionRequirement>[
    ClashEvolutionRequirement(
      fromRarity: ClashRarity.n,
      toRarity: ClashRarity.r,
      minLevel: 20,
      requiredMaterials: {insigniaR: 1},
      coinCost: 500,
    ),
    ClashEvolutionRequirement(
      fromRarity: ClashRarity.r,
      toRarity: ClashRarity.sr,
      minLevel: 50,
      requiredMaterials: {insigniaSr: 1},
      coinCost: 2000,
    ),
  ];

  static ClashEvolutionRequirement? requirementFor(ClashRarity from) {
    for (final requirement in requirements) {
      if (requirement.fromRarity == from) {
        return requirement;
      }
    }
    return null;
  }
}

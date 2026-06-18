import 'clash_card.dart';
import 'clash_card_progress.dart';
import 'clash_evolution_tables.dart';
import 'clash_rarity.dart';

/// Rareza efectiva y bonus de stats por evolución (Fase 20).
class ClashCardEvolutionResolver {
  const ClashCardEvolutionResolver._();

  static ClashRarity effectiveRarity(
    ClashCard card,
    ClashCardProgress? progress,
  ) {
    return progress?.evolvedRarity ?? card.rarity;
  }

  static ClashRarity? nextEvolutionStep(ClashRarity current) {
    return switch (current) {
      ClashRarity.n => ClashRarity.r,
      ClashRarity.r => ClashRarity.sr,
      _ => null,
    };
  }

  static bool canEvolve(ClashRarity current) =>
      nextEvolutionStep(current) != null;

  static double rarityStatMultiplier(ClashRarity rarity) => switch (rarity) {
    ClashRarity.r => 1.08,
    ClashRarity.sr => 1.18,
    _ => 1.0,
  };

  static String rarityLabel(ClashRarity rarity) => switch (rarity) {
    ClashRarity.n => 'N',
    ClashRarity.r => 'R',
    ClashRarity.sr => 'SR',
    ClashRarity.lr => 'LR',
    ClashRarity.xi => 'XI',
  };

  static String materialIdForTarget(ClashRarity target) => switch (target) {
    ClashRarity.r => ClashEvolutionTables.insigniaR,
    ClashRarity.sr => ClashEvolutionTables.insigniaSr,
    _ => throw ArgumentError('Sin material de evolución para $target'),
  };
}

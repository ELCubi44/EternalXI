import 'clash_card.dart';
import 'clash_card_evolution_resolver.dart';
import 'clash_card_progress.dart';
import 'clash_evolution_requirement.dart';
import 'clash_evolution_result.dart';
import 'clash_evolution_tables.dart';
import 'clash_rarity.dart';

class ClashEvolutionService {
  const ClashEvolutionService._();

  static ClashEvolutionResult previewEvolution({
    required String cardId,
    required ClashCard card,
    required ClashCardProgress progress,
    required Map<String, int> availableMaterials,
  }) {
    final currentRarity = ClashCardEvolutionResolver.effectiveRarity(
      card,
      progress,
    );
    final requirement = ClashEvolutionTables.requirementFor(currentRarity);
    if (requirement == null) {
      return _unchanged(
        cardId: cardId,
        card: card,
        progress: progress,
        error: ClashEvolutionError.cannotEvolve,
      );
    }

    if (progress.currentLevel < requirement.minLevel) {
      return _unchanged(
        cardId: cardId,
        card: card,
        progress: progress,
        error: ClashEvolutionError.insufficientLevel,
      );
    }

    for (final entry in requirement.requiredMaterials.entries) {
      final available = availableMaterials[entry.key] ?? 0;
      if (available < entry.value) {
        return _unchanged(
          cardId: cardId,
          card: card,
          progress: progress,
          error: ClashEvolutionError.insufficientMaterials,
        );
      }
    }

    final newRarity = requirement.toRarity;
    return ClashEvolutionResult(
      cardId: cardId,
      previousRarity: currentRarity,
      newRarity: newRarity,
      previousMaxLevel: currentRarity.maxLevel,
      newMaxLevel: newRarity.maxLevel,
      previousLevel: progress.currentLevel,
      newLevel: progress.currentLevel,
      materialsConsumed: Map<String, int>.from(requirement.requiredMaterials),
      coinsConsumed: 0,
    );
  }

  static ClashCardProgress progressAfterEvolution({
    required ClashCardProgress progress,
    required ClashRarity newRarity,
  }) {
    return progress.copyWith(evolvedRarity: newRarity);
  }

  static ClashEvolutionRequirement? activeRequirement(
    ClashCard card,
    ClashCardProgress? progress,
  ) {
    final current = ClashCardEvolutionResolver.effectiveRarity(card, progress);
    return ClashEvolutionTables.requirementFor(current);
  }

  static ClashEvolutionResult _unchanged({
    required String cardId,
    required ClashCard card,
    required ClashCardProgress progress,
    required ClashEvolutionError error,
  }) {
    final current = ClashCardEvolutionResolver.effectiveRarity(card, progress);
    return ClashEvolutionResult(
      cardId: cardId,
      previousRarity: current,
      newRarity: current,
      previousMaxLevel: current.maxLevel,
      newMaxLevel: current.maxLevel,
      previousLevel: progress.currentLevel,
      newLevel: progress.currentLevel,
      materialsConsumed: const {},
      coinsConsumed: 0,
      error: error,
    );
  }
}

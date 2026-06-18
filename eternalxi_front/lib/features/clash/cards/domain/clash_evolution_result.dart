import 'clash_rarity.dart';

enum ClashEvolutionError {
  cardNotOwned,
  cardNotFound,
  cannotEvolve,
  insufficientLevel,
  insufficientMaterials,
}

class ClashEvolutionResult {
  const ClashEvolutionResult({
    required this.cardId,
    required this.previousRarity,
    required this.newRarity,
    required this.previousMaxLevel,
    required this.newMaxLevel,
    required this.previousLevel,
    required this.newLevel,
    required this.materialsConsumed,
    required this.coinsConsumed,
    this.error,
  });

  final String cardId;
  final ClashRarity previousRarity;
  final ClashRarity newRarity;
  final int previousMaxLevel;
  final int newMaxLevel;
  final int previousLevel;
  final int newLevel;
  final Map<String, int> materialsConsumed;
  final int coinsConsumed;
  final ClashEvolutionError? error;

  bool get succeeded => error == null && previousRarity != newRarity;

  ClashEvolutionResult withError(ClashEvolutionError value) {
    return ClashEvolutionResult(
      cardId: cardId,
      previousRarity: previousRarity,
      newRarity: newRarity,
      previousMaxLevel: previousMaxLevel,
      newMaxLevel: newMaxLevel,
      previousLevel: previousLevel,
      newLevel: newLevel,
      materialsConsumed: materialsConsumed,
      coinsConsumed: coinsConsumed,
      error: value,
    );
  }
}

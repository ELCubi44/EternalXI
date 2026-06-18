/// Error al intentar usar un material EXP sobre una carta.
enum ClashExpMaterialUseError {
  cardNotFound,
  cardNotOwned,
  materialNotFound,
  insufficientQuantity,
  cardAtMaxLevel,
  cannotGainXp,
}

/// Resultado de consumir materiales EXP en una carta (Fase 18).
class ClashExpMaterialUseResult {
  const ClashExpMaterialUseResult({
    required this.cardId,
    required this.materialId,
    required this.quantityUsed,
    required this.xpGained,
    required this.previousLevel,
    required this.newLevel,
    required this.previousXp,
    required this.newXp,
    required this.didLevelUp,
    required this.reachedMaxLevel,
    this.error,
  });

  final String cardId;
  final String materialId;
  final int quantityUsed;
  final int xpGained;
  final int previousLevel;
  final int newLevel;
  final int previousXp;
  final int newXp;
  final bool didLevelUp;
  final bool reachedMaxLevel;
  final ClashExpMaterialUseError? error;

  bool get succeeded => error == null && xpGained > 0;
}

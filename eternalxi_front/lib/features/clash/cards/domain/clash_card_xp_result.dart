/// Resultado de aplicar EXP a una carta tras un partido (Fase 17).
class ClashCardXpResult {
  const ClashCardXpResult({
    required this.cardId,
    required this.cardName,
    required this.previousLevel,
    required this.newLevel,
    required this.previousXp,
    required this.newXp,
    required this.xpGained,
    required this.didLevelUp,
    required this.reachedMaxLevel,
  });

  final String cardId;
  final String cardName;
  final int previousLevel;
  final int newLevel;
  final int previousXp;
  final int newXp;
  final int xpGained;
  final bool didLevelUp;
  final bool reachedMaxLevel;

  int get levelsGained => newLevel - previousLevel;
}

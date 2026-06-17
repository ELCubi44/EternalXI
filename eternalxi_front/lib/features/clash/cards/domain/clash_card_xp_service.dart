import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Aplica EXP de partido a una carta (Fase 17).
class ClashCardXpService {
  const ClashCardXpService._();

  static ClashCardProgress initialProgress(String cardId) {
    return ClashCardProgress(
      cardId: cardId,
      currentLevel: 1,
      currentExperience: 0,
      unlockedDuplicateNodes: 0,
      techniqueLevels: const {},
    );
  }

  static bool isAtMaxLevel(ClashCardProgress progress, ClashRarity rarity) {
    return progress.currentLevel >= rarity.maxLevel;
  }

  static ClashCardXpResult applyXp({
    required ClashCardProgress progress,
    required ClashRarity rarity,
    required String cardName,
    required int xpAmount,
  }) {
    final previousLevel = progress.currentLevel;
    final previousXp = progress.currentExperience;

    if (xpAmount <= 0 || isAtMaxLevel(progress, rarity)) {
      return ClashCardXpResult(
        cardId: progress.cardId,
        cardName: cardName,
        previousLevel: previousLevel,
        newLevel: previousLevel,
        previousXp: previousXp,
        newXp: previousXp,
        xpGained: 0,
        didLevelUp: false,
        reachedMaxLevel: isAtMaxLevel(progress, rarity),
      );
    }

    var level = previousLevel;
    var xp = previousXp + xpAmount;
    var didLevelUp = false;

    while (level < rarity.maxLevel) {
      final needed = ClashCardXpTable.xpToNextLevel(level, rarity);
      if (xp < needed) {
        break;
      }
      xp -= needed;
      level++;
      didLevelUp = true;
    }

    if (level >= rarity.maxLevel) {
      level = rarity.maxLevel;
      xp = 0;
    }

    return ClashCardXpResult(
      cardId: progress.cardId,
      cardName: cardName,
      previousLevel: previousLevel,
      newLevel: level,
      previousXp: previousXp,
      newXp: xp,
      xpGained: xpAmount,
      didLevelUp: didLevelUp,
      reachedMaxLevel: level >= rarity.maxLevel,
    );
  }

  static ClashCardProgress progressAfterResult(
    ClashCardProgress progress,
    ClashCardXpResult result,
  ) {
    return progress.copyWith(
      currentLevel: result.newLevel,
      currentExperience: result.newXp,
    );
  }
}

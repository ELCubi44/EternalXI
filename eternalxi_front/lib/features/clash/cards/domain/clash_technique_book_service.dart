import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';

/// Aplica libros de técnica a supertécnicas (Fase 19).
class ClashTechniqueBookService {
  const ClashTechniqueBookService._();

  static ClashTechniqueBookUseResult applyBook({
    required String cardId,
    required ClashSuperTechnique technique,
    required ClashTechniqueBook book,
    required ClashCardProgress progress,
    int quantity = 1,
  }) {
    final previousLevel = ClashTechniqueProgressResolver.resolvedLevel(
      technique: technique,
      progress: progress,
    );
    final previousPower = ClashTechniqueProgressResolver.effectivePower(
      technique: technique,
      progress: progress,
    );

    if (!book.isCompatibleWith(technique.type)) {
      return _failed(
        cardId: cardId,
        techniqueId: technique.id,
        bookId: book.id,
        previousLevel: previousLevel,
        previousPower: previousPower,
        error: ClashTechniqueBookUseError.incompatibleBook,
      );
    }

    if (previousLevel.isMax) {
      return _failed(
        cardId: cardId,
        techniqueId: technique.id,
        bookId: book.id,
        previousLevel: previousLevel,
        previousPower: previousPower,
        error: ClashTechniqueBookUseError.techniqueAtMaxLevel,
        reachedMaxLevel: true,
      );
    }

    final totalSteps = book.levelUpSteps * quantity;
    final newLevel = previousLevel.advancedBy(totalSteps);
    final didLevelUp = newLevel.stepIndex > previousLevel.stepIndex;

    if (!didLevelUp) {
      return _failed(
        cardId: cardId,
        techniqueId: technique.id,
        bookId: book.id,
        previousLevel: previousLevel,
        previousPower: previousPower,
        error: ClashTechniqueBookUseError.cannotImprove,
        reachedMaxLevel: previousLevel.isMax,
      );
    }

    final upgraded = technique.withLevel(newLevel);
    final newPower = upgraded.effectivePower;

    return ClashTechniqueBookUseResult(
      cardId: cardId,
      techniqueId: technique.id,
      bookId: book.id,
      quantityUsed: quantity,
      previousLevel: previousLevel,
      newLevel: newLevel,
      previousEffectivePower: previousPower,
      newEffectivePower: newPower,
      didLevelUp: true,
      reachedMaxLevel: newLevel.isMax,
    );
  }

  static ClashCardProgress progressAfterResult({
    required ClashCardProgress progress,
    required ClashTechniqueBookUseResult result,
  }) {
    final levels = Map<String, ClashTechniqueLevel>.from(
      progress.techniqueLevels,
    );
    levels[result.techniqueId] = result.newLevel;
    return progress.copyWith(techniqueLevels: levels);
  }

  static ClashTechniqueBookUseResult _failed({
    required String cardId,
    required String techniqueId,
    required String bookId,
    required ClashTechniqueLevel previousLevel,
    required int previousPower,
    required ClashTechniqueBookUseError error,
    bool reachedMaxLevel = false,
  }) {
    return ClashTechniqueBookUseResult(
      cardId: cardId,
      techniqueId: techniqueId,
      bookId: bookId,
      quantityUsed: 0,
      previousLevel: previousLevel,
      newLevel: previousLevel,
      previousEffectivePower: previousPower,
      newEffectivePower: previousPower,
      didLevelUp: false,
      reachedMaxLevel: reachedMaxLevel,
      error: error,
    );
  }
}

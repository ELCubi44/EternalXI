import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';

/// Error al intentar usar un libro de técnica.
enum ClashTechniqueBookUseError {
  cardNotFound,
  cardNotOwned,
  techniqueNotFound,
  bookNotFound,
  incompatibleBook,
  insufficientQuantity,
  techniqueAtMaxLevel,
  cannotImprove,
}

/// Resultado de consumir un libro sobre una supertécnica (Fase 19).
class ClashTechniqueBookUseResult {
  const ClashTechniqueBookUseResult({
    required this.cardId,
    required this.techniqueId,
    required this.bookId,
    required this.quantityUsed,
    required this.previousLevel,
    required this.newLevel,
    required this.previousEffectivePower,
    required this.newEffectivePower,
    required this.didLevelUp,
    required this.reachedMaxLevel,
    this.error,
  });

  final String cardId;
  final String techniqueId;
  final String bookId;
  final int quantityUsed;
  final ClashTechniqueLevel previousLevel;
  final ClashTechniqueLevel newLevel;
  final int previousEffectivePower;
  final int newEffectivePower;
  final bool didLevelUp;
  final bool reachedMaxLevel;
  final ClashTechniqueBookUseError? error;

  bool get succeeded => error == null && didLevelUp;
}

extension ClashTechniqueBookUseResultMutators on ClashTechniqueBookUseResult {
  ClashTechniqueBookUseResult withError(ClashTechniqueBookUseError value) {
    return ClashTechniqueBookUseResult(
      cardId: cardId,
      techniqueId: techniqueId,
      bookId: bookId,
      quantityUsed: 0,
      previousLevel: previousLevel,
      newLevel: previousLevel,
      previousEffectivePower: previousEffectivePower,
      newEffectivePower: previousEffectivePower,
      didLevelUp: false,
      reachedMaxLevel: reachedMaxLevel,
      error: value,
    );
  }

  ClashTechniqueBookUseResult withQuantityUsed(int value) {
    return ClashTechniqueBookUseResult(
      cardId: cardId,
      techniqueId: techniqueId,
      bookId: bookId,
      quantityUsed: value,
      previousLevel: previousLevel,
      newLevel: newLevel,
      previousEffectivePower: previousEffectivePower,
      newEffectivePower: newEffectivePower,
      didLevelUp: didLevelUp,
      reachedMaxLevel: reachedMaxLevel,
      error: error,
    );
  }
}

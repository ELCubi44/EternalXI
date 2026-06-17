import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';

/// Escalado provisional de stats por nivel de carta (Fase 17).
class ClashCardLevelScaling {
  const ClashCardLevelScaling._();

  /// Nivel 1 → 1.00; nivel máximo → ~1.25 (LR/XI usan la misma curva por ahora).
  static double levelMultiplier(int level, ClashRarity rarity) {
    final maxLevel = rarity.maxLevel;
    if (maxLevel <= 1 || level <= 1) {
      return 1.0;
    }
    final cappedLevel = level.clamp(1, maxLevel);
    final t = (cappedLevel - 1) / (maxLevel - 1);
    return 1.0 + t * 0.25;
  }

  static int effectiveLevel(ClashCard card, ClashCardProgress? progress) {
    return progress?.currentLevel ?? card.level;
  }

  static ClashStats effectiveStats(
    ClashCard card,
    ClashCardProgress? progress,
  ) {
    final level = effectiveLevel(card, progress);
    final multiplier = levelMultiplier(level, card.rarity);
    return card.stats.scaled(multiplier);
  }

  static int effectivePower(ClashCard card, ClashCardProgress? progress) {
    return effectiveStats(card, progress).power;
  }
}

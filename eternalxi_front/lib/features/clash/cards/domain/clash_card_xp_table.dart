import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Curva provisional de XP por nivel y rareza (Fase 17).
///
/// `xpToNextLevel(level, rarity) = base + level * factor`
class ClashCardXpTable {
  const ClashCardXpTable._();

  static (int base, int factor) curveFor(ClashRarity rarity) =>
      switch (rarity) {
        ClashRarity.n => (40, 10),
        ClashRarity.r => (60, 14),
        ClashRarity.sr => (90, 20),
        ClashRarity.lr => (130, 28),
        ClashRarity.xi => (160, 34),
      };

  /// XP necesaria para pasar de [level] a `level + 1`.
  static int xpToNextLevel(int level, ClashRarity rarity) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'Debe ser >= 1');
    }
    final (base, factor) = curveFor(rarity);
    return base + level * factor;
  }
}

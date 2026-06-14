import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:flutter/material.dart';

/// Etiqueta visual de rareza Clash.
class ClashRarityBadge extends StatelessWidget {
  const ClashRarityBadge({required this.rarity, super.key});

  final ClashRarity rarity;

  static String label(ClashRarity rarity) => switch (rarity) {
    ClashRarity.n => 'N',
    ClashRarity.r => 'R',
    ClashRarity.sr => 'SR',
    ClashRarity.lr => 'LR',
    ClashRarity.xi => 'XI',
  };

  static Color color(ClashRarity rarity) => switch (rarity) {
    ClashRarity.n => const Color(0xFF8E9AAF),
    ClashRarity.r => const Color(0xFF4DA3FF),
    ClashRarity.sr => const Color(0xFFB06CFF),
    ClashRarity.lr => const Color(0xFFFFB020),
    ClashRarity.xi => const Color(0xFF00E5CC),
  };

  @override
  Widget build(BuildContext context) {
    final bg = color(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 0.55)),
      ),
      child: Text(
        label(rarity),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: bg,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

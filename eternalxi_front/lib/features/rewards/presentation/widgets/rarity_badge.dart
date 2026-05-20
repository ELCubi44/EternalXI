import 'package:eternal_xi/features/rewards/utils/reward_rarity_style.dart';
import 'package:flutter/material.dart';

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.compact = false});

  final String rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = styleForRarity(rarity);
    final hPad = compact ? 5.0 : 8.0;
    final vPad = compact ? 2.0 : 3.0;
    final fontSize = compact ? 9.0 : null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: s.badgeBackground,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: s.border.withValues(alpha: 0.65)),
      ),
      child: Text(
        s.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: s.badgeForeground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

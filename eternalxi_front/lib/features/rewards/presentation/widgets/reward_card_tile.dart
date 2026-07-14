import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/rarity_badge.dart';
import 'package:eternal_xi/features/rewards/utils/reward_rarity_style.dart';
import 'package:flutter/material.dart';

class RewardCardTile extends StatelessWidget {
  const RewardCardTile({
    super.key,
    required this.card,
    required this.onUse,
    required this.onTap,
  });

  final RewardCardModel card;
  final VoidCallback? onUse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rl10n = context.rewardsL10n;
    final s = styleForRarity(card.rareza);
    final effectShort = rl10n.tipoEfectoLabelShort(card.tipoEfecto);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: s.gradient,
          ),
          border: Border.all(color: s.border.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: s.glow.withValues(alpha: 0.25),
              blurRadius: rarityGlowSigma(card.rareza) * 0.7,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rl10n.cardDisplayName(card),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  RarityBadge(rarity: card.rareza, compact: true),
                ],
              ),
              const SizedBox(height: 5),
              if (effectShort.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  child: Text(
                    effectShort,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ] else
                const SizedBox(height: 4),
              Expanded(
                child: Text(
                  rl10n.cardDisplayDescription(card),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.25,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: card.isAvailable
                          ? const Color(0xFF81C784)
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      rl10n.estadoLabel(card.estado),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: card.isAvailable
                            ? const Color(0xFF81C784)
                            : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (card.isAvailable)
                    SizedBox(
                      height: 28,
                      child: FilledButton(
                        onPressed: onUse,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                            fontSize: 11,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(rl10n.use),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

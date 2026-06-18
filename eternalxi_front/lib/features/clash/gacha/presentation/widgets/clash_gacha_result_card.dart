import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_pity_card.dart';
import 'package:flutter/material.dart';

/// Tarjeta de resultado individual de invocación (Fase 38).
class ClashGachaResultCard extends StatelessWidget {
  const ClashGachaResultCard({required this.item, super.key});

  final ClashGachaPullResultItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rarityColor = ClashRarityBadge.color(item.rarity);
    final status = item.isNew
        ? l10n.clashGachaResultNew
        : item.upgradedRarity
        ? l10n.clashGachaResultUpgraded
        : l10n.clashGachaResultDuplicate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cardName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Wrap(
                  children: [
                    if (item.wasPity)
                      ClashGachaResultChip(label: l10n.clashGachaPityChip),
                    if (item.wasMultiGuarantee)
                      ClashGachaResultChip(
                        label: l10n.clashGachaMultiGuaranteeChip,
                      ),
                  ],
                ),
                if (item.isDuplicate)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.clashGachaResultDuplicates(
                        item.duplicateCopiesAfter,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ClashRarityBadge(rarity: item.rarity),
        ],
      ),
    );
  }
}

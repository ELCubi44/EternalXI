import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Tile reutilizable de carta Clash para cuadrículas de colección (Fase 36).
class ClashCardTile extends StatelessWidget {
  const ClashCardTile({required this.entry, this.onTap, super.key});

  final ClashCardCatalogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final card = entry.card;
    final rarityColor = ClashRarityBadge.color(entry.effectiveRarity);
    final levelLabel = entry.isMaxLevel
        ? l10n.clashCardMaxLevel
        : l10n.clashCardLevelShort(entry.displayLevel);

    return Material(
      color: context.xiCardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: rarityColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                rarityColor.withValues(alpha: 0.1),
                context.xiCardSurface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClashCardPortrait(
                    name: entry.name,
                    imagePath: card.basicPortraitPath,
                    height: double.infinity,
                    position: card.position,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.xiTextPrimary,
                        ),
                      ),
                    ),
                    if (entry.isEvolved) ...[
                      const SizedBox(width: 4),
                      _ChipLabel(
                        text: l10n.clashCardEvolved,
                        accent: rarityColor,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${card.position.displayNameEs} · ${card.style.displayNameEs}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.xiTextSecondary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ),
                    ClashRarityBadge(rarity: entry.effectiveRarity),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ChipLabel(
                      text: levelLabel,
                      accent: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    Text(
                      l10n.clashCardPowerValue(entry.power),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (entry.hasDuplicateCopies || entry.hasSkillTree) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (entry.hasDuplicateCopies)
                        _ChipLabel(
                          text: l10n.clashCardDuplicateCopies(
                            entry.duplicateCopies,
                          ),
                        ),
                      if (entry.hasSkillTree)
                        _ChipLabel(
                          text: l10n.clashCardSkillTreeShort(
                            entry.unlockedSkillTreeCount,
                            5,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text, this.accent});

  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.xiTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.xiDivider),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_card_epic_showcase.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Tile de colección con presentación épica compacta.
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
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: rarityColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClashCardEpicShowcase(entry: entry, compact: true),
            ),
            Container(
              color: context.xiCardSurface,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                children: [
                  ClashRarityBadge(rarity: entry.effectiveRarity),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${card.position.displayNameEs} · ${card.style.displayNameEs}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Text(
                    levelLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.hasDuplicateCopies || entry.hasSkillTree)
              Container(
                color: context.xiCardSurface,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Wrap(
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
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.xiTextSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.xiDivider),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.xiTextSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

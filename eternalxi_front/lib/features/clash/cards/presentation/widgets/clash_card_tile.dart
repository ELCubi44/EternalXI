import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Tile reutilizable de carta Clash para cuadrículas de colección.
class ClashCardTile extends StatelessWidget {
  const ClashCardTile({required this.entry, this.onTap, super.key});

  final ClashCardCatalogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = entry.card;

    return Material(
      color: context.xiCardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.xiDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  ClashRarityBadge(rarity: card.rarity),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                card.position.displayNameEs,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _ChipLabel(text: card.style.displayNameEs),
                  const Spacer(),
                  Text(
                    'Nv.${entry.displayLevel}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.xiTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.power} PWR',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
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
        color: context.xiChipBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.xiDivider),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.xiTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

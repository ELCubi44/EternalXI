import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';

class ClashLineupSlotTile extends StatelessWidget {
  const ClashLineupSlotTile({
    required this.position,
    required this.entry,
    required this.onTap,
    super.key,
  });

  final ClashPosition position;
  final ClashCardCatalogEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isEmpty = entry == null;

    return Material(
      color: context.xiCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEmpty
              ? context.xiDivider
              : theme.colorScheme.primary.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.displayNameEs,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.xiTextSecondary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty ? l10n.clashLineupSlotEmpty : entry!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.xiTextPrimary,
                      ),
                    ),
                    if (!isEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${entry!.power} PWR',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isEmpty) ClashRarityBadge(rarity: entry!.card.rarity),
              if (isEmpty)
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: context.xiTextSecondary.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClashLineupFieldView extends StatelessWidget {
  const ClashLineupFieldView({
    required this.lineup,
    required this.controller,
    required this.onSlotTap,
    super.key,
  });

  final ClashLineup7v7 lineup;
  final ClashLineupsController controller;
  final ValueChanged<ClashPosition> onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiSurfaceInset,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < ClashLineup7v7.slotOrder.length; i++) ...[
            ClashLineupSlotTile(
              position: ClashLineup7v7
                  .slotOrder[ClashLineup7v7.slotOrder.length - 1 - i],
              entry: controller.entryForCardId(
                lineup.cardIdFor(
                  ClashLineup7v7.slotOrder[ClashLineup7v7.slotOrder.length -
                      1 -
                      i],
                ),
              ),
              onTap: () => onSlotTap(
                ClashLineup7v7.slotOrder[ClashLineup7v7.slotOrder.length -
                    1 -
                    i],
              ),
            ),
            if (i < ClashLineup7v7.slotOrder.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

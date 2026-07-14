import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Tarjeta de slot en alineación 7v7 (Fase 37).
class ClashLineupSlotTile extends StatelessWidget {
  const ClashLineupSlotTile({
    required this.position,
    required this.entry,
    required this.onTap,
    this.zoneAccent,
    super.key,
  });

  final ClashPosition position;
  final ClashCardCatalogEntry? entry;
  final VoidCallback onTap;
  final Color? zoneAccent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isEmpty = entry == null;
    final accent = zoneAccent ?? theme.colorScheme.primary;
    final rarityColor = isEmpty
        ? context.xiDivider
        : ClashRarityBadge.color(entry!.effectiveRarity);

    return Material(
      color: context.xiCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEmpty
              ? accent.withValues(alpha: 0.35)
              : rarityColor.withValues(alpha: 0.55),
          width: isEmpty ? 1 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accent.withValues(alpha: isEmpty ? 0.04 : 0.08),
                context.xiCardSurface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _PositionBadge(position: position, accent: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: accent.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.clashLineupChooseSlot,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: accent,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        Text(
                          entry!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: context.xiTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ClashRarityBadge(rarity: entry!.effectiveRarity),
                            _MiniChip(
                              text: entry!.isMaxLevel
                                  ? l10n.clashCardMaxLevel
                                  : l10n.clashCardLevelShort(
                                      entry!.displayLevel,
                                    ),
                            ),
                            _MiniChip(
                              text: l10n.clashCardPowerValue(entry!.power),
                              accent: theme.colorScheme.primary,
                            ),
                            _MiniChip(text: entry!.card.style.displayNameEs),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.accent});

  final ClashPosition position;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        _shortLabel(position),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
        ),
      ),
    );
  }

  static String _shortLabel(ClashPosition position) => switch (position) {
    ClashPosition.goalkeeper => 'POR',
    ClashPosition.centreBack => 'DFC',
    ClashPosition.fullBack => 'LAT',
    ClashPosition.defensiveMidfielder => 'MCD',
    ClashPosition.attackingMidfielder => 'MCO',
    ClashPosition.winger => 'EXT',
    ClashPosition.striker => 'DEL',
  };
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text, this.accent});

  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.xiTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
        ),
      ),
    );
  }
}

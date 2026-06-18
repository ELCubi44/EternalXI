import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Cabecera de estadísticas de la colección Clash (Fase 36).
class ClashCollectionHeader extends StatelessWidget {
  const ClashCollectionHeader({required this.controller, super.key});

  final ClashCardsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final strongest = controller.strongestOwned;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.collections_bookmark_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashCollectionOwnedCount(controller.ownedCount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                l10n.clashCollectionTotalPower(controller.totalOwnedPower),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (strongest != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.clashCollectionStrongest(
                      strongest.name,
                      strongest.power,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ),
                ClashRarityBadge(rarity: strongest.effectiveRarity),
              ],
            ),
          ],
          if (controller.hasActiveFilters) ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashCollectionActiveFilters,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            _ActiveFilterChips(controller: controller),
          ],
        ],
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.controller});

  final ClashCardsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[];

    final query = controller.searchQuery.trim();
    if (query.isNotEmpty) {
      chips.add(_chip(context, '"$query"'));
    }
    final rarity = controller.rarityFilter;
    if (rarity != null) {
      chips.add(
        _chip(
          context,
          '${l10n.clashFilterRarity}: ${rarity.name.toUpperCase()}',
        ),
      );
    }
    final position = controller.positionFilter;
    if (position != null) {
      chips.add(
        _chip(
          context,
          '${l10n.clashFilterPosition}: ${position.displayNameEs}',
        ),
      );
    }
    final style = controller.styleFilter;
    if (style != null) {
      chips.add(
        _chip(context, '${l10n.clashFilterStyle}: ${style.displayNameEs}'),
      );
    }

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _chip(BuildContext context, String label) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: context.xiChipBackground,
    );
  }
}

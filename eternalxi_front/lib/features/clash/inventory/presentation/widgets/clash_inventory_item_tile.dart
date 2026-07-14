import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:flutter/material.dart';

class ClashInventoryItemTile extends StatelessWidget {
  const ClashInventoryItemTile({required this.item, super.key});

  final ClashInventoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = _accentFor(theme.colorScheme, item.category);
    final isEmpty = item.quantity <= 0;

    return Opacity(
      opacity: isEmpty ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.xiCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.xiDivider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(item.category), color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '×${item.quantity}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CategoryBadge(
                    label: _categoryLabel(l10n, item.category),
                    color: accent,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _usageLabel(l10n, item.usageHint),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(ClashInventoryCategory category) {
    return switch (category) {
      ClashInventoryCategory.exp => Icons.auto_stories_rounded,
      ClashInventoryCategory.technique => Icons.menu_book_rounded,
      ClashInventoryCategory.evolution => Icons.military_tech_rounded,
      ClashInventoryCategory.match => Icons.medical_services_rounded,
      ClashInventoryCategory.tickets => Icons.confirmation_number_rounded,
    };
  }

  static Color _accentFor(ColorScheme scheme, ClashInventoryCategory category) {
    return switch (category) {
      ClashInventoryCategory.exp => scheme.primary,
      ClashInventoryCategory.technique => scheme.tertiary,
      ClashInventoryCategory.evolution => scheme.secondary,
      ClashInventoryCategory.match => scheme.error,
      ClashInventoryCategory.tickets => scheme.primaryContainer,
    };
  }

  String _categoryLabel(dynamic l10n, ClashInventoryCategory category) {
    return switch (category) {
      ClashInventoryCategory.exp => l10n.clashInventoryExp,
      ClashInventoryCategory.technique => l10n.clashInventoryTechnique,
      ClashInventoryCategory.evolution => l10n.clashInventoryEvolution,
      ClashInventoryCategory.match => l10n.clashInventoryMatch,
      ClashInventoryCategory.tickets => l10n.clashInventoryTickets,
    };
  }

  String _usageLabel(dynamic l10n, ClashInventoryUsageHint hint) {
    return switch (hint) {
      ClashInventoryUsageHint.fromCardDetail =>
        l10n.clashInventoryUseFromCardDetail,
      ClashInventoryUsageHint.duringHalftime =>
        l10n.clashInventoryUseDuringHalftime,
      ClashInventoryUsageHint.useInSummon => l10n.clashInventoryUseInSummon,
    };
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
        ),
      ),
    );
  }
}

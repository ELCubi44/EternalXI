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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              _iconFor(item.category),
              color: theme.colorScheme.onPrimaryContainer,
            ),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '×${item.quantity}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
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
                Text(
                  _categoryLabel(l10n, item.category),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.xiTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _usageLabel(l10n, item.usageHint),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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

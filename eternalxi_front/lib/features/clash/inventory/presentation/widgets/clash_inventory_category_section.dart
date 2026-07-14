import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/widgets/clash_inventory_item_tile.dart';
import 'package:flutter/material.dart';

class ClashInventoryCategorySection extends StatelessWidget {
  const ClashInventoryCategorySection({
    required this.category,
    required this.items,
    required this.showProvisionalNote,
    super.key,
  });

  final ClashInventoryCategory category;
  final List<ClashInventoryItem> items;
  final bool showProvisionalNote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = _accentFor(theme.colorScheme, category);
    final visibleItems = items.where((item) => item.quantity > 0).toList();
    final zeroItems = items.where((item) => item.quantity <= 0).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Icon(_iconFor(category), size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _categoryLabel(l10n, category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  ),
              ),
            ),
          ],
        ),
        if (showProvisionalNote &&
            category == ClashInventoryCategory.match) ...[
          const SizedBox(height: 6),
          Text(
            l10n.clashInventoryMatchKitProvisional,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (visibleItems.isEmpty && zeroItems.isEmpty)
          _EmptyCategoryCard(message: l10n.clashInventoryEmptyCategory)
        else ...[
          for (final item in visibleItems) ...[
            ClashInventoryItemTile(item: item),
            const SizedBox(height: 8),
          ],
          if (zeroItems.isNotEmpty) ...[
            Text(
              l10n.clashInventoryZeroQuantityHeader,
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in zeroItems) ...[
              ClashInventoryItemTile(item: item),
              const SizedBox(height: 8),
            ],
          ],
        ],
        const SizedBox(height: 16),
      ],
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
}

class _EmptyCategoryCard extends StatelessWidget {
  const _EmptyCategoryCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xiDivider),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
      ),
    );
  }
}

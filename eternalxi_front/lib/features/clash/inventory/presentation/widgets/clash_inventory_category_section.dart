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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _categoryLabel(l10n, category),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (showProvisionalNote &&
            category == ClashInventoryCategory.match) ...[
          const SizedBox(height: 6),
          Text(
            l10n.clashInventoryMatchKitProvisional,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (items.isEmpty)
          _EmptyCategoryCard(message: l10n.clashInventoryEmptyCategory)
        else
          for (final item in items) ...[
            ClashInventoryItemTile(item: item),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
      ],
    );
  }

  String _categoryLabel(dynamic l10n, ClashInventoryCategory category) {
    return switch (category) {
      ClashInventoryCategory.exp => l10n.clashInventoryExp,
      ClashInventoryCategory.technique => l10n.clashInventoryTechnique,
      ClashInventoryCategory.evolution => l10n.clashInventoryEvolution,
      ClashInventoryCategory.match => l10n.clashInventoryMatch,
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

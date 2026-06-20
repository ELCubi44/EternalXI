import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/controllers/clash_inventory_controller.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/widgets/clash_inventory_category_section.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/widgets/clash_inventory_item_tile.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashInventoryScreen extends StatefulWidget {
  const ClashInventoryScreen({super.key});

  @override
  State<ClashInventoryScreen> createState() => _ClashInventoryScreenState();
}

class _ClashInventoryScreenState extends State<ClashInventoryScreen> {
  late final ClashInventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashInventoryController(
      repository: context.read<ClashInventoryRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToShop(BuildContext context) {
    try {
      context.read<ClashNavigationController>().selectTab(3);
    } catch (_) {}
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClashInventoryController>.value(
      value: _controller,
      child: _ClashInventoryBody(onGoToShop: () => _goToShop(context)),
    );
  }
}

class _ClashInventoryBody extends StatelessWidget {
  const _ClashInventoryBody({required this.onGoToShop});

  final VoidCallback onGoToShop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashInventoryController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clashInventoryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: switch (controller.state) {
        ClashInventoryLoadState.loading || ClashInventoryLoadState.idle =>
          const Center(child: CircularProgressIndicator()),
        ClashInventoryLoadState.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(controller.errorMessage ?? l10n.clashStoryLoadError),
          ),
        ),
        ClashInventoryLoadState.ready => _ReadyInventory(
          controller: controller,
          onGoToShop: onGoToShop,
        ),
      },
    );
  }
}

class _ReadyInventory extends StatelessWidget {
  const _ReadyInventory({required this.controller, required this.onGoToShop});

  final ClashInventoryController controller;
  final VoidCallback onGoToShop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = controller.summary;
    final grouped = controller.groupedVisibleItems;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (summary != null) _SummaryCard(summary: summary),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _FilterChips(
            selected: controller.filter,
            onSelected: controller.setFilter,
          ),
        ),
        const SizedBox(height: 16),
        if (controller.filter == ClashInventoryFilter.all)
          for (final category in ClashInventoryCategory.values)
            ClashInventoryCategorySection(
              category: category,
              items: grouped[category] ?? const [],
              showProvisionalNote: true,
            )
        else if (controller.visibleItems.isEmpty)
          _EmptyFilterState(onGoToShop: onGoToShop)
        else ...[
          if (controller.filter == ClashInventoryFilter.match) ...[
            Text(
              l10n.clashInventoryMatchKitProvisional,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final item in controller.visibleItems) ...[
            ClashInventoryItemTile(item: item),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.clashRewardHistory),
          icon: const Icon(Icons.history_rounded),
          label: Text(l10n.clashRewardHistoryView),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ClashInventorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashInventorySummaryTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashInventoryTotalItems(summary.totalQuantity),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ClashInventoryCategory.values)
                _SummaryChip(
                  label: l10n.clashInventoryCategoryCount(
                    _categoryShortLabel(l10n, category),
                    summary.quantityFor(category),
                  ),
                  color: _accentFor(theme.colorScheme, category),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryShortLabel(dynamic l10n, ClashInventoryCategory category) {
    return switch (category) {
      ClashInventoryCategory.exp => l10n.clashInventoryExp,
      ClashInventoryCategory.technique => l10n.clashInventoryTechnique,
      ClashInventoryCategory.evolution => l10n.clashInventoryEvolution,
      ClashInventoryCategory.match => l10n.clashInventoryMatch,
      ClashInventoryCategory.tickets => l10n.clashInventoryTickets,
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
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final ClashInventoryFilter selected;
  final ValueChanged<ClashInventoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        for (final filter in ClashInventoryFilter.values) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterLabel(l10n, filter)),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
          ),
        ],
      ],
    );
  }

  String _filterLabel(dynamic l10n, ClashInventoryFilter filter) {
    return switch (filter) {
      ClashInventoryFilter.all => l10n.clashInventoryAll,
      ClashInventoryFilter.exp => l10n.clashInventoryExp,
      ClashInventoryFilter.technique => l10n.clashInventoryTechnique,
      ClashInventoryFilter.evolution => l10n.clashInventoryEvolution,
      ClashInventoryFilter.match => l10n.clashInventoryMatch,
      ClashInventoryFilter.tickets => l10n.clashInventoryTickets,
    };
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.onGoToShop});

  final VoidCallback onGoToShop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: context.xiTextSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.clashInventoryEmptyFilter,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: context.xiTextSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onGoToShop,
            child: Text(l10n.clashInventoryGoToShop),
          ),
        ],
      ),
    );
  }
}

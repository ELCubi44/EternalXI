import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_tile.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_collection_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashCardCollectionScreen extends StatefulWidget {
  const ClashCardCollectionScreen({super.key});

  @override
  State<ClashCardCollectionScreen> createState() =>
      _ClashCardCollectionScreenState();
}

class _ClashCardCollectionScreenState extends State<ClashCardCollectionScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ClashCardsController>();
      if (controller.state == ClashCardsLoadState.idle) {
        controller.load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearFilters(ClashCardsController controller) {
    _searchController.clear();
    controller.clearFilters();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
  }

  void _closeSearch(ClashCardsController controller) {
    setState(() => _searchOpen = false);
    if (_searchController.text.trim().isEmpty) {
      controller.setSearchQuery('');
    }
  }

  void _showCollectionInfo() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clashCollectionInfoTitle),
          content: SingleChildScrollView(
            child: Text(l10n.clashCollectionInfoBody),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashCardsController>();

    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, topInset + 16, 4, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go(AppRoutes.clash),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l10n.clashBack,
              ),
              Expanded(
                child: _searchOpen
                    ? TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: controller.setSearchQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.clashSearchHint,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            tooltip: l10n.cancel,
                            onPressed: () {
                              _clearFilters(controller);
                              _closeSearch(controller);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      )
                    : Transform(
                        transform: Matrix4.skewX(-0.12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(
                                      alpha: 0.75,
                                    ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Transform(
                            transform: Matrix4.skewX(0.12),
                            child: Text(
                              l10n.clashCollectionTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      ),
              ),
              if (!_searchOpen) ...[
                IconButton(
                  tooltip: l10n.clashSearchHint,
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: l10n.clashCollectionInfoTitle,
                  onPressed: _showCollectionInfo,
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ],
            ],
          ),
        ),
        _FiltersBar(controller: controller),
        Expanded(
          child: _CollectionBody(
            controller: controller,
            onClearFilters: () => _clearFilters(controller),
          ),
        ),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.controller});

  final ClashCardsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          _FilterMenu<ClashRarity?>(
            label: l10n.clashFilterRarity,
            value: controller.rarityFilter,
            items: [
              _FilterItem(null, l10n.clashFilterAll),
              ...ClashRarity.values.map(
                (r) => _FilterItem(r, r.name.toUpperCase()),
              ),
            ],
            onChanged: controller.setRarityFilter,
          ),
          const SizedBox(width: 8),
          _FilterMenu<ClashPosition?>(
            label: l10n.clashFilterPosition,
            value: controller.positionFilter,
            items: [
              _FilterItem(null, l10n.clashFilterAll),
              ...ClashPosition.values.map(
                (p) => _FilterItem(p, p.displayNameEs),
              ),
            ],
            onChanged: controller.setPositionFilter,
          ),
          const SizedBox(width: 8),
          _FilterMenu<ClashPlayerStyle?>(
            label: l10n.clashFilterStyle,
            value: controller.styleFilter,
            items: [
              _FilterItem(null, l10n.clashFilterAll),
              ...ClashPlayerStyle.values.map(
                (s) => _FilterItem(s, s.displayNameEs),
              ),
            ],
            onChanged: controller.setStyleFilter,
          ),
          const SizedBox(width: 8),
          _FilterMenu<ClashCardSortField>(
            label: l10n.clashSortLabel,
            value: controller.sortField,
            items: [
              _FilterItem(ClashCardSortField.power, l10n.clashSortPower),
              _FilterItem(ClashCardSortField.level, l10n.clashSortLevel),
              _FilterItem(ClashCardSortField.name, l10n.clashSortName),
            ],
            onChanged: controller.setSortField,
          ),
          IconButton(
            onPressed: controller.toggleSortDirection,
            icon: Icon(
              controller.sortDescending
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
            ),
            tooltip: l10n.clashSortDirection,
          ),
        ],
      ),
    );
  }
}

class _FilterItem<T> {
  const _FilterItem(this.value, this.label);

  final T value;
  final String label;
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_FilterItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );
    final isActive = selected.value != items.first.value;

    return PopupMenuButton<T>(
      onSelected: onChanged,
      itemBuilder: (context) => items
          .map(
            (item) =>
                PopupMenuItem<T>(value: item.value, child: Text(item.label)),
          )
          .toList(),
      child: Chip(
        label: Text('$label: ${selected.label}'),
        visualDensity: VisualDensity.compact,
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
    );
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({
    required this.controller,
    required this.onClearFilters,
  });

  final ClashCardsController controller;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    switch (controller.state) {
      case ClashCardsLoadState.idle:
      case ClashCardsLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case ClashCardsLoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              controller.errorMessage ?? l10n.clashCollectionLoadError,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case ClashCardsLoadState.ready:
        final cards = controller.visibleCards;
        if (cards.isEmpty) {
          return ClashCollectionEmptyState(
            controller: controller,
            onClearFilters: onClearFilters,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final entry = cards[index];
            return ClashCardTile(
              entry: entry,
              onTap: () => context.push(AppRoutes.clashCardDetail(entry.id)),
            );
          },
        );
    }
  }
}

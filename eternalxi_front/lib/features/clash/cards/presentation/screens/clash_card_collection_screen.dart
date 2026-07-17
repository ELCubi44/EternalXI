import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
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

  Future<void> _openFilters(ClashCardsController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: XiColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return ChangeNotifierProvider<ClashCardsController>.value(
          value: controller,
          child: const _CollectionFilterSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashCardsController>();
    final topInset = MediaQuery.paddingOf(context).top;
    final filtersActive = controller.rarityFilter != null ||
        controller.positionFilter != null ||
        controller.positionGroupFilter != null ||
        controller.styleFilter != null ||
        controller.teamFilter != null;

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
                  tooltip: l10n.clashFilterRarity,
                  onPressed: () => _openFilters(controller),
                  icon: Badge(
                    isLabelVisible: filtersActive,
                    smallSize: 8,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
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

class _CollectionFilterSheet extends StatelessWidget {
  const _CollectionFilterSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashCardsController>();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _XiFilterPanel(
                      title: l10n.clashSortLabel,
                      trailing: _XiTextChip(
                        label: controller.sortDescending
                            ? 'Descendente'
                            : 'Ascendente',
                        selected: true,
                        dense: true,
                        onTap: controller.toggleSortDirection,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _XiTextChip(
                            label: l10n.clashSortPower,
                            selected: controller.sortField ==
                                ClashCardSortField.power,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.power,
                            ),
                          ),
                          _XiTextChip(
                            label: l10n.clashSortLevel,
                            selected: controller.sortField ==
                                ClashCardSortField.level,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.level,
                            ),
                          ),
                          _XiTextChip(
                            label: l10n.clashFilterRarity,
                            selected: controller.sortField ==
                                ClashCardSortField.rarity,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.rarity,
                            ),
                          ),
                          _XiTextChip(
                            label: l10n.clashSortName,
                            selected: controller.sortField ==
                                ClashCardSortField.name,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.name,
                            ),
                          ),
                          _XiTextChip(
                            label: l10n.clashFilterPosition,
                            selected: controller.sortField ==
                                ClashCardSortField.position,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.position,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _XiFilterPanel(
                      title: 'Filtros',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _XiSectionCaption(l10n.clashFilterPosition),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _XiTextChip(
                                label: l10n.clashFilterAll,
                                selected:
                                    controller.positionGroupFilter == null &&
                                        controller.positionFilter == null,
                                onTap: () {
                                  controller.setPositionGroupFilter(null);
                                  controller.setPositionFilter(null);
                                },
                              ),
                              ...ClashPositionGroup.values.map((group) {
                                final selected =
                                    controller.positionGroupFilter == group &&
                                        controller.positionFilter == null;
                                final groupActive = selected ||
                                    (controller.positionFilter != null &&
                                        controller.positionFilter!.group ==
                                            group);
                                return _XiTextChip(
                                  label: group.displayNameEs,
                                  selected: groupActive,
                                  onTap: () =>
                                      controller.setPositionGroupFilter(
                                    selected ? null : group,
                                  ),
                                );
                              }),
                            ],
                          ),
                          if (controller.positionGroupFilter != null &&
                              controller.positionGroupFilter!.positions
                                      .length >
                                  1) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _XiTextChip(
                                  label: 'Todas',
                                  selected: controller.positionFilter == null,
                                  onTap: () =>
                                      controller.setPositionFilter(null),
                                ),
                                ...controller.positionGroupFilter!.positions
                                    .map((pos) {
                                  return _XiTextChip(
                                    label: pos.displayNameEs,
                                    selected:
                                        controller.positionFilter == pos,
                                    onTap: () =>
                                        controller.setPositionFilter(
                                      controller.positionFilter == pos
                                          ? null
                                          : pos,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          _XiSectionCaption(l10n.clashFilterStyle),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _XiTextChip(
                                label: l10n.clashFilterAll,
                                selected: controller.styleFilter == null,
                                onTap: () =>
                                    controller.setStyleFilter(null),
                              ),
                              ...ClashPlayerStyle.values.map((style) {
                                return _XiTextChip(
                                  label: style.displayNameEs,
                                  selected:
                                      controller.styleFilter == style,
                                  onTap: () => controller.setStyleFilter(
                                    controller.styleFilter == style
                                        ? null
                                        : style,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _XiSectionCaption(l10n.clashFilterRarity),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _XiTextChip(
                                label: l10n.clashFilterAll,
                                selected: controller.rarityFilter == null,
                                onTap: () =>
                                    controller.setRarityFilter(null),
                              ),
                              ...ClashRarity.values.map((rarity) {
                                return _XiIconChip(
                                  selected:
                                      controller.rarityFilter == rarity,
                                  asset:
                                      ClashEpicAssets.rarityIcon(rarity),
                                  semanticsLabel: rarity.name.toUpperCase(),
                                  onTap: () => controller.setRarityFilter(
                                    controller.rarityFilter == rarity
                                        ? null
                                        : rarity,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _XiSectionCaption('Equipo'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _XiTextChip(
                                label: l10n.clashFilterAll,
                                selected: controller.teamFilter == null,
                                onTap: () =>
                                    controller.setTeamFilter(null),
                              ),
                              ...ClashEpicAssets.clashTeamNames.map((team) {
                                final crest =
                                    ClashEpicAssets.teamCrestAsset(team);
                                if (crest == null) {
                                  return _XiTextChip(
                                    label: team,
                                    selected:
                                        controller.teamFilter == team,
                                    onTap: () => controller.setTeamFilter(
                                      controller.teamFilter == team
                                          ? null
                                          : team,
                                    ),
                                  );
                                }
                                return _XiIconChip(
                                  selected:
                                      controller.teamFilter == team,
                                  asset: crest,
                                  semanticsLabel: team,
                                  size: 50,
                                  onTap: () => controller.setTeamFilter(
                                    controller.teamFilter == team
                                        ? null
                                        : team,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: XiColors.royalBlue,
                      foregroundColor: XiColors.warmWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Listo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: controller.clearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: XiColors.warmWhite,
                      side: BorderSide(
                        color: XiColors.classicGold.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _XiFilterPanel extends StatelessWidget {
  const _XiFilterPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: XiColors.classicGold.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: XiColors.classicGold,
                          letterSpacing: 0.4,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _XiSectionCaption extends StatelessWidget {
  const _XiSectionCaption(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: XiColors.iceBlue.withValues(alpha: 0.92),
            letterSpacing: 0.3,
          ),
    );
  }
}

class _XiTextChip extends StatelessWidget {
  const _XiTextChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? XiColors.royalBlue.withValues(alpha: 0.42)
          : XiColors.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 14,
            vertical: dense ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? XiColors.classicGold
                  : Colors.white.withValues(alpha: 0.14),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: dense ? 12 : 13,
              color: XiColors.warmWhite,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _XiIconChip extends StatelessWidget {
  const _XiIconChip({
    required this.selected,
    required this.asset,
    required this.onTap,
    required this.semanticsLabel,
    this.size = 46,
  });

  final bool selected;
  final String asset;
  final VoidCallback onTap;
  final String semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      selected: selected,
      child: Material(
        color: selected
            ? XiColors.royalBlue.withValues(alpha: 0.35)
            : XiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? XiColors.classicGold
                    : Colors.white.withValues(alpha: 0.14),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
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

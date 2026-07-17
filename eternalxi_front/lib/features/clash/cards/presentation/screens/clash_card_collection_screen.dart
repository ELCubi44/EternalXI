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
      backgroundColor: const Color(0xFF1A1C22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: Colors.white70, width: 1.2),
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

  static const _labelOrange = Color(0xFFF0A020);
  static const _selectedGreen = Color(0xFF3CB43C);
  static const _okOrange = Color(0xFFF47A24);
  static const _metal = Color(0xFF3A3F4A);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashCardsController>();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, bottom + 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // —— ORDEN (arriba, texto) ——
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.clashSortLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                          ),
                          _DokkanTextChip(
                            label: controller.sortDescending
                                ? '⬇️ Descendente'
                                : '⬆️ Ascendente',
                            selected: true,
                            selectedColor: const Color(0xFF4A6FA5),
                            onTap: controller.toggleSortDirection,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _DokkanTextGrid(
                        children: [
                          _DokkanTextChip(
                            label: l10n.clashSortPower,
                            selected:
                                controller.sortField == ClashCardSortField.power,
                            selectedColor: _selectedGreen,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.power,
                            ),
                          ),
                          _DokkanTextChip(
                            label: l10n.clashSortLevel,
                            selected:
                                controller.sortField == ClashCardSortField.level,
                            selectedColor: _selectedGreen,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.level,
                            ),
                          ),
                          _DokkanTextChip(
                            label: l10n.clashFilterRarity,
                            selected: controller.sortField ==
                                ClashCardSortField.rarity,
                            selectedColor: _selectedGreen,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.rarity,
                            ),
                          ),
                          _DokkanTextChip(
                            label: l10n.clashSortName,
                            selected:
                                controller.sortField == ClashCardSortField.name,
                            selectedColor: _selectedGreen,
                            onTap: () => controller.setSortField(
                              ClashCardSortField.name,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white54, height: 1),
                      const SizedBox(height: 10),

                      // —— FILTROS ——
                      Text(
                        'Filtros',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.6,
                            ),
                      ),
                      const SizedBox(height: 12),

                      _DokkanSectionLabel(
                        label: l10n.clashFilterPosition,
                        color: _labelOrange,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _DokkanTextChip(
                            label: l10n.clashFilterAll,
                            selected: controller.positionGroupFilter == null &&
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
                                    controller.positionFilter!.group == group);
                            return _DokkanTextChip(
                              label: group.displayNameEs,
                              selected: groupActive,
                              onTap: () => controller.setPositionGroupFilter(
                                selected ? null : group,
                              ),
                            );
                          }),
                        ],
                      ),
                      if (controller.positionGroupFilter != null &&
                          controller
                                  .positionGroupFilter!.positions.length >
                              1) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _DokkanTextChip(
                              label: 'Todas',
                              selected: controller.positionFilter == null,
                              onTap: () =>
                                  controller.setPositionFilter(null),
                            ),
                            ...controller.positionGroupFilter!.positions
                                .map((pos) {
                              return _DokkanTextChip(
                                label: pos.displayNameEs,
                                selected: controller.positionFilter == pos,
                                onTap: () => controller.setPositionFilter(
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
                      _DokkanSectionLabel(
                        label: l10n.clashFilterStyle,
                        color: _labelOrange,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _DokkanTextChip(
                            label: l10n.clashFilterAll,
                            selected: controller.styleFilter == null,
                            onTap: () => controller.setStyleFilter(null),
                          ),
                          ...ClashPlayerStyle.values.map((style) {
                            return _DokkanTextChip(
                              label: style.displayNameEs,
                              selected: controller.styleFilter == style,
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
                      _DokkanSectionLabel(
                        label: l10n.clashFilterRarity,
                        color: _labelOrange,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _DokkanTextChip(
                            label: l10n.clashFilterAll,
                            selected: controller.rarityFilter == null,
                            onTap: () => controller.setRarityFilter(null),
                          ),
                          ...ClashRarity.values.map((rarity) {
                            return _DokkanIconChip(
                              selected: controller.rarityFilter == rarity,
                              asset: ClashEpicAssets.rarityIcon(rarity),
                              tooltip: rarity.name.toUpperCase(),
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
                      _DokkanSectionLabel(
                        label: 'Equipo',
                        color: _labelOrange,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _DokkanTextChip(
                            label: l10n.clashFilterAll,
                            selected: controller.teamFilter == null,
                            onTap: () => controller.setTeamFilter(null),
                          ),
                          ...ClashEpicAssets.clashTeamNames.map((team) {
                            final crest =
                                ClashEpicAssets.teamCrestAsset(team);
                            if (crest == null) {
                              return _DokkanTextChip(
                                label: team,
                                selected: controller.teamFilter == team,
                                onTap: () => controller.setTeamFilter(
                                  controller.teamFilter == team
                                      ? null
                                      : team,
                                ),
                              );
                            }
                            return _DokkanIconChip(
                              selected: controller.teamFilter == team,
                              asset: crest,
                              tooltip: team,
                              size: 48,
                              onTap: () => controller.setTeamFilter(
                                controller.teamFilter == team ? null : team,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Material(
                      color: _okOrange,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'OK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Material(
                      color: _metal,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: controller.clearFilters,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Quitar todo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DokkanSectionLabel extends StatelessWidget {
  const _DokkanSectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 13,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _DokkanTextGrid extends StatelessWidget {
  const _DokkanTextGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 3;
        const gap = 6.0;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: w, child: child),
          ],
        );
      },
    );
  }
}

class _DokkanTextChip extends StatelessWidget {
  const _DokkanTextChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = XiColors.royalBlue,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : const Color(0xFF3A3F4A),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(
          color: selected
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.white24,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DokkanIconChip extends StatelessWidget {
  const _DokkanIconChip({
    required this.selected,
    required this.asset,
    required this.onTap,
    this.tooltip,
    this.size = 44,
  });

  final bool selected;
  final String asset;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: selected
          ? XiColors.royalBlue.withValues(alpha: 0.55)
          : const Color(0xFF3A3F4A),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(
          color: selected
              ? XiColors.classicGold.withValues(alpha: 0.9)
              : Colors.white24,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) {
      return chip;
    }
    return Tooltip(message: tooltip!, child: chip);
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

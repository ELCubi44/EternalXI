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
      showDragHandle: true,
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                    },
                    child: Text(l10n.clashFilterAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SectionTitle(emoji: '📍', label: l10n.clashFilterPosition),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EmojiChoiceChip(
                    selected: controller.positionGroupFilter == null &&
                        controller.positionFilter == null,
                    label: '✨',
                    tooltip: l10n.clashFilterAll,
                    onTap: () {
                      controller.setPositionGroupFilter(null);
                      controller.setPositionFilter(null);
                    },
                  ),
                  ...ClashPositionGroup.values.map((group) {
                    final selected = controller.positionGroupFilter == group &&
                        controller.positionFilter == null;
                    return _EmojiChoiceChip(
                      selected: selected ||
                          (controller.positionFilter != null &&
                              controller.positionFilter!.group == group),
                      label: group.emoji,
                      tooltip: group.displayNameEs,
                      onTap: () => controller.setPositionGroupFilter(
                        selected ? null : group,
                      ),
                    );
                  }),
                ],
              ),
              if (controller.positionGroupFilter != null &&
                  controller.positionGroupFilter!.positions.length > 1) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _EmojiChoiceChip(
                      selected: controller.positionFilter == null,
                      label: '✨',
                      tooltip: controller.positionGroupFilter!.displayNameEs,
                      onTap: () => controller.setPositionFilter(null),
                    ),
                    ...controller.positionGroupFilter!.positions.map((pos) {
                      return _IconChoiceChip(
                        selected: controller.positionFilter == pos,
                        asset: ClashEpicAssets.positionIcon(pos),
                        tooltip: pos.displayNameEs,
                        onTap: () => controller.setPositionFilter(
                          controller.positionFilter == pos ? null : pos,
                        ),
                      );
                    }),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _SectionTitle(emoji: '🎭', label: l10n.clashFilterStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EmojiChoiceChip(
                    selected: controller.styleFilter == null,
                    label: '✨',
                    tooltip: l10n.clashFilterAll,
                    onTap: () => controller.setStyleFilter(null),
                  ),
                  ...ClashPlayerStyle.values.map((style) {
                    return _EmojiChoiceChip(
                      selected: controller.styleFilter == style,
                      label: style.emoji,
                      tooltip: style.displayNameEs,
                      onTap: () => controller.setStyleFilter(
                        controller.styleFilter == style ? null : style,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(emoji: '💎', label: l10n.clashFilterRarity),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EmojiChoiceChip(
                    selected: controller.rarityFilter == null,
                    label: '✨',
                    tooltip: l10n.clashFilterAll,
                    onTap: () => controller.setRarityFilter(null),
                  ),
                  ...ClashRarity.values.map((rarity) {
                    return _IconChoiceChip(
                      selected: controller.rarityFilter == rarity,
                      asset: ClashEpicAssets.rarityIcon(rarity),
                      tooltip: rarity.name.toUpperCase(),
                      onTap: () => controller.setRarityFilter(
                        controller.rarityFilter == rarity ? null : rarity,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(emoji: '🏟️', label: 'Equipo'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EmojiChoiceChip(
                    selected: controller.teamFilter == null,
                    label: '✨',
                    tooltip: l10n.clashFilterAll,
                    onTap: () => controller.setTeamFilter(null),
                  ),
                  ...controller.ownedTeams.map((team) {
                    return _TextChoiceChip(
                      selected: controller.teamFilter == team,
                      label: team,
                      onTap: () => controller.setTeamFilter(
                        controller.teamFilter == team ? null : team,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(emoji: '↕️', label: l10n.clashSortLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EmojiChoiceChip(
                    selected: controller.sortField == ClashCardSortField.power,
                    label: '⚡',
                    tooltip: l10n.clashSortPower,
                    onTap: () =>
                        controller.setSortField(ClashCardSortField.power),
                  ),
                  _EmojiChoiceChip(
                    selected: controller.sortField == ClashCardSortField.level,
                    label: '📶',
                    tooltip: l10n.clashSortLevel,
                    onTap: () =>
                        controller.setSortField(ClashCardSortField.level),
                  ),
                  _EmojiChoiceChip(
                    selected: controller.sortField == ClashCardSortField.rarity,
                    label: '💎',
                    tooltip: l10n.clashFilterRarity,
                    onTap: () =>
                        controller.setSortField(ClashCardSortField.rarity),
                  ),
                  _EmojiChoiceChip(
                    selected: controller.sortField == ClashCardSortField.name,
                    label: '🔤',
                    tooltip: l10n.clashSortName,
                    onTap: () =>
                        controller.setSortField(ClashCardSortField.name),
                  ),
                  _EmojiChoiceChip(
                    selected: false,
                    label: controller.sortDescending ? '⬇️' : '⬆️',
                    tooltip: l10n.clashSortDirection,
                    onTap: controller.toggleSortDirection,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Listo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$emoji  $label',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: XiColors.warmWhite.withValues(alpha: 0.9),
          ),
    );
  }
}

class _EmojiChoiceChip extends StatelessWidget {
  const _EmojiChoiceChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.tooltip,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.black.withValues(alpha: 0.28),
          border: Border.all(
            color: selected
                ? XiColors.classicGold.withValues(alpha: 0.85)
                : Colors.white24,
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
    );
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}

class _IconChoiceChip extends StatelessWidget {
  const _IconChoiceChip({
    required this.selected,
    required this.asset,
    required this.onTap,
    this.tooltip,
  });

  final bool selected;
  final String asset;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.black.withValues(alpha: 0.28),
          border: Border.all(
            color: selected
                ? XiColors.classicGold.withValues(alpha: 0.85)
                : Colors.white24,
          ),
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}

class _TextChoiceChip extends StatelessWidget {
  const _TextChoiceChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.black.withValues(alpha: 0.28),
          border: Border.all(
            color: selected
                ? XiColors.classicGold.withValues(alpha: 0.85)
                : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
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

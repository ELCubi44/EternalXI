import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';

enum _PickerListFilter { compatible, all, rarity }

Future<void> showClashLineupCardPicker({
  required BuildContext context,
  required ClashLineupsController controller,
  required ClashPosition slot,
  required Future<void> Function(String? cardId) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _ClashLineupCardPickerSheet(
        controller: controller,
        slot: slot,
        onSelected: (cardId) async {
          Navigator.of(sheetContext).pop();
          await onSelected(cardId);
        },
      );
    },
  );
}

class _ClashLineupCardPickerSheet extends StatefulWidget {
  const _ClashLineupCardPickerSheet({
    required this.controller,
    required this.slot,
    required this.onSelected,
  });

  final ClashLineupsController controller;
  final ClashPosition slot;
  final Future<void> Function(String? cardId) onSelected;

  @override
  State<_ClashLineupCardPickerSheet> createState() =>
      _ClashLineupCardPickerSheetState();
}

class _ClashLineupCardPickerSheetState
    extends State<_ClashLineupCardPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';
  _PickerListFilter _filter = _PickerListFilter.compatible;
  ClashRarity? _rarityFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _blockLabel(ClashLineupPickerBlockLabel reason) {
    final l10n = context.l10n;
    return switch (reason) {
      ClashLineupPickerBlockLabel.wrongPosition =>
        l10n.clashLineupBlockWrongPosition,
      ClashLineupPickerBlockLabel.duplicatePlayer =>
        l10n.clashLineupBlockDuplicatePlayer,
      ClashLineupPickerBlockLabel.alreadyUsed =>
        l10n.clashLineupBlockAlreadyUsed,
    };
  }

  List<ClashCardCatalogEntry> _visibleEntries() {
    var entries = widget.controller.pickerEntries(
      slot: widget.slot,
      searchQuery: _query,
    );

    if (_filter == _PickerListFilter.compatible) {
      entries = entries
          .where(
            (entry) => widget.controller.canPickEntryForPicker(
              slot: widget.slot,
              entry: entry,
            ),
          )
          .toList();
    }

    if (_filter == _PickerListFilter.rarity && _rarityFilter != null) {
      entries = entries
          .where((entry) => entry.effectiveRarity == _rarityFilter)
          .toList();
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = _visibleEntries();
    final ownedEmpty = widget.controller
        .pickerEntries(slot: widget.slot)
        .isEmpty;
    final compatibleCount = widget.controller
        .pickerEntries(slot: widget.slot, searchQuery: _query)
        .where(
          (entry) => widget.controller.canPickEntryForPicker(
            slot: widget.slot,
            entry: entry,
          ),
        )
        .length;
    final hasAssigned =
        widget.controller.selectedLineup?.cardIdFor(widget.slot) != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.clashLineupPickCard(widget.slot.displayNameEs),
                style: theme.textTheme.titleMedium?.copyWith(
                  ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.clashSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.clashLineupPickerCompatible),
                      selected: _filter == _PickerListFilter.compatible,
                      onSelected: (_) => setState(
                        () => _filter = _PickerListFilter.compatible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.clashLineupPickerAll),
                      selected: _filter == _PickerListFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _PickerListFilter.all),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.clashLineupPickerByRarity),
                      selected: _filter == _PickerListFilter.rarity,
                      onSelected: (_) => setState(() {
                        _filter = _PickerListFilter.rarity;
                        _rarityFilter ??= ClashRarity.n;
                      }),
                    ),
                  ],
                ),
              ),
              if (_filter == _PickerListFilter.rarity) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ClashRarity.values
                        .map(
                          (rarity) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(ClashRarityBadge.label(rarity)),
                              selected: _rarityFilter == rarity,
                              onSelected: (_) =>
                                  setState(() => _rarityFilter = rarity),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (hasAssigned)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => widget.onSelected(null),
                    icon: const Icon(Icons.clear_rounded),
                    label: Text(l10n.clashLineupClearSlot),
                  ),
                ),
              Expanded(
                child: ownedEmpty
                    ? Center(
                        child: Text(
                          l10n.clashLineupNoOwnedCards,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.xiTextSecondary,
                          ),
                        ),
                      )
                    : entries.isEmpty
                    ? Center(
                        child: Text(
                          l10n.clashLineupNoCompatibleCards,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.xiTextSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: entries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final block = widget.controller.pickerBlockLabel(
                            slot: widget.slot,
                            entry: entry,
                          );
                          final enabled = block == null;
                          final compatible = widget.controller.canPickEntry(
                            slot: widget.slot,
                            entry: entry,
                          );

                          return _PickerCardTile(
                            entry: entry,
                            enabled: enabled,
                            blockLabel: block == null
                                ? null
                                : _blockLabel(block),
                            compatibilityLabel: compatible
                                ? l10n.clashLineupCardCompatible
                                : l10n.clashLineupCardIncompatible,
                            onTap: enabled
                                ? () => widget.onSelected(entry.id)
                                : null,
                          );
                        },
                      ),
              ),
              if (!ownedEmpty && compatibleCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.clashLineupNoCompatibleCards,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PickerCardTile extends StatelessWidget {
  const _PickerCardTile({
    required this.entry,
    required this.enabled,
    required this.compatibilityLabel,
    required this.onTap,
    this.blockLabel,
  });

  final ClashCardCatalogEntry entry;
  final bool enabled;
  final String compatibilityLabel;
  final String? blockLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rarityColor = ClashRarityBadge.color(entry.effectiveRarity);
    final levelLabel = entry.isMaxLevel
        ? l10n.clashCardMaxLevel
        : l10n.clashCardLevelShort(entry.displayLevel);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: context.xiCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: rarityColor.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ClashRarityBadge(rarity: entry.effectiveRarity),
                          _Tag(text: levelLabel),
                          _Tag(
                            text: l10n.clashCardPowerValue(entry.power),
                            accent: theme.colorScheme.primary,
                          ),
                          _Tag(text: entry.card.position.displayNameEs),
                          _Tag(text: entry.card.style.displayNameEs),
                          _Tag(
                            text: compatibilityLabel,
                            accent: enabled
                                ? Colors.green
                                : theme.colorScheme.error,
                          ),
                        ],
                      ),
                      if (blockLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          blockLabel!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.accent});

  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.xiTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
        ),
      ),
    );
  }
}

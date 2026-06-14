import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_rules.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';

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

  String _blockLabel(ClashLineupAssignBlockReason reason) {
    final l10n = context.l10n;
    return switch (reason) {
      ClashLineupAssignBlockReason.wrongPosition =>
        l10n.clashLineupBlockWrongPosition,
      ClashLineupAssignBlockReason.duplicatePlayer =>
        l10n.clashLineupBlockDuplicatePlayer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = widget.controller.pickerEntries(
      slot: widget.slot,
      searchQuery: _query,
    );
    final compatible = entries
        .where(
          (entry) =>
              widget.controller.canPickEntry(slot: widget.slot, entry: entry),
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => widget.onSelected(null),
                  icon: const Icon(Icons.clear_rounded),
                  label: Text(l10n.clashLineupClearSlot),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final block = widget.controller.pickerBlockReason(
                      slot: widget.slot,
                      entry: entry,
                    );
                    final enabled = block == null;

                    return Opacity(
                      opacity: enabled ? 1 : 0.55,
                      child: Material(
                        color: context.xiCardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.xiDivider),
                        ),
                        child: ListTile(
                          enabled: enabled,
                          onTap: enabled
                              ? () => widget.onSelected(entry.id)
                              : null,
                          title: Text(
                            entry.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            block != null
                                ? _blockLabel(block)
                                : '${entry.card.position.displayNameEs} · ${entry.power} PWR',
                          ),
                          trailing: ClashRarityBadge(rarity: entry.card.rarity),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (compatible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.clashLineupNoCompatibleCards,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

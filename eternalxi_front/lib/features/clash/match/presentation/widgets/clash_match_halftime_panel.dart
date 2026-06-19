import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel de descanso con objetos de partido (Fase 12).
class ClashMatchHalftimePanel extends StatefulWidget {
  const ClashMatchHalftimePanel({super.key});

  @override
  State<ClashMatchHalftimePanel> createState() =>
      _ClashMatchHalftimePanelState();
}

class _ClashMatchHalftimePanelState extends State<ClashMatchHalftimePanel> {
  String? _pendingItemId;
  final Set<int> _selectedPlayers = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final match = context.watch<ClashMatchController>();
    final state = match.state;
    if (state == null || !state.isPausedForHalftime) {
      return const SizedBox.shrink();
    }

    final pendingEntry = _pendingItemId == null
        ? null
        : _entryFor(state, _pendingItemId!);
    final lastResult = state.lastItemEffectResult;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.clashMatchHalftimeTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.clashMatchScoreLabel(state.score.user, state.score.rival),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.clashMatchHalftimeItemsHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.clashMatchHalftimeSquadTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...state.userSquad.map((player) => _SquadRow(player: player)),
            const SizedBox(height: 14),
            Text(
              l10n.clashMatchHalftimeItemsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...state.matchInventory.map(
              (entry) => _ItemTile(
                entry: entry,
                isPending: entry.item.id == _pendingItemId,
                onTap: () => _onItemTap(context, match, state, entry),
              ),
            ),
            if (pendingEntry != null &&
                pendingEntry.item.type.requiresPlayerSelection) ...[
              const SizedBox(height: 12),
              Text(
                l10n.clashMatchHalftimeSelectPlayers(
                  pendingEntry.item.targetCount,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.userSquad.map((player) {
                  final selected = _selectedPlayers.contains(player.index);
                  return FilterChip(
                    label: Text(player.label),
                    selected: selected,
                    onSelected: (_) => _togglePlayer(
                      player.index,
                      pendingEntry.item.type.maxTargets,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _pendingItemId = null;
                        _selectedPlayers.clear();
                      }),
                      child: Text(l10n.clashMatchHalftimeCancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canApplySelection(pendingEntry.item.type)
                          ? () => _applyPending(match)
                          : null,
                      child: Text(l10n.clashMatchHalftimeApplyItem),
                    ),
                  ),
                ],
              ),
            ],
            if (lastResult != null) ...[
              const SizedBox(height: 10),
              Material(
                color: lastResult.used
                    ? Colors.green.withValues(alpha: 0.12)
                    : theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    lastResult.summaryMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: match.continueFromHalftime,
              child: Text(l10n.clashMatchHalftimeContinue),
            ),
          ],
        ),
      ),
    );
  }

  ClashMatchItemInventoryEntry? _entryFor(MatchState state, String itemId) {
    for (final entry in state.matchInventory) {
      if (entry.item.id == itemId) {
        return entry;
      }
    }
    return null;
  }

  void _onItemTap(
    BuildContext context,
    ClashMatchController match,
    MatchState state,
    ClashMatchItemInventoryEntry entry,
  ) {
    if (!entry.isAvailable) {
      return;
    }
    if (!entry.item.type.requiresPlayerSelection) {
      match.useMatchItem(entry.item.id);
      return;
    }
    setState(() {
      _pendingItemId = entry.item.id;
      _selectedPlayers.clear();
    });
  }

  void _togglePlayer(int index, int maxTargets) {
    setState(() {
      if (_selectedPlayers.contains(index)) {
        _selectedPlayers.remove(index);
        return;
      }
      if (_selectedPlayers.length >= maxTargets) {
        return;
      }
      _selectedPlayers.add(index);
    });
  }

  bool _canApplySelection(ClashMatchItemType type) {
    if (type.maxTargets == 1) {
      return _selectedPlayers.length == 1;
    }
    return _selectedPlayers.isNotEmpty && _selectedPlayers.length <= 3;
  }

  void _applyPending(ClashMatchController match) {
    final itemId = _pendingItemId;
    if (itemId == null) {
      return;
    }
    match.useMatchItem(
      itemId,
      targetIndices: _selectedPlayers.toList()..sort(),
    );
    setState(() {
      _pendingItemId = null;
      _selectedPlayers.clear();
    });
  }
}

class _SquadRow extends StatelessWidget {
  const _SquadRow({required this.player});

  final MatchSquadPlayer player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${player.label} · ${player.position.displayNameEs}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            l10n.clashMatchHalftimePtLabel(player.currentPt, player.maxPt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.clashMatchHalftimeStaminaLabel(
              player.currentStamina,
              player.maxStamina,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.entry,
    required this.isPending,
    required this.onTap,
  });

  final ClashMatchItemInventoryEntry entry;
  final bool isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final enabled = entry.isAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          backgroundColor: isPending
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  l10n.clashMatchHalftimeItemQty(entry.quantity),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.item.description),
            Text(
              l10n.clashMatchHalftimeItemEffect(
                entry.item.amount,
                entry.item.targetCount,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

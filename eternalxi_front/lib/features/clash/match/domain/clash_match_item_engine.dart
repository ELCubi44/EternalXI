import 'package:eternal_xi/features/clash/match/domain/clash_match_item.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_effect_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_player_change.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';

/// Aplicación de objetos de partido durante el descanso (Fase 12).
class ClashMatchItemEngine {
  const ClashMatchItemEngine._();

  static ClashMatchItemInventoryEntry? findEntry(
    MatchState state,
    String itemId,
  ) {
    for (final entry in state.matchInventory) {
      if (entry.item.id == itemId) {
        return entry;
      }
    }
    return null;
  }

  static bool canUseDuringHalftime(MatchState state) =>
      state.isHalftime && state.status == MatchStatus.halftime;

  static ClashMatchItemEffectResult preview(
    MatchState state, {
    required String itemId,
    List<int> targetIndices = const [],
  }) {
    return _apply(
      state,
      itemId: itemId,
      targetIndices: targetIndices,
      consumeItem: false,
    );
  }

  static MatchState useItem(
    MatchState state, {
    required String itemId,
    List<int> targetIndices = const [],
  }) {
    if (!canUseDuringHalftime(state)) {
      return state;
    }
    final result = _apply(
      state,
      itemId: itemId,
      targetIndices: targetIndices,
      consumeItem: true,
    );
    if (!result.used) {
      return state.copyWith(lastItemEffectResult: result);
    }

    return state.copyWith(
      userSquad: _applySquadChanges(state.userSquad, result.affectedPlayers),
      matchInventory: _consumeInventory(state.matchInventory, itemId),
      usedItemsLog: [...state.usedItemsLog, result.summaryMessage],
      lastItemEffectResult: result,
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: MatchEventType.halftimeItemUsed,
          message: result.summaryMessage,
        ),
      ],
    );
  }

  static ClashMatchItemEffectResult _apply(
    MatchState state, {
    required String itemId,
    required List<int> targetIndices,
    required bool consumeItem,
  }) {
    final entry = findEntry(state, itemId);
    if (entry == null) {
      return ClashMatchItemEffectResult(
        itemId: itemId,
        itemName: itemId,
        used: false,
        affectedPlayers: const [],
        errorMessage: 'Objeto no encontrado',
      );
    }
    if (!canUseDuringHalftime(state)) {
      return ClashMatchItemEffectResult(
        itemId: itemId,
        itemName: entry.item.name,
        used: false,
        affectedPlayers: const [],
        errorMessage: 'Solo en descanso',
      );
    }
    if (entry.quantity <= 0) {
      return ClashMatchItemEffectResult(
        itemId: itemId,
        itemName: entry.item.name,
        used: false,
        affectedPlayers: const [],
        errorMessage: 'Sin unidades disponibles',
      );
    }

    final indices = _resolveTargets(state, entry.item.type, targetIndices);
    if (indices == null) {
      return ClashMatchItemEffectResult(
        itemId: itemId,
        itemName: entry.item.name,
        used: false,
        affectedPlayers: const [],
        errorMessage: 'Selección de jugadores inválida',
      );
    }

    final changes = <ClashMatchItemPlayerChange>[];
    for (final index in indices) {
      final player = _playerAt(state.userSquad, index);
      if (player == null) {
        continue;
      }
      final change = _applyToPlayer(player, entry.item);
      if (change != null) {
        changes.add(change);
      }
    }

    if (changes.isEmpty) {
      return ClashMatchItemEffectResult(
        itemId: itemId,
        itemName: entry.item.name,
        used: false,
        affectedPlayers: const [],
        errorMessage: 'Ningún jugador puede beneficiarse',
      );
    }

    return ClashMatchItemEffectResult(
      itemId: itemId,
      itemName: entry.item.name,
      used: consumeItem,
      affectedPlayers: changes,
    );
  }

  static List<int>? _resolveTargets(
    MatchState state,
    ClashMatchItemType type,
    List<int> targetIndices,
  ) {
    return switch (type) {
      ClashMatchItemType.recoverPtAllSmall ||
      ClashMatchItemType.recoverStaminaAllSmall =>
        state.userSquad.map((player) => player.index).toList(),
      ClashMatchItemType.recoverPtSingle ||
      ClashMatchItemType.recoverStaminaSingle =>
        targetIndices.length == 1 ? targetIndices : null,
      ClashMatchItemType.recoverPtTriple ||
      ClashMatchItemType.recoverStaminaTriple =>
        targetIndices.isEmpty || targetIndices.length > 3
            ? null
            : targetIndices.take(3).toList(),
    };
  }

  static ClashMatchItemPlayerChange? _applyToPlayer(
    MatchSquadPlayer player,
    ClashMatchItem item,
  ) {
    if (item.type.isPtRecovery) {
      if (player.currentPt >= player.maxPt) {
        return null;
      }
      final after = (player.currentPt + item.amount).clamp(0, player.maxPt);
      if (after == player.currentPt) {
        return null;
      }
      return ClashMatchItemPlayerChange(
        playerIndex: player.index,
        label: player.label,
        beforePt: player.currentPt,
        afterPt: after,
      );
    }

    final maxStamina = player.maxStamina;
    if (player.currentStamina >= maxStamina) {
      return null;
    }
    final after = (player.currentStamina + item.amount).clamp(0, maxStamina);
    if (after == player.currentStamina) {
      return null;
    }
    return ClashMatchItemPlayerChange(
      playerIndex: player.index,
      label: player.label,
      beforeStamina: player.currentStamina,
      afterStamina: after,
    );
  }

  static MatchSquadPlayer? _playerAt(List<MatchSquadPlayer> squad, int index) {
    for (final player in squad) {
      if (player.index == index) {
        return player;
      }
    }
    return null;
  }

  static List<MatchSquadPlayer> _applySquadChanges(
    List<MatchSquadPlayer> squad,
    List<ClashMatchItemPlayerChange> changes,
  ) {
    final byIndex = {for (final change in changes) change.playerIndex: change};
    return squad.map((player) {
      final change = byIndex[player.index];
      if (change == null) {
        return player;
      }
      return player.copyWith(
        currentPt: change.afterPt ?? player.currentPt,
        currentStamina: change.afterStamina ?? player.currentStamina,
      );
    }).toList();
  }

  static List<ClashMatchItemInventoryEntry> _consumeInventory(
    List<ClashMatchItemInventoryEntry> inventory,
    String itemId,
  ) {
    return inventory
        .map(
          (entry) => entry.item.id == itemId
              ? entry.copyWith(quantity: entry.quantity - 1)
              : entry,
        )
        .toList();
  }
}

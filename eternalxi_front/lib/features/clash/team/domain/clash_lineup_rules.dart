import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';

/// Motivo por el que una carta no puede asignarse a un slot.
enum ClashLineupAssignBlockReason { wrongPosition, duplicatePlayer }

/// Reglas puras de validación y potencia para alineaciones 7vs7.
class ClashLineupRules {
  const ClashLineupRules._();

  static bool isPositionCompatible(
    ClashCardCatalogEntry entry,
    ClashPosition slot,
  ) {
    return entry.card.position == slot;
  }

  static bool hasDuplicatePlayerInLineup(
    ClashLineup7v7 lineup,
    int playerId, {
    required Map<String, ClashCardCatalogEntry> catalogById,
    ClashPosition? replacingSlot,
  }) {
    for (final position in ClashLineup7v7.slotOrder) {
      if (replacingSlot != null && position == replacingSlot) {
        continue;
      }
      final cardId = lineup.cardIdFor(position);
      if (cardId == null || cardId.isEmpty) {
        continue;
      }
      final existing = catalogById[cardId];
      if (existing?.playerId == playerId) {
        return true;
      }
    }
    return false;
  }

  static ClashLineupAssignBlockReason? blockReason({
    required ClashLineup7v7 lineup,
    required ClashPosition slot,
    required ClashCardCatalogEntry entry,
    required Map<String, ClashCardCatalogEntry> catalogById,
  }) {
    if (!isPositionCompatible(entry, slot)) {
      return ClashLineupAssignBlockReason.wrongPosition;
    }

    if (hasDuplicatePlayerInLineup(
      lineup,
      entry.playerId,
      catalogById: catalogById,
      replacingSlot: slot,
    )) {
      return ClashLineupAssignBlockReason.duplicatePlayer;
    }

    return null;
  }

  static bool canAssign({
    required ClashLineup7v7 lineup,
    required ClashPosition slot,
    required ClashCardCatalogEntry entry,
    required Map<String, ClashCardCatalogEntry> catalogById,
  }) {
    return blockReason(
          lineup: lineup,
          slot: slot,
          entry: entry,
          catalogById: catalogById,
        ) ==
        null;
  }

  static int calculateTotalPower(
    ClashLineup7v7 lineup,
    Map<String, ClashCardCatalogEntry> catalogById,
  ) {
    var total = 0;
    for (final cardId in lineup.assignedCardIds) {
      total += catalogById[cardId]?.power ?? 0;
    }
    return total;
  }

  static List<ClashLineup7v7> ensureSingleActive(
    List<ClashLineup7v7> lineups,
    String activeId,
  ) {
    return lineups
        .map((lineup) => lineup.copyWith(isActive: lineup.id == activeId))
        .toList(growable: false);
  }
}

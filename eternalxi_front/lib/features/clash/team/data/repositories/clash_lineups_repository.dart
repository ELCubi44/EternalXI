import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_rules.dart';

class ClashLineupOperationException implements Exception {
  ClashLineupOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repositorio de alineaciones 7vs7 Clash (local, sin Fantasy).
class ClashLineupsRepository {
  ClashLineupsRepository({
    required ClashLineupsStorageBackend storage,
    required ClashCardsRepository cardsRepository,
  }) : _storage = storage,
       _cardsRepository = cardsRepository;

  final ClashLineupsStorageBackend _storage;
  final ClashCardsRepository _cardsRepository;

  List<ClashLineup7v7>? _cache;
  Map<String, ClashCardCatalogEntry>? _catalogById;

  Future<List<ClashLineup7v7>> loadLineups() async {
    _cache ??= _normalize(_storage.readLineups());
    return List<ClashLineup7v7>.unmodifiable(_cache!);
  }

  Future<Map<String, ClashCardCatalogEntry>> loadCatalogById() async {
    _catalogById ??= {
      for (final entry in await _cardsRepository.fetchAllCards())
        entry.id: entry,
    };
    return Map<String, ClashCardCatalogEntry>.unmodifiable(_catalogById!);
  }

  Future<List<ClashLineup7v7>> saveLineups(List<ClashLineup7v7> lineups) async {
    final normalized = _normalize(lineups);
    await _storage.writeLineups(normalized);
    _cache = normalized;
    return List<ClashLineup7v7>.unmodifiable(normalized);
  }

  Future<List<ClashLineup7v7>> renameLineup(
    String lineupId,
    String name,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ClashLineupOperationException('El nombre no puede estar vacío');
    }

    final lineups = await loadLineups();
    final updated = lineups
        .map(
          (lineup) => lineup.id == lineupId
              ? lineup.copyWith(name: trimmed, lastModifiedAt: DateTime.now())
              : lineup,
        )
        .toList(growable: false);
    return saveLineups(updated);
  }

  Future<List<ClashLineup7v7>> setActiveLineup(String lineupId) async {
    final lineups = await loadLineups();
    if (!lineups.any((lineup) => lineup.id == lineupId)) {
      throw ClashLineupOperationException('Alineación no encontrada');
    }
    final updated = ClashLineupRules.ensureSingleActive(lineups, lineupId)
        .map(
          (lineup) => lineup.id == lineupId
              ? lineup.copyWith(lastModifiedAt: DateTime.now())
              : lineup,
        )
        .toList(growable: false);
    return saveLineups(updated);
  }

  Future<List<ClashLineup7v7>> assignCard({
    required String lineupId,
    required ClashPosition slot,
    required String? cardId,
  }) async {
    final catalog = await loadCatalogById();
    final lineups = await loadLineups();
    final index = lineups.indexWhere((lineup) => lineup.id == lineupId);
    if (index < 0) {
      throw ClashLineupOperationException('Alineación no encontrada');
    }

    final lineup = lineups[index];
    final nextSlots = Map<ClashPosition, String?>.from(lineup.slots);

    if (cardId == null || cardId.isEmpty) {
      nextSlots[slot] = null;
    } else {
      final entry = catalog[cardId];
      if (entry == null) {
        throw ClashLineupOperationException('Carta no encontrada');
      }
      final block = ClashLineupRules.blockReason(
        lineup: lineup,
        slot: slot,
        entry: entry,
        catalogById: catalog,
      );
      if (block != null) {
        throw ClashLineupOperationException(_blockMessage(block));
      }
      nextSlots[slot] = cardId;
    }

    final updatedLineup = lineup.copyWith(
      slots: nextSlots,
      lastModifiedAt: DateTime.now(),
    );
    final updated = [...lineups]..[index] = updatedLineup;
    return saveLineups(updated);
  }

  List<ClashLineup7v7> _normalize(List<ClashLineup7v7>? stored) {
    final defaults = ClashLineup7v7.createDefaultSet();
    if (stored == null || stored.isEmpty) {
      return defaults;
    }

    final byId = {for (final lineup in stored) lineup.id: lineup};
    final normalized = <ClashLineup7v7>[];
    for (var i = 0; i < ClashLineup7v7.maxLineups; i++) {
      final defaultLineup = defaults[i];
      final existing = byId[defaultLineup.id];
      normalized.add(existing ?? defaultLineup);
    }

    if (!normalized.any((lineup) => lineup.isActive)) {
      normalized[0] = normalized[0].copyWith(isActive: true);
    } else {
      var activeSet = false;
      for (var i = 0; i < normalized.length; i++) {
        if (normalized[i].isActive) {
          if (activeSet) {
            normalized[i] = normalized[i].copyWith(isActive: false);
          } else {
            activeSet = true;
          }
        }
      }
    }

    return normalized;
  }

  String _blockMessage(ClashLineupAssignBlockReason reason) => switch (reason) {
    ClashLineupAssignBlockReason.wrongPosition =>
      'La carta no es compatible con esta posición',
    ClashLineupAssignBlockReason.duplicatePlayer =>
      'Ese jugador ya está en la alineación',
  };

  void clearCacheForTests() {
    _cache = null;
    _catalogById = null;
  }
}

import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Colección de cartas poseídas por el jugador (local, sin backend).
class ClashPlayerCollectionRepository {
  ClashPlayerCollectionRepository({
    required ClashPlayerCollectionStorageBackend storage,
    required ClashCardsRepository cardsRepository,
  }) : _storage = storage,
       _cardsRepository = cardsRepository;

  final ClashPlayerCollectionStorageBackend _storage;
  final ClashCardsRepository _cardsRepository;

  ClashPlayerCollectionSnapshot? _cache;

  ClashPlayerCollectionSnapshot _loadSnapshot() {
    _cache ??= _storage.readSnapshot();
    return _cache!;
  }

  Set<String> loadOwnedCardIds() {
    return Set<String>.from(_loadSnapshot().ownedCardIds);
  }

  Map<String, ClashCardProgress> loadCardProgress() {
    return Map<String, ClashCardProgress>.from(_loadSnapshot().cardProgress);
  }

  ClashCardProgress? progressFor(String cardId) =>
      _loadSnapshot().cardProgress[cardId];

  ClashCardProgress ensureProgress(String cardId) {
    final snapshot = _loadSnapshot();
    final existing = snapshot.cardProgress[cardId];
    if (existing != null) {
      return existing;
    }
    final created = ClashCardXpService.initialProgress(cardId);
    _cache = snapshot.copyWith(
      cardProgress: {...snapshot.cardProgress, cardId: created},
    );
    return created;
  }

  Future<void> grantCardIds(Iterable<String> cardIds) async {
    final owned = loadOwnedCardIds();
    final before = owned.length;
    owned.addAll(cardIds);
    if (owned.length == before) {
      return;
    }
    final progress = loadCardProgress();
    for (final id in cardIds) {
      progress.putIfAbsent(id, () => ClashCardXpService.initialProgress(id));
    }
    await _save(
      _loadSnapshot().copyWith(ownedCardIds: owned, cardProgress: progress),
    );
  }

  Future<List<String>> grantMissingCardIds(Iterable<String> cardIds) async {
    final owned = loadOwnedCardIds();
    final progress = loadCardProgress();
    final newlyGranted = <String>[];
    for (final id in cardIds) {
      if (!owned.contains(id)) {
        owned.add(id);
        progress[id] = ClashCardXpService.initialProgress(id);
        newlyGranted.add(id);
      }
    }
    if (newlyGranted.isNotEmpty) {
      await _save(
        _loadSnapshot().copyWith(ownedCardIds: owned, cardProgress: progress),
      );
    }
    return newlyGranted;
  }

  Future<List<String>> grantEternalXiStarterNCards() async {
    final catalog = await _cardsRepository.fetchAllCards();
    final starterIds = catalog
        .where(
          (entry) =>
              entry.team == 'Eternal XI' && entry.card.rarity == ClashRarity.n,
        )
        .map((entry) => entry.id)
        .toList(growable: false);
    return grantMissingCardIds(starterIds);
  }

  Future<List<ClashCardCatalogEntry>> fetchOwnedCards() async {
    final owned = loadOwnedCardIds();
    if (owned.isEmpty) {
      return const [];
    }
    final catalog = await _cardsRepository.fetchAllCards();
    final progress = loadCardProgress();
    return catalog
        .where((entry) => owned.contains(entry.id))
        .map(
          (entry) => entry.withProgress(
            progress[entry.id] ?? ClashCardXpService.initialProgress(entry.id),
          ),
        )
        .toList(growable: false);
  }

  ClashCardCatalogEntry enrichEntry(ClashCardCatalogEntry entry) {
    final progress =
        progressFor(entry.id) ?? ClashCardXpService.initialProgress(entry.id);
    return entry.withProgress(progress);
  }

  Map<String, ClashCardCatalogEntry> enrichCatalog(
    Map<String, ClashCardCatalogEntry> catalogById,
  ) {
    return catalogById.map((key, entry) => MapEntry(key, enrichEntry(entry)));
  }

  /// Concede EXP de partido a cartas de la alineación (solo victoria).
  Future<List<ClashCardXpResult>> grantMatchXp({
    required Iterable<String> cardIds,
    required int xpPerCard,
  }) async {
    if (xpPerCard <= 0 || cardIds.isEmpty) {
      return const [];
    }

    final snapshot = _loadSnapshot();
    var progressMap = Map<String, ClashCardProgress>.from(
      snapshot.cardProgress,
    );
    final results = <ClashCardXpResult>[];

    for (final cardId in cardIds) {
      if (!snapshot.ownedCardIds.contains(cardId)) {
        continue;
      }
      final entry = await _cardsRepository.findById(cardId);
      if (entry == null) {
        continue;
      }

      final current =
          progressMap[cardId] ?? ClashCardXpService.initialProgress(cardId);
      final result = ClashCardXpService.applyXp(
        progress: current,
        rarity: entry.card.rarity,
        cardName: entry.name,
        xpAmount: xpPerCard,
      );
      progressMap[cardId] = ClashCardXpService.progressAfterResult(
        current,
        result,
      );
      results.add(result);
    }

    if (results.isNotEmpty) {
      await _save(snapshot.copyWith(cardProgress: progressMap));
    }

    return results;
  }

  /// Calcula EXP de partido sin persistir (preview en fin de partido).
  Future<List<ClashCardXpResult>> previewMatchXp({
    required Iterable<String> cardIds,
    required int xpPerCard,
  }) async {
    if (xpPerCard <= 0 || cardIds.isEmpty) {
      return const [];
    }

    final owned = loadOwnedCardIds();
    final progressMap = loadCardProgress();
    final results = <ClashCardXpResult>[];

    for (final cardId in cardIds) {
      if (!owned.contains(cardId)) {
        continue;
      }
      final entry = await _cardsRepository.findById(cardId);
      if (entry == null) {
        continue;
      }
      final current =
          progressMap[cardId] ?? ClashCardXpService.initialProgress(cardId);
      results.add(
        ClashCardXpService.applyXp(
          progress: current,
          rarity: entry.card.rarity,
          cardName: entry.name,
          xpAmount: xpPerCard,
        ),
      );
    }

    return results;
  }

  /// Preview sincrónico para UI de fin de partido.
  List<ClashCardXpResult> previewMatchXpSync({
    required Iterable<String> cardIds,
    required int xpPerCard,
    required Map<String, ClashCardCatalogEntry> catalogById,
  }) {
    if (xpPerCard <= 0 || cardIds.isEmpty) {
      return const [];
    }

    final owned = loadOwnedCardIds();
    final results = <ClashCardXpResult>[];

    for (final cardId in cardIds) {
      if (!owned.contains(cardId)) {
        continue;
      }
      final entry = catalogById[cardId];
      if (entry == null) {
        continue;
      }
      final current =
          entry.progress ?? ClashCardXpService.initialProgress(cardId);
      results.add(
        ClashCardXpService.applyXp(
          progress: current,
          rarity: entry.card.rarity,
          cardName: entry.name,
          xpAmount: xpPerCard,
        ),
      );
    }

    return results;
  }

  bool ownsCard(String cardId) => loadOwnedCardIds().contains(cardId);

  Future<void> _save(ClashPlayerCollectionSnapshot snapshot) async {
    _cache = snapshot;
    await _storage.writeSnapshot(snapshot);
  }

  void clearCacheForTests() => _cache = null;
}

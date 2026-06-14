import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
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

  Set<String>? _cache;

  Set<String> loadOwnedCardIds() {
    _cache ??= _storage.readOwnedCardIds();
    return Set<String>.from(_cache!);
  }

  Future<Set<String>> grantCardIds(Iterable<String> cardIds) async {
    final owned = loadOwnedCardIds();
    final before = owned.length;
    owned.addAll(cardIds);
    if (owned.length == before) {
      return const {};
    }
    await _save(owned);
    final granted = <String>{};
    for (final id in cardIds) {
      if (owned.contains(id)) {
        granted.add(id);
      }
    }
    return granted;
  }

  Future<List<String>> grantMissingCardIds(Iterable<String> cardIds) async {
    final owned = loadOwnedCardIds();
    final newlyGranted = <String>[];
    for (final id in cardIds) {
      if (!owned.contains(id)) {
        owned.add(id);
        newlyGranted.add(id);
      }
    }
    if (newlyGranted.isNotEmpty) {
      await _save(owned);
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
    return catalog
        .where((entry) => owned.contains(entry.id))
        .toList(growable: false);
  }

  bool ownsCard(String cardId) => loadOwnedCardIds().contains(cardId);

  Future<void> _save(Set<String> owned) async {
    _cache = Set<String>.from(owned);
    await _storage.writeOwnedCardIds(_cache!);
  }

  void clearCacheForTests() => _cache = null;
}

import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

enum ClashCardSortField { power, level, name }

/// Repositorio local de cartas Clash (sin backend ni Fantasy).
class ClashCardsRepository {
  ClashCardsRepository(this._dataSource);

  final ClashCardsLocalDataSource _dataSource;

  List<ClashCardCatalogEntry>? _cache;

  Future<List<ClashCardCatalogEntry>> fetchAllCards() async {
    _cache ??= await _dataSource.loadCards();
    return List<ClashCardCatalogEntry>.unmodifiable(_cache!);
  }

  Future<ClashCardCatalogEntry?> findById(String cardId) async {
    final cards = await fetchAllCards();
    for (final entry in cards) {
      if (entry.id == cardId) {
        return entry;
      }
    }
    return null;
  }

  /// Filtra y ordena cartas en memoria.
  List<ClashCardCatalogEntry> filterAndSort({
    required List<ClashCardCatalogEntry> cards,
    String searchQuery = '',
    ClashRarity? rarity,
    ClashPosition? position,
    ClashPlayerStyle? style,
    ClashCardSortField sortField = ClashCardSortField.power,
    bool descending = true,
  }) {
    final query = searchQuery.trim().toLowerCase();
    var result = cards.where((entry) {
      if (query.isNotEmpty && !entry.name.toLowerCase().contains(query)) {
        return false;
      }
      if (rarity != null && entry.effectiveRarity != rarity) {
        return false;
      }
      if (position != null && entry.card.position != position) {
        return false;
      }
      if (style != null && entry.card.style != style) {
        return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      final cmp = switch (sortField) {
        ClashCardSortField.power => a.power.compareTo(b.power),
        ClashCardSortField.level => a.displayLevel.compareTo(b.displayLevel),
        ClashCardSortField.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
      };
      return descending ? -cmp : cmp;
    });

    return result;
  }

  /// Expuesto para tests: invalida caché.
  void clearCacheForTests() => _cache = null;
}

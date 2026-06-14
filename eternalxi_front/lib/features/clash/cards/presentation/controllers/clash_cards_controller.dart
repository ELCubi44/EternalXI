import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:flutter/foundation.dart';

enum ClashCardsLoadState { idle, loading, ready, error }

/// Estado de la colección de cartas Clash.
class ClashCardsController extends ChangeNotifier {
  ClashCardsController(this._repository, this._collectionRepository);

  final ClashCardsRepository _repository;
  final ClashPlayerCollectionRepository _collectionRepository;

  ClashCardsLoadState _state = ClashCardsLoadState.idle;
  String? _errorMessage;
  List<ClashCardCatalogEntry> _allCards = const [];
  List<ClashCardCatalogEntry> _visibleCards = const [];

  String _searchQuery = '';
  ClashRarity? _rarityFilter;
  ClashPosition? _positionFilter;
  ClashPlayerStyle? _styleFilter;
  ClashCardSortField _sortField = ClashCardSortField.power;
  bool _sortDescending = true;

  ClashCardsLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ClashCardCatalogEntry> get visibleCards => _visibleCards;
  String get searchQuery => _searchQuery;
  ClashRarity? get rarityFilter => _rarityFilter;
  ClashPosition? get positionFilter => _positionFilter;
  ClashPlayerStyle? get styleFilter => _styleFilter;
  ClashCardSortField get sortField => _sortField;
  bool get sortDescending => _sortDescending;

  Future<void> load() async {
    if (_state == ClashCardsLoadState.loading) {
      return;
    }
    _state = ClashCardsLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allCards = await _collectionRepository.fetchOwnedCards();
      _applyFilters();
      _state = ClashCardsLoadState.ready;
    } catch (error) {
      _state = ClashCardsLoadState.error;
      _errorMessage = error.toString();
      _visibleCards = const [];
    }
    notifyListeners();
  }

  Future<void> reloadOwnedCards() async {
    _allCards = await _collectionRepository.fetchOwnedCards();
    _applyFilters();
    notifyListeners();
  }

  Future<ClashCardCatalogEntry?> findCard(String cardId) {
    return _repository.findById(cardId);
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _applyFilters();
    notifyListeners();
  }

  void setRarityFilter(ClashRarity? rarity) {
    _rarityFilter = rarity;
    _applyFilters();
    notifyListeners();
  }

  void setPositionFilter(ClashPosition? position) {
    _positionFilter = position;
    _applyFilters();
    notifyListeners();
  }

  void setStyleFilter(ClashPlayerStyle? style) {
    _styleFilter = style;
    _applyFilters();
    notifyListeners();
  }

  void setSortField(ClashCardSortField field) {
    _sortField = field;
    _applyFilters();
    notifyListeners();
  }

  void toggleSortDirection() {
    _sortDescending = !_sortDescending;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_allCards.isEmpty) {
      _visibleCards = const [];
      return;
    }
    _visibleCards = _repository.filterAndSort(
      cards: _allCards,
      searchQuery: _searchQuery,
      rarity: _rarityFilter,
      position: _positionFilter,
      style: _styleFilter,
      sortField: _sortField,
      descending: _sortDescending,
    );
  }
}

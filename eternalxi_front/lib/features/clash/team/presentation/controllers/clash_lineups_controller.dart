import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_rules.dart';
import 'package:flutter/foundation.dart';

enum ClashLineupsLoadState { idle, loading, ready, error }

/// Estado de alineaciones 7vs7 Clash.
class ClashLineupsController extends ChangeNotifier {
  ClashLineupsController({
    required ClashLineupsRepository lineupsRepository,
    required ClashPlayerCollectionRepository collectionRepository,
  }) : _lineupsRepository = lineupsRepository,
       _collectionRepository = collectionRepository;

  final ClashLineupsRepository _lineupsRepository;
  final ClashPlayerCollectionRepository _collectionRepository;

  ClashLineupsLoadState _state = ClashLineupsLoadState.idle;
  String? _errorMessage;
  List<ClashLineup7v7> _lineups = const [];
  Map<String, ClashCardCatalogEntry> _catalogById = const {};
  int _selectedIndex = 0;

  ClashLineupsLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ClashLineup7v7> get lineups => _lineups;
  int get selectedIndex => _selectedIndex;

  ClashLineup7v7? get selectedLineup =>
      _lineups.isEmpty ? null : _lineups[_selectedIndex];

  Map<String, ClashCardCatalogEntry> get catalogById => _catalogById;

  Future<void> load() async {
    if (_state == ClashLineupsLoadState.loading) {
      return;
    }
    _state = ClashLineupsLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _catalogById = await _lineupsRepository.loadCatalogById();
      _lineups = await _lineupsRepository.loadLineups();
      _selectedIndex = _lineups.indexWhere((lineup) => lineup.isActive);
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      _state = ClashLineupsLoadState.ready;
    } catch (error) {
      _state = ClashLineupsLoadState.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void selectLineupIndex(int index) {
    if (index < 0 || index >= _lineups.length || index == _selectedIndex) {
      return;
    }
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> renameSelectedLineup(String name) async {
    final lineup = selectedLineup;
    if (lineup == null) {
      return;
    }
    _lineups = await _lineupsRepository.renameLineup(lineup.id, name);
    notifyListeners();
  }

  Future<void> setSelectedAsActive() async {
    final lineup = selectedLineup;
    if (lineup == null || lineup.isActive) {
      return;
    }
    _lineups = await _lineupsRepository.setActiveLineup(lineup.id);
    notifyListeners();
  }

  Future<void> assignCard({
    required ClashPosition slot,
    required String? cardId,
  }) async {
    final lineup = selectedLineup;
    if (lineup == null) {
      return;
    }
    _lineups = await _lineupsRepository.assignCard(
      lineupId: lineup.id,
      slot: slot,
      cardId: cardId,
    );
    notifyListeners();
  }

  int totalPower(ClashLineup7v7 lineup) {
    return ClashLineupRules.calculateTotalPower(lineup, _catalogById);
  }

  ClashCardCatalogEntry? entryForCardId(String? cardId) {
    if (cardId == null || cardId.isEmpty) {
      return null;
    }
    return _catalogById[cardId];
  }

  List<ClashCardCatalogEntry> pickerEntries({
    required ClashPosition slot,
    String searchQuery = '',
  }) {
    final lineup = selectedLineup;
    if (lineup == null) {
      return const [];
    }

    final query = searchQuery.trim().toLowerCase();
    final owned = _collectionRepository.loadOwnedCardIds();
    final entries = _catalogById.values.where((entry) {
      if (!owned.contains(entry.id)) {
        return false;
      }
      if (query.isNotEmpty && !entry.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    entries.sort((a, b) => b.power.compareTo(a.power));
    return entries;
  }

  ClashLineupAssignBlockReason? pickerBlockReason({
    required ClashPosition slot,
    required ClashCardCatalogEntry entry,
  }) {
    final lineup = selectedLineup;
    if (lineup == null) {
      return null;
    }
    return ClashLineupRules.blockReason(
      lineup: lineup,
      slot: slot,
      entry: entry,
      catalogById: _catalogById,
    );
  }

  bool canPickEntry({
    required ClashPosition slot,
    required ClashCardCatalogEntry entry,
  }) {
    return pickerBlockReason(slot: slot, entry: entry) == null;
  }
}

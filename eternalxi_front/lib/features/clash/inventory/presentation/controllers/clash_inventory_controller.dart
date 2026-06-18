import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:flutter/foundation.dart';

enum ClashInventoryLoadState { idle, loading, ready, error }

class ClashInventoryController extends ChangeNotifier {
  ClashInventoryController({required ClashInventoryRepository repository})
    : _repository = repository;

  final ClashInventoryRepository _repository;

  ClashInventoryLoadState _state = ClashInventoryLoadState.idle;
  List<ClashInventoryItem> _items = const [];
  ClashInventorySummary? _summary;
  ClashInventoryFilter _filter = ClashInventoryFilter.all;
  String? _errorMessage;

  ClashInventoryLoadState get state => _state;
  ClashInventoryFilter get filter => _filter;
  ClashInventorySummary? get summary => _summary;
  String? get errorMessage => _errorMessage;

  List<ClashInventoryItem> get visibleItems {
    return ClashInventoryRepository.filterItems(_items, _filter);
  }

  Map<ClashInventoryCategory, List<ClashInventoryItem>>
  get groupedVisibleItems {
    if (_filter != ClashInventoryFilter.all) {
      return {_filter.category!: visibleItems};
    }
    return ClashInventoryRepository.groupByCategory(_items);
  }

  Future<void> load() async {
    if (_state == ClashInventoryLoadState.loading) {
      return;
    }
    _state = ClashInventoryLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.fetchAllItems();
      _items = items;
      _summary = ClashInventoryRepository.buildSummary(items);
      _state = ClashInventoryLoadState.ready;
    } catch (error) {
      _state = ClashInventoryLoadState.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void setFilter(ClashInventoryFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }
}

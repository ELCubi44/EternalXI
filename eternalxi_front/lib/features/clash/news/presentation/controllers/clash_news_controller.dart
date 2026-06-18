import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_item.dart';
import 'package:flutter/foundation.dart';

enum ClashNewsLoadState { idle, loading, ready }

class ClashNewsController extends ChangeNotifier {
  ClashNewsController({required ClashNewsRepository repository})
    : _repository = repository;

  final ClashNewsRepository _repository;

  ClashNewsLoadState _state = ClashNewsLoadState.idle;
  List<ClashNewsEntry> _entries = const [];
  ClashNewsSummary _summary = const ClashNewsSummary(unreadCount: 0);
  ClashNewsFilter _filter = ClashNewsFilter.all;
  String? _expandedNewsId;
  String? _errorMessage;

  ClashNewsLoadState get state => _state;
  List<ClashNewsEntry> get entries => _entries;
  ClashNewsSummary get summary => _summary;
  ClashNewsFilter get filter => _filter;
  String? get expandedNewsId => _expandedNewsId;
  String? get errorMessage => _errorMessage;

  List<ClashNewsEntry> get filteredEntries {
    return ClashNewsRepository.filterEntries(_entries, _filter);
  }

  Future<void> load() async {
    _state = ClashNewsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _entries = await _repository.fetchNewsEntries();
      _summary = await _repository.fetchSummary();
      _state = ClashNewsLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashNewsLoadState.ready;
    }
    notifyListeners();
  }

  Future<void> openScreen() async {
    await _repository.recordOpened();
    await load();
  }

  void setFilter(ClashNewsFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }

  Future<void> toggleExpanded(String newsId) async {
    if (_expandedNewsId == newsId) {
      _expandedNewsId = null;
    } else {
      _expandedNewsId = newsId;
      await markAsRead(newsId);
    }
    notifyListeners();
  }

  Future<void> markAsRead(String newsId) async {
    await _repository.markAsRead(newsId);
    _entries = await _repository.fetchNewsEntries();
    _summary = await _repository.fetchSummary();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    _entries = await _repository.fetchNewsEntries();
    _summary = await _repository.fetchSummary();
    notifyListeners();
  }
}

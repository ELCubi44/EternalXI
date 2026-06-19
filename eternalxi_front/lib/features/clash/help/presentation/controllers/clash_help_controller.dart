import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:flutter/foundation.dart';

enum ClashHelpLoadState { idle, loading, ready, error }

/// Estado de la guía Clash (Fase 51).
class ClashHelpController extends ChangeNotifier {
  ClashHelpController({required ClashHelpRepository repository})
    : _repository = repository;

  final ClashHelpRepository _repository;

  ClashHelpLoadState _state = ClashHelpLoadState.idle;
  String? _errorMessage;
  List<ClashHelpTopic> _topics = const [];
  String _query = '';
  ClashHelpCategory? _category;

  ClashHelpLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ClashHelpTopic> get topics => _topics;
  String get query => _query;
  ClashHelpCategory? get category => _category;

  Future<void> load() async {
    _state = ClashHelpLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _topics = await _repository.search(query: _query, category: _category);
      _state = ClashHelpLoadState.ready;
    } catch (error) {
      _state = ClashHelpLoadState.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> setQuery(String value) async {
    _query = value;
    await load();
  }

  Future<void> setCategory(ClashHelpCategory? value) async {
    _category = value;
    await load();
  }
}

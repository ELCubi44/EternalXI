import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:flutter/foundation.dart';

enum ClashCharacterEventsLoadState { idle, loading, ready }

class ClashCharacterEventsController extends ChangeNotifier {
  ClashCharacterEventsController({
    required ClashCharacterEventsRepository repository,
  }) : _repository = repository;

  final ClashCharacterEventsRepository _repository;

  ClashCharacterEventsLoadState _state = ClashCharacterEventsLoadState.idle;
  List<ClashCharacterEventSummary> _summaries = const [];
  ClashCharacterEvent? _activeEvent;
  List<ClashCharacterEventStageProgress> _stageProgress = const [];
  String? _errorMessage;

  ClashCharacterEventsLoadState get state => _state;
  List<ClashCharacterEventSummary> get summaries => _summaries;
  ClashCharacterEvent? get activeEvent => _activeEvent;
  List<ClashCharacterEventStageProgress> get stageProgress => _stageProgress;
  String? get errorMessage => _errorMessage;
  ClashCharacterEventStageCompletionResult? get lastCompletion =>
      _repository.lastCompletion;

  Future<void> loadEvents() async {
    _state = ClashCharacterEventsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _summaries = await _repository.fetchEventSummaries();
      _state = ClashCharacterEventsLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashCharacterEventsLoadState.ready;
    }
    notifyListeners();
  }

  Future<bool> openEvent(String eventId) async {
    _state = ClashCharacterEventsLoadState.loading;
    notifyListeners();
    try {
      _activeEvent = await _repository.findEventById(eventId);
      if (_activeEvent == null) {
        _state = ClashCharacterEventsLoadState.ready;
        notifyListeners();
        return false;
      }
      _stageProgress = await _repository.fetchStageProgress(eventId);
      _state = ClashCharacterEventsLoadState.ready;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashCharacterEventsLoadState.ready;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshActiveEvent() async {
    final eventId = _activeEvent?.id;
    if (eventId == null) {
      return;
    }
    _stageProgress = await _repository.fetchStageProgress(eventId);
    _summaries = await _repository.fetchEventSummaries();
    notifyListeners();
  }

  ClashCharacterEventStageProgress? stageProgressFor(String stageId) {
    for (final item in _stageProgress) {
      if (item.stage.id == stageId) {
        return item;
      }
    }
    return null;
  }
}

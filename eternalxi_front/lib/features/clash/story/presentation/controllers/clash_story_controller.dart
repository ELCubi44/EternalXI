import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_chapter.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_saga.dart';
import 'package:flutter/foundation.dart';

enum ClashStoryLoadState { idle, loading, ready, error }

/// Estado y acciones del modo Historia Clash.
class ClashStoryController extends ChangeNotifier {
  ClashStoryController({required ClashStoryRepository storyRepository})
    : _storyRepository = storyRepository {
    _progress = _storyRepository.loadProgress();
  }

  final ClashStoryRepository _storyRepository;

  ClashStoryLoadState _state = ClashStoryLoadState.idle;
  String? _errorMessage;
  List<ClashStorySaga> _sagas = const [];
  ClashStoryChapter? _activeChapter;
  ClashStoryProgress _progress = const ClashStoryProgress();

  ClashStoryLevel? _activeLevel;
  int _sceneIndex = 0;
  ClashStoryCompletionResult? _lastCompletion;

  ClashStoryLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ClashStorySaga> get sagas => _sagas;
  ClashStoryChapter? get activeChapter => _activeChapter;
  ClashStoryProgress get progress => _progress;
  ClashStoryLevel? get activeLevel => _activeLevel;
  int get sceneIndex => _sceneIndex;
  ClashStoryCompletionResult? get lastCompletion => _lastCompletion;

  bool get clashTeamUnlocked => _progress.clashTeamUnlocked;

  bool get isSummonUnlocked => _storyRepository.isSummonUnlocked(_progress);

  Future<void> load() async {
    if (_state == ClashStoryLoadState.loading) {
      return;
    }
    _state = ClashStoryLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _storyRepository.ensureSummonUnlocked();
      _progress = _storyRepository.loadProgress();
      _sagas = await _storyRepository.loadSagas();
      if (_sagas.isNotEmpty) {
        final saga = _sagas.first;
        final chapterId = _progress.currentChapterId.isNotEmpty
            ? _progress.currentChapterId
            : saga.chapterIds.first;
        _activeChapter = await _storyRepository.loadChapter(chapterId);
      }
      _state = ClashStoryLoadState.ready;
    } catch (error) {
      _state = ClashStoryLoadState.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  ClashStoryLevelStatus statusFor(ClashStoryLevel level) {
    final chapter = _activeChapter;
    if (chapter == null) {
      return ClashStoryLevelStatus.locked;
    }
    return _storyRepository.levelStatus(
      level: level,
      chapterLevels: chapter.levels,
      progress: _progress,
    );
  }

  bool canOpen(ClashStoryLevel level) {
    final chapter = _activeChapter;
    if (chapter == null) {
      return false;
    }
    return _storyRepository.canOpenLevel(
      level: level,
      chapterLevels: chapter.levels,
      progress: _progress,
    );
  }

  Future<bool> prepareLevel(String levelId) async {
    final level = await _storyRepository.findLevelById(levelId);
    if (level == null) {
      return false;
    }
    if (!canOpen(level)) {
      return false;
    }
    _activeLevel = level;
    _sceneIndex = 0;
    _lastCompletion = null;
    notifyListeners();
    return true;
  }

  void clearActiveLevel() {
    _activeLevel = null;
    _sceneIndex = 0;
    notifyListeners();
  }

  bool get hasNextScene {
    final level = _activeLevel;
    if (level == null) {
      return false;
    }
    return _sceneIndex < level.scenes.length - 1;
  }

  void nextScene() {
    if (hasNextScene) {
      _sceneIndex += 1;
      notifyListeners();
    }
  }

  void skipScene() {
    final level = _activeLevel;
    if (level == null) {
      return;
    }
    final scene = level.scenes[_sceneIndex];
    if (scene.isSkippable) {
      nextScene();
    }
  }

  Future<ClashStoryCompletionResult?> finishActiveLevel() async {
    final level = _activeLevel;
    if (level == null) {
      return null;
    }
    if (hasNextScene) {
      return null;
    }

    final result = await _storyRepository.completeStoryLevel(level.id);
    _progress = _storyRepository.loadProgress();
    _lastCompletion = result;
    notifyListeners();
    return result;
  }

  Future<ClashStoryCompletionResult?> finishMatchLevel({
    required String levelId,
    required bool userWon,
    MatchState? matchState,
    Iterable<String>? lineupCardIds,
  }) async {
    final result = await _storyRepository.completeMatchLevel(
      levelId,
      userWon: userWon,
      matchState: matchState,
      lineupCardIds: lineupCardIds,
    );
    if (userWon) {
      _progress = _storyRepository.loadProgress();
      _lastCompletion = result;
    } else {
      _lastCompletion = null;
    }
    notifyListeners();
    return result;
  }

  void clearLastCompletion() {
    _lastCompletion = null;
    notifyListeners();
  }

  ClashStoryLevel? nextUnlockedLevelAfter(String levelId) {
    final chapter = _activeChapter;
    if (chapter == null) {
      return null;
    }
    final sorted = [...chapter.levels]
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = sorted.indexWhere((level) => level.id == levelId);
    if (index < 0 || index >= sorted.length - 1) {
      return null;
    }
    final next = sorted[index + 1];
    return canOpen(next) ? next : null;
  }
}

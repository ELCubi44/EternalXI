import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_completion_unlocks.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_chapter.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_saga.dart';

class ClashStoryOperationException implements Exception {
  ClashStoryOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repositorio de historia Clash (contenido local + progreso local).
class ClashStoryRepository {
  ClashStoryRepository({
    required ClashStoryLocalDataSource dataSource,
    required ClashStoryProgressStorageBackend progressStorage,
    required ClashPlayerCollectionRepository collectionRepository,
  }) : _dataSource = dataSource,
       _progressStorage = progressStorage,
       _collectionRepository = collectionRepository;

  final ClashStoryLocalDataSource _dataSource;
  final ClashStoryProgressStorageBackend _progressStorage;
  final ClashPlayerCollectionRepository _collectionRepository;

  List<ClashStorySaga>? _sagasCache;
  final Map<String, ClashStoryChapter> _chaptersCache = {};
  ClashStoryProgress? _progressCache;

  ClashStoryProgress loadProgress() {
    _progressCache ??= _progressStorage.readProgress();
    return _progressCache!;
  }

  Future<List<ClashStorySaga>> loadSagas() async {
    _sagasCache ??= await _dataSource.loadSagas();
    return List<ClashStorySaga>.unmodifiable(_sagasCache!);
  }

  Future<ClashStoryChapter> loadChapter(String chapterId) async {
    if (_chaptersCache.containsKey(chapterId)) {
      return _chaptersCache[chapterId]!;
    }
    final chapter = await _dataSource.loadChapter(chapterId);
    _chaptersCache[chapterId] = chapter;
    return chapter;
  }

  Future<ClashStoryLevel?> findLevelById(String levelId) async {
    final sagas = await loadSagas();
    for (final saga in sagas) {
      for (final chapterId in saga.chapterIds) {
        final chapter = await loadChapter(chapterId);
        for (final level in chapter.levels) {
          if (level.id == levelId) {
            return level;
          }
        }
      }
    }
    return null;
  }

  ClashStoryLevelStatus levelStatus({
    required ClashStoryLevel level,
    required List<ClashStoryLevel> chapterLevels,
    ClashStoryProgress? progress,
  }) {
    final state = progress ?? loadProgress();
    if (state.isLevelCompleted(level.id)) {
      return ClashStoryLevelStatus.completed;
    }
    if (_isLevelAvailable(level, chapterLevels, state)) {
      return ClashStoryLevelStatus.available;
    }
    return ClashStoryLevelStatus.locked;
  }

  bool canOpenLevel({
    required ClashStoryLevel level,
    required List<ClashStoryLevel> chapterLevels,
    ClashStoryProgress? progress,
  }) {
    return levelStatus(
          level: level,
          chapterLevels: chapterLevels,
          progress: progress,
        ) ==
        ClashStoryLevelStatus.available;
  }

  bool _isLevelAvailable(
    ClashStoryLevel level,
    List<ClashStoryLevel> chapterLevels,
    ClashStoryProgress progress,
  ) {
    final sorted = [...chapterLevels]
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = sorted.indexWhere((item) => item.id == level.id);
    if (index < 0) {
      return false;
    }
    if (index == 0) {
      return true;
    }
    final previous = sorted[index - 1];
    return progress.isLevelCompleted(previous.id);
  }

  Future<ClashStoryCompletionResult> completeStoryLevel(String levelId) async {
    final level = await _requireLevel(levelId);
    if (level.type != ClashStoryLevelType.story) {
      throw ClashStoryOperationException('Este nivel no es narrativo');
    }
    return _completeLevel(levelId, level);
  }

  Future<ClashStoryCompletionResult> completeMatchLevel(
    String levelId, {
    required bool userWon,
  }) async {
    if (!userWon) {
      return ClashStoryCompletionResult(
        levelId: levelId,
        rewardsGranted: const ClashStoryReward(),
        newlyGrantedCardIds: const [],
        unlocks: const ClashStoryCompletionUnlocks(),
        firstCompletion: false,
      );
    }

    final level = await _requireLevel(levelId);
    if (level.type != ClashStoryLevelType.match &&
        level.type != ClashStoryLevelType.mixed) {
      throw ClashStoryOperationException('Este nivel no es un partido');
    }
    return _completeLevel(levelId, level);
  }

  Future<ClashStoryLevel> _requireLevel(String levelId) async {
    final level = await findLevelById(levelId);
    if (level == null) {
      throw ClashStoryOperationException('Nivel no encontrado');
    }
    final chapter = await loadChapter(level.chapterId);
    if (!canOpenLevel(level: level, chapterLevels: chapter.levels)) {
      throw ClashStoryOperationException('Nivel bloqueado');
    }
    return level;
  }

  Future<ClashStoryCompletionResult> _completeLevel(
    String levelId,
    ClashStoryLevel level,
  ) async {
    var progress = loadProgress();
    final firstCompletion = !progress.isLevelCompleted(levelId);
    final rewardsAlreadyClaimed = progress.areRewardsClaimed(levelId);

    final newlyGrantedCards = <String>[];
    if (firstCompletion && !rewardsAlreadyClaimed) {
      newlyGrantedCards.addAll(await _grantRewards(level.rewards, progress));
    }

    progress = progress.copyWith(
      completedLevelIds: {...progress.completedLevelIds, levelId},
      claimedRewardLevelIds: firstCompletion && !rewardsAlreadyClaimed
          ? {...progress.claimedRewardLevelIds, levelId}
          : progress.claimedRewardLevelIds,
      unlocks: firstCompletion
          ? progress.unlocks.merge(level.completionUnlocks)
          : progress.unlocks,
      eternalXiCardsGranted:
          progress.eternalXiCardsGranted ||
          (level.rewards.starterRosterKey != null &&
              newlyGrantedCards.isNotEmpty),
      walletGems:
          progress.walletGems +
          (firstCompletion && !rewardsAlreadyClaimed ? level.rewards.gems : 0),
      walletCoins:
          progress.walletCoins +
          (firstCompletion && !rewardsAlreadyClaimed ? level.rewards.coins : 0),
      currentChapterId: level.chapterId,
    );

    await _saveProgress(progress);

    return ClashStoryCompletionResult(
      levelId: levelId,
      rewardsGranted: firstCompletion && !rewardsAlreadyClaimed
          ? level.rewards
          : const ClashStoryReward(),
      newlyGrantedCardIds: newlyGrantedCards,
      unlocks: level.completionUnlocks,
      firstCompletion: firstCompletion,
    );
  }

  Future<List<String>> _grantRewards(
    ClashStoryReward rewards,
    ClashStoryProgress progress,
  ) async {
    final granted = <String>[];

    if (rewards.starterRosterKey ==
        ClashStoryReward.eternalXiStarterRosterKey) {
      granted.addAll(await _collectionRepository.grantEternalXiStarterNCards());
    }

    if (rewards.cardIds.isNotEmpty) {
      granted.addAll(
        await _collectionRepository.grantMissingCardIds(rewards.cardIds),
      );
    }

    return granted;
  }

  Future<void> _saveProgress(ClashStoryProgress progress) async {
    _progressCache = progress;
    await _progressStorage.writeProgress(progress);
  }

  void clearCacheForTests() {
    _sagasCache = null;
    _chaptersCache.clear();
    _progressCache = null;
  }
}

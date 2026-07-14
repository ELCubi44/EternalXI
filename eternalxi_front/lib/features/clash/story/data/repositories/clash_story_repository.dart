import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
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
    ClashGachaTicketRepository? ticketRepository,
  }) : _dataSource = dataSource,
       _progressStorage = progressStorage,
       _collectionRepository = collectionRepository,
       _ticketRepository = ticketRepository;

  final ClashStoryLocalDataSource _dataSource;
  final ClashStoryProgressStorageBackend _progressStorage;
  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashGachaTicketRepository? _ticketRepository;

  List<ClashStorySaga>? _sagasCache;
  final Map<String, ClashStoryChapter> _chaptersCache = {};
  ClashStoryProgress? _progressCache;

  ClashLocalRewardGranter get _itemRewardGranter => ClashLocalRewardGranter(
    collectionRepository: _collectionRepository,
    ticketRepository: _ticketRepository,
  );

  static const eternalXiFormedLevelId = 'prologue-lvl-03';

  static const _eternalXiFormedUnlocks = ClashStoryCompletionUnlocks(
    clashTeamUnlocked: true,
    firstLineupUnlocked: true,
    nextPlayableLevelUnlocked: true,
  );

  ClashStoryProgress loadProgress() {
    _progressCache ??= _normalizeProgress(_progressStorage.readProgress());
    return _progressCache!;
  }

  /// Invocaciones y equipo Clash disponibles tras formar Eternal XI.
  bool isSummonUnlocked([ClashStoryProgress? progress]) {
    final p = progress ?? loadProgress();
    return p.clashTeamUnlocked ||
        p.eternalXiCardsGranted ||
        p.completedLevelIds.contains(eternalXiFormedLevelId);
  }

  /// Repara flags de desbloqueo si el roster ya existe (sync, reinstall, etc.).
  Future<bool> ensureSummonUnlocked() async {
    var progress = loadProgress();
    if (progress.clashTeamUnlocked) {
      return true;
    }

    final formedByProgress = isSummonUnlocked(progress);
    final formedByCollection =
        !formedByProgress &&
        await _collectionRepository.ownsEternalXiStarterNCards();

    if (!formedByProgress && !formedByCollection) {
      return false;
    }

    progress = progress.copyWith(
      unlocks: progress.unlocks.merge(_eternalXiFormedUnlocks),
      eternalXiCardsGranted: true,
      completedLevelIds: formedByCollection
          ? {...progress.completedLevelIds, eternalXiFormedLevelId}
          : progress.completedLevelIds,
    );
    await _saveProgress(progress);
    return true;
  }

  ClashStoryProgress _normalizeProgress(ClashStoryProgress progress) {
    if (!isSummonUnlocked(progress) || progress.clashTeamUnlocked) {
      return progress;
    }
    return progress.copyWith(
      unlocks: progress.unlocks.merge(_eternalXiFormedUnlocks),
      eternalXiCardsGranted: true,
    );
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
    final status = levelStatus(
      level: level,
      chapterLevels: chapterLevels,
      progress: progress,
    );
    return status == ClashStoryLevelStatus.available ||
        status == ClashStoryLevelStatus.completed;
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
    MatchState? matchState,
    Iterable<String>? lineupCardIds,
  }) async {
    final level = await _requireLevel(levelId);
    if (level.type != ClashStoryLevelType.match &&
        level.type != ClashStoryLevelType.mixed) {
      throw ClashStoryOperationException('Este nivel no es un partido');
    }

    final stateForEvaluation =
        matchState ?? MatchState.testing(levelId: levelId);
    final objectiveResults = ClashMatchObjectiveEvaluator.evaluate(
      objectives: level.matchObjectives,
      state: stateForEvaluation,
      userWon: userWon,
      progress: loadProgress(),
    );

    if (!userWon) {
      return ClashStoryCompletionResult(
        levelId: levelId,
        rewardsGranted: const ClashStoryReward(),
        newlyGrantedCardIds: const [],
        unlocks: const ClashStoryCompletionUnlocks(),
        firstCompletion: false,
        objectiveResults: objectiveResults,
        cardXpResults: const [],
      );
    }

    return _completeMatchLevel(
      levelId,
      level,
      objectiveResults,
      stateForEvaluation,
      lineupCardIds: lineupCardIds,
    );
  }

  Future<ClashStoryCompletionResult> _completeMatchLevel(
    String levelId,
    ClashStoryLevel level,
    List<ClashMatchObjectiveProgress> objectiveResults,
    MatchState matchState, {
    Iterable<String>? lineupCardIds,
  }) async {
    var progress = loadProgress();
    final firstCompletion = !progress.isLevelCompleted(levelId);
    final baseRewardsAlreadyClaimed = progress.areRewardsClaimed(levelId);
    final grantBaseVictory = firstCompletion && !baseRewardsAlreadyClaimed;

    final rewardsToGrant = ClashMatchObjectiveEvaluator.rewardsToGrant(
      levelId: levelId,
      baseVictoryReward: level.rewards,
      objectiveResults: objectiveResults,
      grantBaseVictory: grantBaseVictory,
      progress: progress,
    );

    final newlyGrantedCards = <String>[];
    if (!rewardsToGrant.isEmpty) {
      newlyGrantedCards.addAll(await _grantRewards(rewardsToGrant, progress));
    }

    final newlyClaimedObjectiveKeys = <String>{};
    for (final result in objectiveResults) {
      if (!result.completed || result.objective.rewards.isEmpty) {
        continue;
      }
      final key = ClashMatchObjectiveEvaluator.rewardKey(
        levelId,
        result.objectiveId,
      );
      if (!progress.claimedObjectiveRewardKeys.contains(key)) {
        newlyClaimedObjectiveKeys.add(key);
      }
    }

    progress = progress.copyWith(
      completedLevelIds: {...progress.completedLevelIds, levelId},
      claimedRewardLevelIds: grantBaseVictory
          ? {...progress.claimedRewardLevelIds, levelId}
          : progress.claimedRewardLevelIds,
      claimedObjectiveRewardKeys: {
        ...progress.claimedObjectiveRewardKeys,
        ...newlyClaimedObjectiveKeys,
      },
      unlocks: firstCompletion
          ? progress.unlocks.merge(level.completionUnlocks)
          : progress.unlocks,
      eternalXiCardsGranted:
          progress.eternalXiCardsGranted ||
          (level.rewards.starterRosterKey != null &&
              newlyGrantedCards.isNotEmpty),
      walletGems: progress.walletGems + rewardsToGrant.gems,
      walletCoins: progress.walletCoins + rewardsToGrant.coins,
      currentChapterId: level.chapterId,
    );

    await _saveProgress(progress);

    final cardXpResults = level.cardXpReward > 0 && lineupCardIds != null
        ? await _collectionRepository.grantMatchXp(
            cardIds: lineupCardIds,
            xpPerCard: level.cardXpReward,
          )
        : const <ClashCardXpResult>[];

    final displayResults = ClashMatchObjectiveEvaluator.evaluate(
      objectives: level.matchObjectives,
      state: matchState,
      userWon: true,
      progress: progress,
    );

    return ClashStoryCompletionResult(
      levelId: levelId,
      rewardsGranted: rewardsToGrant,
      newlyGrantedCardIds: newlyGrantedCards,
      unlocks: level.completionUnlocks,
      firstCompletion: firstCompletion,
      objectiveResults: displayResults,
      cardXpResults: cardXpResults,
    );
  }

  Future<ClashStoryLevel> _requireLevel(String levelId) async {
    final level = await findLevelById(levelId);
    if (level == null) {
      throw ClashStoryOperationException('Nivel no encontrado');
    }
    final progress = loadProgress();
    if (progress.isLevelCompleted(levelId)) {
      return level;
    }
    final chapter = await loadChapter(level.chapterId);
    if (!canOpenLevel(
      level: level,
      chapterLevels: chapter.levels,
      progress: progress,
    )) {
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
    final result = await _itemRewardGranter.grantAll(
      ClashRewardConverters.fromStoryRewardItems(rewards),
      grantWallet: false,
    );
    return result.newlyGrantedCardIds;
  }

  Future<void> _saveProgress(ClashStoryProgress progress) async {
    _progressCache = progress;
    await _progressStorage.writeProgress(progress);
  }

  int walletGems() => loadProgress().walletGems;

  int walletCoins() => loadProgress().walletCoins;

  bool canSpendCoins(int amount) {
    if (amount <= 0) {
      return true;
    }
    return loadProgress().walletCoins >= amount;
  }

  Future<bool> spendGems(int amount) async {
    if (amount <= 0) {
      return true;
    }
    final progress = loadProgress();
    if (progress.walletGems < amount) {
      return false;
    }
    await _saveProgress(
      progress.copyWith(walletGems: progress.walletGems - amount),
    );
    return true;
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) {
      return true;
    }
    final progress = loadProgress();
    if (progress.walletCoins < amount) {
      return false;
    }
    await _saveProgress(
      progress.copyWith(walletCoins: progress.walletCoins - amount),
    );
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) {
      return;
    }
    final progress = loadProgress();
    await _saveProgress(
      progress.copyWith(walletCoins: progress.walletCoins + amount),
    );
  }

  Future<void> addGems(int amount) async {
    if (amount <= 0) {
      return;
    }
    final progress = loadProgress();
    await _saveProgress(
      progress.copyWith(walletGems: progress.walletGems + amount),
    );
  }

  void clearCacheForTests() {
    _sagasCache = null;
    _chaptersCache.clear();
    _progressCache = null;
  }
}

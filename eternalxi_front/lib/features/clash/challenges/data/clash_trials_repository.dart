import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_local_datasource.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_storage.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';

class ClashTrialsRepository {
  ClashTrialsRepository({
    required ClashTrialsLocalDataSource dataSource,
    required ClashTrialsStorageBackend storage,
    required ClashLocalRewardGranter rewardGranter,
    required ClashPlayerCollectionRepository collectionRepository,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _rewardGranter = rewardGranter,
       _collectionRepository = collectionRepository,
       _now = now ?? DateTime.now;

  final ClashTrialsLocalDataSource _dataSource;
  final ClashTrialsStorageBackend _storage;
  final ClashLocalRewardGranter _rewardGranter;
  final ClashPlayerCollectionRepository _collectionRepository;
  final DateTime Function() _now;

  List<ClashTrial>? _trialsCache;
  ClashTrialsProgressState? _stateCache;
  ClashTrialFloorCompletionResult? lastCompletion;

  Future<List<ClashTrial>> _loadCatalog() async {
    _trialsCache ??= await _dataSource.loadTrials();
    return _trialsCache!;
  }

  String _localDateKey(DateTime time) {
    final local = DateTime(time.year, time.month, time.day);
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<ClashTrialsProgressState> loadState() async {
    if (_stateCache != null) {
      return _normalizeDailyAttempts(_stateCache!);
    }
    final stored = _storage.readState();
    _stateCache = stored ?? const ClashTrialsProgressState();
    _stateCache = _normalizeDailyAttempts(_stateCache!);
    if (stored == null) {
      await _storage.writeState(_stateCache!);
    }
    return _stateCache!;
  }

  ClashTrialsProgressState _normalizeDailyAttempts(ClashTrialsProgressState state) {
    final today = _localDateKey(_now());
    if (state.dailyAttemptsDateKey == today) {
      return state;
    }
    return state.copyWith(
      dailyAttemptsUsed: 0,
      dailyAttemptsDateKey: today,
    );
  }

  int remainingDailyAttempts(ClashTrialsProgressState state) {
    final normalized = _normalizeDailyAttempts(state);
    return (ClashTrialsProgressState.dailyAttemptLimit - normalized.dailyAttemptsUsed)
        .clamp(0, ClashTrialsProgressState.dailyAttemptLimit);
  }

  Future<ClashTrial?> findTrialById(String trialId) async {
    for (final trial in await _loadCatalog()) {
      if (trial.id == trialId) {
        return trial;
      }
    }
    return null;
  }

  Future<ClashTrialFloor?> findFloor(String trialId, String floorId) async {
    final trial = await findTrialById(trialId);
    if (trial == null) {
      return null;
    }
    for (final floor in trial.floors) {
      if (floor.id == floorId) {
        return floor;
      }
    }
    return null;
  }

  bool isFloorUnlocked(
    ClashTrial trial,
    ClashTrialFloor floor,
    ClashTrialsProgressState state,
  ) {
    final index = trial.floors.indexWhere((item) => item.id == floor.id);
    if (index <= 0) {
      return true;
    }
    final previousId = trial.floors[index - 1].id;
    return state.completedFloorIds.contains(previousId);
  }

  ClashTrialFloorProgress buildFloorProgress({
    required ClashTrial trial,
    required ClashTrialFloor floor,
    required ClashTrialsProgressState state,
  }) {
    final unlocked = isFloorUnlocked(trial, floor, state);
    final clearCount = state.clearCounts[floor.id] ?? 0;
    final completed = state.completedFloorIds.contains(floor.id);
    final status = !unlocked
        ? ClashTrialFloorStatus.locked
        : completed
        ? ClashTrialFloorStatus.completed
        : ClashTrialFloorStatus.available;
    return ClashTrialFloorProgress(
      floor: floor,
      status: status,
      clearCount: clearCount,
      canPlay: unlocked && remainingDailyAttempts(state) > 0,
      scaledPower: floor.scaledRecommendedPower(clearCount),
    );
  }

  Future<List<ClashTrialSummary>> fetchTrialSummaries() async {
    final trials = await _loadCatalog();
    final state = await loadState();
    return trials
        .map((trial) {
          final completed = trial.floors
              .where((floor) => state.completedFloorIds.contains(floor.id))
              .length;
          var bestClear = 0;
          for (final floor in trial.floors) {
            final count = state.clearCounts[floor.id] ?? 0;
            if (count > bestClear) {
              bestClear = count;
            }
          }
          return ClashTrialSummary(
            trial: trial,
            completedFloors: completed,
            totalFloors: trial.floors.length,
            bestClearCount: bestClear,
          );
        })
        .toList(growable: false);
  }

  Future<List<ClashTrialFloorProgress>> fetchFloorProgress(String trialId) async {
    final trial = await findTrialById(trialId);
    if (trial == null) {
      return const [];
    }
    final state = await loadState();
    return trial.floors
        .map(
          (floor) => buildFloorProgress(trial: trial, floor: floor, state: state),
        )
        .toList(growable: false);
  }

  Future<bool> consumeDailyAttempt() async {
    var state = await loadState();
    if (remainingDailyAttempts(state) <= 0) {
      return false;
    }
    state = state.copyWith(
      dailyAttemptsUsed: state.dailyAttemptsUsed + 1,
      dailyAttemptsDateKey: _localDateKey(_now()),
      lastPlayedAt: _now().toIso8601String(),
    );
    _stateCache = state;
    await _storage.writeState(state);
    return true;
  }

  Future<void> grantBonusDailyAttempts(int amount) async {
    if (amount <= 0) {
      return;
    }
    var state = await loadState();
    final reduced = (state.dailyAttemptsUsed - amount).clamp(
      0,
      ClashTrialsProgressState.dailyAttemptLimit,
    );
    state = state.copyWith(
      dailyAttemptsUsed: reduced,
      dailyAttemptsDateKey: _localDateKey(_now()),
    );
    _stateCache = state;
    await _storage.writeState(state);
  }

  Future<ClashTrialFloorCompletionResult?> completeFloor({
    required String trialId,
    required String floorId,
    required bool userWon,
    required int techniqueUses,
    Iterable<String>? lineupCardIds,
  }) async {
    if (!userWon) {
      return null;
    }

    final trial = await findTrialById(trialId);
    final floor = await findFloor(trialId, floorId);
    if (trial == null || floor == null) {
      return null;
    }

    var state = await loadState();
    if (!isFloorUnlocked(trial, floor, state)) {
      return null;
    }

    final clearCount = state.clearCounts[floorId] ?? 0;
    final isFirstClear = clearCount == 0;
    final baseReward = isFirstClear ? floor.firstClearRewards : floor.repeatRewards;

    final newlyGranted = baseReward.isEmpty
        ? const <String>[]
        : await _grantReward(baseReward);

    var techniqueBonusGranted = false;
    var techniqueBonusRewards = const ClashCharacterEventReward();
    var bonusGrantedIds = const <String>[];

    if (techniqueUses >= floor.techniqueBonusTarget &&
        floor.techniqueBonusTarget > 0 &&
        !floor.techniqueBonusRewards.isEmpty) {
      techniqueBonusGranted = true;
      techniqueBonusRewards = floor.techniqueBonusRewards;
      bonusGrantedIds = await _grantReward(techniqueBonusRewards);
    }

    final cardXpResults = floor.cardXpReward > 0 && lineupCardIds != null
        ? await _collectionRepository.grantMatchXp(
            cardIds: lineupCardIds,
            xpPerCard: floor.cardXpReward,
          )
        : const <ClashCardXpResult>[];

    state = state.copyWith(
      completedFloorIds: {...state.completedFloorIds, floorId},
      clearCounts: {...state.clearCounts, floorId: clearCount + 1},
      totalTechniqueUses: state.totalTechniqueUses + techniqueUses,
      lastPlayedAt: _now().toIso8601String(),
    );
    _stateCache = state;
    await _storage.writeState(state);

    final result = ClashTrialFloorCompletionResult(
      trialId: trialId,
      floorId: floorId,
      firstClear: isFirstClear,
      rewardsGranted: baseReward,
      newlyGrantedCardIds: [...newlyGranted, ...bonusGrantedIds],
      techniqueBonusGranted: techniqueBonusGranted,
      techniqueBonusRewards: techniqueBonusRewards,
      cardXpResults: cardXpResults,
    );
    lastCompletion = result;
    return result;
  }

  Future<List<String>> _grantReward(ClashCharacterEventReward reward) async {
    if (reward.isEmpty) {
      return const [];
    }
    final result = await _rewardGranter.grantAll(
      ClashRewardConverters.fromCharacterEventReward(reward),
    );
    return result.newlyGrantedCardIds;
  }

  void clearCacheForTests() {
    _trialsCache = null;
    _stateCache = null;
    lastCompletion = null;
    _dataSource.clearCacheForTests();
  }

  Future<void> resetForTests() async {
    clearCacheForTests();
    await _storage.clear();
  }
}

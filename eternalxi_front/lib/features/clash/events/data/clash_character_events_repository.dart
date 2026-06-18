import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_local_datasource.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_status.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

class ClashCharacterEventsRepository {
  ClashCharacterEventsRepository({
    required ClashCharacterEventsLocalDataSource dataSource,
    required ClashCharacterEventsStorageBackend storage,
    required ClashStoryRepository storyRepository,
    required ClashShopGrantService grantService,
    required ClashPlayerCollectionRepository collectionRepository,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _storyRepository = storyRepository,
       _grantService = grantService,
       _collectionRepository = collectionRepository,
       _now = now ?? DateTime.now;

  final ClashCharacterEventsLocalDataSource _dataSource;
  final ClashCharacterEventsStorageBackend _storage;
  final ClashStoryRepository _storyRepository;
  final ClashShopGrantService _grantService;
  final ClashPlayerCollectionRepository _collectionRepository;
  final DateTime Function() _now;

  List<ClashCharacterEvent>? _eventsCache;
  ClashCharacterEventsProgressState? _stateCache;
  ClashCharacterEventStageCompletionResult? lastCompletion;

  static String firstClearKey(String stageId) => '$stageId/firstClear';

  Future<List<ClashCharacterEvent>> _loadCatalog() async {
    _eventsCache ??= await _dataSource.loadEvents();
    return _eventsCache!;
  }

  Future<ClashCharacterEventsProgressState> loadState() async {
    if (_stateCache != null) {
      return _stateCache!;
    }
    final stored = _storage.readState();
    _stateCache = stored ?? const ClashCharacterEventsProgressState();
    if (stored == null) {
      await _storage.writeState(_stateCache!);
    }
    return _stateCache!;
  }

  Future<ClashCharacterEvent?> findEventById(String eventId) async {
    for (final event in await _loadCatalog()) {
      if (event.id == eventId) {
        return event;
      }
    }
    return null;
  }

  Future<ClashCharacterEventStage?> findStage(
    String eventId,
    String stageId,
  ) async {
    final event = await findEventById(eventId);
    if (event == null) {
      return null;
    }
    for (final stage in event.stages) {
      if (stage.id == stageId) {
        return stage;
      }
    }
    return null;
  }

  bool isStageUnlocked(
    ClashCharacterEvent event,
    ClashCharacterEventStage stage,
    ClashCharacterEventsProgressState state,
  ) {
    final index = event.stages.indexWhere((item) => item.id == stage.id);
    if (index <= 0) {
      return true;
    }
    final previousId = event.stages[index - 1].id;
    return state.completedStageIds.contains(previousId);
  }

  ClashCharacterEventStageProgress buildStageProgress({
    required ClashCharacterEvent event,
    required ClashCharacterEventStage stage,
    required ClashCharacterEventsProgressState state,
  }) {
    final unlocked = isStageUnlocked(event, stage, state);
    final clearCount = state.clearCounts[stage.id] ?? 0;
    final completed = state.completedStageIds.contains(stage.id);
    final status = !unlocked
        ? ClashCharacterEventStageStatus.locked
        : completed
        ? ClashCharacterEventStageStatus.completed
        : ClashCharacterEventStageStatus.available;
    return ClashCharacterEventStageProgress(
      stage: stage,
      status: status,
      clearCount: clearCount,
      canPlay: unlocked,
    );
  }

  Future<List<ClashCharacterEventSummary>> fetchEventSummaries() async {
    final events = await _loadCatalog();
    final state = await loadState();
    return events
        .map((event) {
          final completed = event.stages
              .where((stage) => state.completedStageIds.contains(stage.id))
              .length;
          return ClashCharacterEventSummary(
            event: event,
            completedStages: completed,
            totalStages: event.stages.length,
            isAvailable:
                event.status == ClashCharacterEventAvailability.available,
          );
        })
        .toList(growable: false);
  }

  Future<List<ClashCharacterEventStageProgress>> fetchStageProgress(
    String eventId,
  ) async {
    final event = await findEventById(eventId);
    if (event == null) {
      return const [];
    }
    final state = await loadState();
    return event.stages
        .map(
          (stage) =>
              buildStageProgress(event: event, stage: stage, state: state),
        )
        .toList(growable: false);
  }

  Future<ClashCharacterEventStageCompletionResult?> completeStoryStage({
    required String eventId,
    required String stageId,
  }) async {
    final event = await findEventById(eventId);
    final stage = await findStage(eventId, stageId);
    if (event == null || stage == null) {
      return null;
    }
    if (stage.type != ClashCharacterEventStageType.story) {
      return null;
    }

    var state = await loadState();
    if (!isStageUnlocked(event, stage, state)) {
      return null;
    }

    final rewardKey = firstClearKey(stageId);
    final isFirstClear = !state.claimedFirstClearRewardKeys.contains(rewardKey);
    final reward = isFirstClear
        ? stage.firstClearRewards
        : const ClashCharacterEventReward();

    final newlyGranted = reward.isEmpty
        ? const <String>[]
        : await _grantReward(reward);

    final clearCount = (state.clearCounts[stageId] ?? 0) + 1;
    state = state.copyWith(
      completedStageIds: {...state.completedStageIds, stageId},
      claimedFirstClearRewardKeys: isFirstClear
          ? {...state.claimedFirstClearRewardKeys, rewardKey}
          : state.claimedFirstClearRewardKeys,
      clearCounts: {...state.clearCounts, stageId: clearCount},
      lastPlayedAt: _now().toIso8601String(),
    );
    _stateCache = state;
    await _storage.writeState(state);

    final result = ClashCharacterEventStageCompletionResult(
      eventId: eventId,
      stageId: stageId,
      firstClear: isFirstClear,
      rewardsGranted: reward,
      newlyGrantedCardIds: newlyGranted,
    );
    lastCompletion = result;
    return result;
  }

  Future<ClashCharacterEventStageCompletionResult?> completeMatchStage({
    required String eventId,
    required String stageId,
    required bool userWon,
    Iterable<String>? lineupCardIds,
  }) async {
    if (!userWon) {
      return null;
    }

    final event = await findEventById(eventId);
    final stage = await findStage(eventId, stageId);
    if (event == null || stage == null) {
      return null;
    }
    if (stage.type != ClashCharacterEventStageType.match) {
      return null;
    }

    var state = await loadState();
    if (!isStageUnlocked(event, stage, state)) {
      return null;
    }

    final clearCount = state.clearCounts[stageId] ?? 0;
    final isFirstClear = clearCount == 0;
    final reward = isFirstClear ? stage.firstClearRewards : stage.repeatRewards;

    final newlyGranted = reward.isEmpty
        ? const <String>[]
        : await _grantReward(reward);

    final cardXpResults = stage.cardXpReward > 0 && lineupCardIds != null
        ? await _collectionRepository.grantMatchXp(
            cardIds: lineupCardIds,
            xpPerCard: stage.cardXpReward,
          )
        : const <ClashCardXpResult>[];

    final rewardKey = firstClearKey(stageId);
    state = state.copyWith(
      completedStageIds: {...state.completedStageIds, stageId},
      claimedFirstClearRewardKeys: isFirstClear
          ? {...state.claimedFirstClearRewardKeys, rewardKey}
          : state.claimedFirstClearRewardKeys,
      clearCounts: {...state.clearCounts, stageId: clearCount + 1},
      lastPlayedAt: _now().toIso8601String(),
    );
    _stateCache = state;
    await _storage.writeState(state);

    final result = ClashCharacterEventStageCompletionResult(
      eventId: eventId,
      stageId: stageId,
      firstClear: isFirstClear,
      rewardsGranted: reward,
      newlyGrantedCardIds: newlyGranted,
      cardXpResults: cardXpResults,
    );
    lastCompletion = result;
    return result;
  }

  Future<List<String>> _grantReward(ClashCharacterEventReward reward) async {
    if (reward.isEmpty) {
      return const [];
    }

    final newlyGranted = <String>[];
    if (reward.coins > 0) {
      await _storyRepository.addCoins(reward.coins);
    }
    if (reward.gems > 0) {
      await _storyRepository.addGems(reward.gems);
    }

    final itemGrants = reward.toAchievementReward().toProductGrants();
    if (itemGrants.isNotEmpty) {
      await _grantService.grantProductGrants(itemGrants);
    }

    if (reward.featuredCardId != null) {
      newlyGranted.addAll(
        await _grantFeaturedCard(
          reward.featuredCardId!,
          asDuplicateOnly: reward.featuredCardAsDuplicate,
        ),
      );
    }
    return newlyGranted;
  }

  Future<List<String>> _grantFeaturedCard(
    String cardId, {
    required bool asDuplicateOnly,
  }) async {
    final owned = _collectionRepository.loadOwnedCardIds();
    if (!owned.contains(cardId)) {
      return _collectionRepository.grantMissingCardIds([cardId]);
    }
    if (asDuplicateOnly || owned.contains(cardId)) {
      await _collectionRepository.grantCardCopy(cardId);
    }
    return const [];
  }

  void clearCacheForTests() {
    _eventsCache = null;
    _stateCache = null;
    lastCompletion = null;
    _dataSource.clearCacheForTests();
  }

  Future<void> resetForTests() async {
    clearCacheForTests();
    await _storage.clear();
  }
}

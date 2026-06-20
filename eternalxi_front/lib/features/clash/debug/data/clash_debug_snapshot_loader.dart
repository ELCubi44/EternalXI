import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/debug/domain/clash_debug_snapshot.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carga el snapshot de diagnóstico local Clash (Fase 61).
class ClashDebugSnapshotLoader {
  const ClashDebugSnapshotLoader({
    required ClashPlayerCollectionStorageBackend collectionStorage,
    required ClashStoryRepository storyRepository,
    required ClashInventoryRepository inventoryRepository,
    required ClashCharacterEventsRepository eventsRepository,
    required ClashGachaRepository gachaRepository,
    required ClashGiftsRepository giftsRepository,
    required ClashDailyMissionsRepository dailyMissionsRepository,
    required ClashWeeklyMissionsRepository weeklyMissionsRepository,
    required ClashAchievementsRepository achievementsRepository,
    required ClashRewardHistoryRepository rewardHistoryRepository,
    SharedPreferences? sharedPreferences,
  }) : _collectionStorage = collectionStorage,
       _storyRepository = storyRepository,
       _inventoryRepository = inventoryRepository,
       _eventsRepository = eventsRepository,
       _gachaRepository = gachaRepository,
       _giftsRepository = giftsRepository,
       _dailyMissionsRepository = dailyMissionsRepository,
       _weeklyMissionsRepository = weeklyMissionsRepository,
       _achievementsRepository = achievementsRepository,
       _rewardHistoryRepository = rewardHistoryRepository,
       _sharedPreferences = sharedPreferences;

  final ClashPlayerCollectionStorageBackend _collectionStorage;
  final ClashStoryRepository _storyRepository;
  final ClashInventoryRepository _inventoryRepository;
  final ClashCharacterEventsRepository _eventsRepository;
  final ClashGachaRepository _gachaRepository;
  final ClashGiftsRepository _giftsRepository;
  final ClashDailyMissionsRepository _dailyMissionsRepository;
  final ClashWeeklyMissionsRepository _weeklyMissionsRepository;
  final ClashAchievementsRepository _achievementsRepository;
  final ClashRewardHistoryRepository _rewardHistoryRepository;
  final SharedPreferences? _sharedPreferences;

  Future<ClashDebugSnapshot> load() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    final schemaVersion =
        prefs.getInt(ClashSharedPreferencesKeys.schemaVersion) ??
        ClashStorageSchema.legacyUntrackedVersion;
    final lastMigratedAt = prefs.getString(
      ClashSharedPreferencesKeys.lastMigratedAt,
    );

    final collection = _readCollectionSummary();
    final inventory = await _inventoryRepository.fetchSummary();
    final events = await _loadEventSummary();
    final gacha = await _loadGachaSummary();
    final gifts = await _giftsRepository.fetchSummary();
    final daily = await _dailyMissionsRepository.fetchSummary();
    final weekly = await _weeklyMissionsRepository.fetchSummary();
    final achievements = await _achievementsRepository.fetchSummary();

    return ClashDebugSnapshot(
      schemaVersion: schemaVersion,
      lastMigratedAt: lastMigratedAt,
      rewardHistoryCount: _rewardHistoryRepository.loadEntries().length,
      collectionTotalCards: collection.totalCards,
      collectionUniqueCards: collection.uniqueCards,
      collectionDuplicateCopies: collection.duplicateCopies,
      walletCoins: _storyRepository.walletCoins(),
      walletGems: _storyRepository.walletGems(),
      expMaterialQuantity: inventory.quantityFor(ClashInventoryCategory.exp),
      techniqueBookQuantity: inventory.quantityFor(
        ClashInventoryCategory.technique,
      ),
      evolutionMaterialQuantity: inventory.quantityFor(
        ClashInventoryCategory.evolution,
      ),
      ticketQuantity: inventory.quantityFor(ClashInventoryCategory.tickets),
      totalEvents: events.totalEvents,
      eventsWithProgress: events.eventsWithProgress,
      eventProgress: events.eventProgress,
      gachaHistoryCount: gacha.historyCount,
      gachaPitySummaries: gacha.pitySummaries,
      gachaDailyAvailableCount: gacha.dailyAvailableCount,
      gachaDailyUsedCount: gacha.dailyUsedCount,
      giftsClaimed: gifts.claimedCount,
      giftsPending: gifts.pendingCount,
      giftsTotal: gifts.totalGifts,
      dailyMissionsCompleted: daily.completedCount,
      dailyMissionsClaimed: daily.claimedCount,
      dailyMissionsTotal: daily.totalMissions,
      weeklyMissionsCompleted: weekly.completedCount,
      weeklyMissionsClaimed: weekly.claimedCount,
      weeklyMissionsTotal: weekly.totalMissions,
      achievementsCompleted: achievements.completedCount,
      achievementsClaimed: achievements.claimedCount,
      achievementsTotal: achievements.totalAchievements,
    );
  }

  ({int totalCards, int uniqueCards, int duplicateCopies})
  _readCollectionSummary() {
    final snapshot = _collectionStorage.readSnapshot();
    var totalCards = 0;
    var duplicateCopies = 0;
    for (final cardId in snapshot.ownedCardIds) {
      final progress = snapshot.cardProgress[cardId];
      totalCards += progress?.totalCopies ?? 1;
      duplicateCopies += progress?.duplicateCopies ?? 0;
    }
    return (
      totalCards: totalCards,
      uniqueCards: snapshot.ownedCardIds.length,
      duplicateCopies: duplicateCopies,
    );
  }

  Future<
    ({
      int totalEvents,
      int eventsWithProgress,
      List<ClashDebugEventProgress> eventProgress,
    })
  >
  _loadEventSummary() async {
    final summaries = await _eventsRepository.fetchEventSummaries();
    final progress = summaries
        .map(
          (summary) => ClashDebugEventProgress(
            eventId: summary.event.id,
            eventTitle: summary.event.title,
            completedStages: summary.completedStages,
            totalStages: summary.totalStages,
          ),
        )
        .toList(growable: false);
    final withProgress = summaries
        .where((summary) => summary.completedStages > 0)
        .length;

    return (
      totalEvents: summaries.length,
      eventsWithProgress: withProgress,
      eventProgress: progress,
    );
  }

  Future<
    ({
      int historyCount,
      List<ClashDebugGachaPitySummary> pitySummaries,
      int dailyAvailableCount,
      int dailyUsedCount,
    })
  >
  _loadGachaSummary() async {
    final catalog = await _gachaRepository.fetchCatalog();
    final history = await _gachaRepository.loadHistory();
    final pitySummaries = <ClashDebugGachaPitySummary>[];
    var dailyAvailable = 0;
    var dailyUsed = 0;

    for (final banner in catalog.banners) {
      final pity = _gachaRepository.loadPityState(banner.id);
      pitySummaries.add(
        ClashDebugGachaPitySummary(
          bannerId: banner.id,
          pullsSinceLastPity: pity.pullsSinceLastPity,
          threshold: pity.threshold,
          totalPulls: pity.totalPulls,
        ),
      );
      if (_gachaRepository.isDailyAvailable(banner.id)) {
        dailyAvailable += 1;
      } else {
        dailyUsed += 1;
      }
    }

    return (
      historyCount: history.length,
      pitySummaries: pitySummaries,
      dailyAvailableCount: dailyAvailable,
      dailyUsedCount: dailyUsed,
    );
  }
}

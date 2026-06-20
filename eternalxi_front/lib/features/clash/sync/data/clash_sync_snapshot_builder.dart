import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_device_info.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fuentes inyectables para construir [ClashSyncSnapshot] sin red ni Provider.
///
/// Todos los backends son opcionales: los ausentes producen defaults seguros.
/// [gachaRepository] o [knownGachaBannerIds] permiten resolver pity/daily por banner.
class ClashSyncSnapshotBuilderDependencies {
  const ClashSyncSnapshotBuilderDependencies({
    this.sharedPreferences,
    this.schemaVersion,
    this.lastMigratedAt,
    this.collectionStorage,
    this.storyProgressStorage,
    this.expMaterialStorage,
    this.techniqueBookStorage,
    this.evolutionMaterialStorage,
    this.ticketInventoryStorage,
    this.lineupsStorage,
    this.giftsStorage,
    this.dailyMissionsStorage,
    this.weeklyMissionsStorage,
    this.achievementsStorage,
    this.characterEventsStorage,
    this.gachaHistoryStorage,
    this.gachaPityStorage,
    this.gachaDailyStorage,
    this.rewardHistoryStorage,
    this.gachaRepository,
    this.knownGachaBannerIds = const [],
  });

  final SharedPreferences? sharedPreferences;
  final int? schemaVersion;
  final String? lastMigratedAt;
  final ClashPlayerCollectionStorageBackend? collectionStorage;
  final ClashStoryProgressStorageBackend? storyProgressStorage;
  final ClashExpMaterialInventoryStorageBackend? expMaterialStorage;
  final ClashTechniqueBookInventoryStorageBackend? techniqueBookStorage;
  final ClashEvolutionMaterialInventoryStorageBackend? evolutionMaterialStorage;
  final ClashGachaTicketInventoryStorageBackend? ticketInventoryStorage;
  final ClashLineupsStorageBackend? lineupsStorage;
  final ClashGiftsStorageBackend? giftsStorage;
  final ClashDailyMissionsStorageBackend? dailyMissionsStorage;
  final ClashWeeklyMissionsStorageBackend? weeklyMissionsStorage;
  final ClashAchievementsStorageBackend? achievementsStorage;
  final ClashCharacterEventsStorageBackend? characterEventsStorage;
  final ClashGachaHistoryStorageBackend? gachaHistoryStorage;
  final ClashGachaPityStorageBackend? gachaPityStorage;
  final ClashGachaDailyStorageBackend? gachaDailyStorage;
  final ClashRewardHistoryStorageBackend? rewardHistoryStorage;
  final ClashGachaRepository? gachaRepository;
  final List<String> knownGachaBannerIds;
}

/// Construye [ClashSyncSnapshot] desde storages locales (Fase 65).
///
/// Solo lectura: no modifica persistencia ni realiza llamadas HTTP.
class ClashSyncSnapshotBuilder {
  const ClashSyncSnapshotBuilder({
    required this.dependencies,
    this.generatedAt,
    this.deviceInfo,
  });

  final ClashSyncSnapshotBuilderDependencies dependencies;
  final DateTime Function()? generatedAt;
  final ClashSyncDeviceInfo? deviceInfo;

  Future<ClashSyncSnapshot> build() async {
    final prefs = dependencies.sharedPreferences;
    final schemaVersion =
        dependencies.schemaVersion ??
        prefs?.getInt(ClashSharedPreferencesKeys.schemaVersion) ??
        ClashStorageSchema.legacyUntrackedVersion;
    final lastMigratedAt =
        dependencies.lastMigratedAt ??
        prefs?.getString(ClashSharedPreferencesKeys.lastMigratedAt);

    final timestamp = generatedAt?.call() ?? DateTime.now().toUtc();

    return ClashSyncSnapshot(
      generatedAt: timestamp,
      schemaVersion: schemaVersion,
      lastMigratedAt: lastMigratedAt,
      deviceInfo: deviceInfo,
      wallet: _buildWallet(),
      collection: _buildCollection(),
      inventories: _buildInventories(),
      lineups: _buildLineups(),
      storyProgress: _buildStoryProgress(),
      characterEventsProgress: _buildCharacterEventsProgress(),
      missionsProgress: _buildMissionsProgress(),
      achievementsProgress: _buildAchievementsProgress(),
      giftsProgress: _buildGiftsProgress(),
      gachaState: await _buildGachaState(),
      rewardHistorySummary: _buildRewardHistorySummary(),
    );
  }

  ClashSyncWallet _buildWallet() {
    final progress = dependencies.storyProgressStorage?.readProgress();
    if (progress == null) {
      return const ClashSyncWallet();
    }
    return ClashSyncWallet(
      coins: progress.walletCoins,
      gems: progress.walletGems,
    );
  }

  ClashSyncCollection _buildCollection() {
    final storage = dependencies.collectionStorage;
    if (storage == null) {
      return const ClashSyncCollection();
    }
    final snapshot = storage.readSnapshot();
    var totalCopies = 0;
    var duplicateCopies = 0;
    for (final cardId in snapshot.ownedCardIds) {
      final progress = snapshot.cardProgress[cardId];
      totalCopies += progress?.totalCopies ?? 1;
      duplicateCopies += progress?.duplicateCopies ?? 0;
    }
    return ClashSyncCollection(
      ownedCardIds: snapshot.ownedCardIds.toList(growable: false),
      uniqueCount: snapshot.ownedCardIds.length,
      totalCopies: totalCopies,
      duplicateCopies: duplicateCopies,
    );
  }

  ClashSyncInventories _buildInventories() {
    return ClashSyncInventories(
      expMaterials: Map<String, int>.from(
        dependencies.expMaterialStorage?.readSnapshot().quantities ?? const {},
      ),
      techniqueBooks: Map<String, int>.from(
        dependencies.techniqueBookStorage?.readSnapshot().quantities ??
            const {},
      ),
      evolutionMaterials: Map<String, int>.from(
        dependencies.evolutionMaterialStorage?.readSnapshot().quantities ??
            const {},
      ),
      tickets: Map<String, int>.from(
        dependencies.ticketInventoryStorage?.readQuantities() ?? const {},
      ),
    );
  }

  ClashSyncLineups _buildLineups() {
    final lineups = dependencies.lineupsStorage?.readLineups();
    if (lineups == null || lineups.isEmpty) {
      return const ClashSyncLineups();
    }
    final active = lineups.where((lineup) => lineup.isActive).toList();
    return ClashSyncLineups(
      lineupCount: lineups.length,
      activeLineupId: active.isNotEmpty ? active.first.id : null,
      completeLineupCount: lineups.where((lineup) => lineup.isComplete).length,
    );
  }

  ClashSyncStoryProgress _buildStoryProgress() {
    final progress =
        dependencies.storyProgressStorage?.readProgress() ??
        const ClashStoryProgress();
    return ClashSyncStoryProgress(
      completedLevelIds: progress.completedLevelIds.toList(growable: false),
      claimedRewardLevelIds: progress.claimedRewardLevelIds.toList(
        growable: false,
      ),
      claimedObjectiveRewardKeys: progress.claimedObjectiveRewardKeys.toList(
        growable: false,
      ),
      currentSagaId: progress.currentSagaId,
      currentChapterId: progress.currentChapterId,
      clashTeamUnlocked: progress.clashTeamUnlocked,
      eternalXiCardsGranted: progress.eternalXiCardsGranted,
    );
  }

  ClashSyncCharacterEventsProgress _buildCharacterEventsProgress() {
    final state = dependencies.characterEventsStorage?.readState();
    if (state == null) {
      return const ClashSyncCharacterEventsProgress();
    }
    return ClashSyncCharacterEventsProgress(
      completedStageIds: state.completedStageIds.toList(growable: false),
      claimedFirstClearRewardKeys: state.claimedFirstClearRewardKeys.toList(
        growable: false,
      ),
      clearCounts: Map<String, int>.from(state.clearCounts),
      lastPlayedAt: state.lastPlayedAt,
    );
  }

  ClashSyncMissionsProgress _buildMissionsProgress() {
    final daily = dependencies.dailyMissionsStorage?.readState();
    final weekly = dependencies.weeklyMissionsStorage?.readState();
    return ClashSyncMissionsProgress(
      dailyLocalDate: daily?.localDate ?? '',
      dailyProgress: Map<String, int>.from(daily?.progress ?? const {}),
      dailyClaimedMissionIds:
          daily?.claimedMissionIds.toList(growable: false) ?? const [],
      weeklyWeekKey: weekly?.weekKey ?? '',
      weeklyProgress: Map<String, int>.from(weekly?.progress ?? const {}),
      weeklyClaimedMissionIds:
          weekly?.claimedMissionIds.toList(growable: false) ?? const [],
    );
  }

  ClashSyncAchievementsProgress _buildAchievementsProgress() {
    final state = dependencies.achievementsStorage?.readState();
    if (state == null) {
      return const ClashSyncAchievementsProgress();
    }
    return ClashSyncAchievementsProgress(
      progress: Map<String, int>.from(state.progress),
      claimedAchievementIds: state.claimedAchievementIds.toList(
        growable: false,
      ),
      updatedAt: state.updatedAt,
    );
  }

  ClashSyncGiftsProgress _buildGiftsProgress() {
    final state = dependencies.giftsStorage?.readState();
    if (state == null) {
      return const ClashSyncGiftsProgress();
    }
    return ClashSyncGiftsProgress(
      claimedGiftIds: state.claimedGiftIds.toList(growable: false),
      lastOpenedAt: state.lastOpenedAt,
    );
  }

  Future<ClashSyncGachaState> _buildGachaState() async {
    final history = dependencies.gachaHistoryStorage?.readEntries() ?? const [];
    final bannerIds = await _resolveGachaBannerIds(history);
    final pityStates = <ClashSyncGachaPityState>[];
    final dailyDates = <String, String>{};
    final pityStorage = dependencies.gachaPityStorage;
    final dailyStorage = dependencies.gachaDailyStorage;

    for (final bannerId in bannerIds) {
      if (pityStorage != null) {
        final pity = pityStorage.readState(bannerId);
        if (pity != null) {
          pityStates.add(
            ClashSyncGachaPityState(
              bannerId: pity.bannerId,
              pullsSinceLastPity: pity.pullsSinceLastPity,
              pityThreshold: pity.threshold,
              totalPulls: pity.totalPulls,
              pityHits: pity.pityHits,
            ),
          );
        }
      }
      if (dailyStorage != null) {
        final date = dailyStorage.readLastUsedDate(bannerId);
        if (date != null && date.isNotEmpty) {
          dailyDates[bannerId] = date;
        }
      }
    }

    return ClashSyncGachaState(
      historyEntryCount: history.length,
      pityByBanner: pityStates,
      dailyLastUsedByBanner: dailyDates,
    );
  }

  Future<List<String>> _resolveGachaBannerIds(
    List<ClashGachaHistoryEntry> historyEntries,
  ) async {
    final ids = <String>{...dependencies.knownGachaBannerIds};
    for (final entry in historyEntries) {
      if (entry.bannerId.isNotEmpty) {
        ids.add(entry.bannerId);
      }
    }
    final repository = dependencies.gachaRepository;
    if (repository != null) {
      final catalog = await repository.fetchCatalog();
      ids.addAll(catalog.banners.map((banner) => banner.id));
    }
    return ids.toList(growable: false);
  }

  ClashSyncRewardHistorySummary _buildRewardHistorySummary() {
    final entries =
        dependencies.rewardHistoryStorage?.readEntries() ?? const [];
    if (entries.isEmpty) {
      return const ClashSyncRewardHistorySummary();
    }
    var partialCount = 0;
    var failureCount = 0;
    for (final entry in entries) {
      if (entry.isPartial) {
        partialCount += 1;
      }
      if (entry.isFailure) {
        failureCount += 1;
      }
    }
    return ClashSyncRewardHistorySummary(
      entryCount: entries.length,
      latestEntryAt: entries.first.createdAt.toUtc().toIso8601String(),
      partialCount: partialCount,
      failureCount: failureCount,
    );
  }
}

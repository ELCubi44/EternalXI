import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_service.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_completion_unlocks.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_section.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependencias inyectables para [ClashSyncSnapshotApplier].
class ClashSyncSnapshotApplierDependencies {
  const ClashSyncSnapshotApplierDependencies({
    required this.sharedPreferences,
    this.collectionStorage,
    this.storyProgressStorage,
    this.expMaterialStorage,
    this.techniqueBookStorage,
    this.evolutionMaterialStorage,
    this.ticketInventoryStorage,
    this.dailyMissionsStorage,
    this.weeklyMissionsStorage,
    this.achievementsStorage,
    this.giftsStorage,
    this.characterEventsStorage,
    this.gachaHistoryStorage,
    this.gachaPityStorage,
    this.gachaDailyStorage,
    this.rewardHistoryStorage,
  });

  final SharedPreferences sharedPreferences;
  final ClashPlayerCollectionStorageBackend? collectionStorage;
  final ClashStoryProgressStorageBackend? storyProgressStorage;
  final ClashExpMaterialInventoryStorageBackend? expMaterialStorage;
  final ClashTechniqueBookInventoryStorageBackend? techniqueBookStorage;
  final ClashEvolutionMaterialInventoryStorageBackend? evolutionMaterialStorage;
  final ClashGachaTicketInventoryStorageBackend? ticketInventoryStorage;
  final ClashDailyMissionsStorageBackend? dailyMissionsStorage;
  final ClashWeeklyMissionsStorageBackend? weeklyMissionsStorage;
  final ClashAchievementsStorageBackend? achievementsStorage;
  final ClashGiftsStorageBackend? giftsStorage;
  final ClashCharacterEventsStorageBackend? characterEventsStorage;
  final ClashGachaHistoryStorageBackend? gachaHistoryStorage;
  final ClashGachaPityStorageBackend? gachaPityStorage;
  final ClashGachaDailyStorageBackend? gachaDailyStorage;
  final ClashRewardHistoryStorageBackend? rewardHistoryStorage;
}

/// Aplica manualmente un [ClashSyncSnapshot] remoto al almacenamiento local (Fase 73).
///
/// Flujo: backup → validar remoto → preparar payloads → escribir en orden.
/// No se invoca automáticamente tras pull ni login.
class ClashSyncSnapshotApplier {
  const ClashSyncSnapshotApplier({
    required this.builder,
    required this.validator,
    required this.dependencies,
    this.now,
  });

  final ClashSyncSnapshotBuilder builder;
  final ClashSyncSnapshotValidator validator;
  final ClashSyncSnapshotApplierDependencies dependencies;
  final DateTime Function()? now;

  Future<ClashSyncApplyResult> applyRemoteSnapshot(
    ClashSyncSnapshot remote, {
    int? serverRevision,
  }) async {
    final appliedAt = _now();

    final support = _checkRequiredBackends();
    if (support != null) {
      return ClashSyncApplyResult(
        status: ClashSyncApplyStatus.unsupported,
        appliedAt: appliedAt,
        message: support,
        errorCode: 'missing_backend',
      );
    }

    final validation = validator.validate(remote);
    if (!validation.isValid) {
      return ClashSyncApplyResult(
        status: ClashSyncApplyStatus.validationFailed,
        appliedAt: appliedAt,
        validationResult: validation,
        message: 'Remote snapshot validation failed',
        errorCode: 'validation_failed',
      );
    }

    final localSnapshot = await builder.build();
    final backupStore = ClashSyncLocalBackupStore(
      sharedPreferences: dependencies.sharedPreferences,
    );
    final backupCreated = await backupStore.save(
      ClashSyncLocalBackup(
        generatedAt: appliedAt,
        source: ClashSyncLocalBackup.sourceBeforeRemoteApply,
        snapshot: localSnapshot,
        serverRevision: serverRevision,
      ),
    );
    if (!backupCreated) {
      return ClashSyncApplyResult(
        status: ClashSyncApplyStatus.backupFailed,
        appliedAt: appliedAt,
        validationResult: validation,
        message: 'Could not create local backup',
        errorCode: 'backup_failed',
      );
    }

    final skippedSections = <String>[];
    _collectSkippedSections(remote, skippedSections);

    try {
      final appliedSections = await _writeRemoteSnapshot(
        remote,
        skippedSections,
      );
      return ClashSyncApplyResult(
        status: ClashSyncApplyStatus.success,
        appliedAt: appliedAt,
        backupCreated: true,
        appliedSections: appliedSections,
        skippedSections: skippedSections,
        validationResult: validation,
        message: 'Remote snapshot applied locally',
      );
    } catch (error) {
      return ClashSyncApplyResult(
        status: ClashSyncApplyStatus.applyFailed,
        appliedAt: appliedAt,
        backupCreated: true,
        skippedSections: skippedSections,
        validationResult: validation,
        message: error.toString(),
        errorCode: 'apply_failed',
      );
    }
  }

  String? _checkRequiredBackends() {
    final deps = dependencies;
    if (deps.storyProgressStorage == null) {
      return 'Story progress storage unavailable';
    }
    if (deps.collectionStorage == null) {
      return 'Collection storage unavailable';
    }
    if (deps.expMaterialStorage == null ||
        deps.techniqueBookStorage == null ||
        deps.evolutionMaterialStorage == null ||
        deps.ticketInventoryStorage == null) {
      return 'Inventory storage unavailable';
    }
    if (deps.dailyMissionsStorage == null ||
        deps.weeklyMissionsStorage == null) {
      return 'Missions storage unavailable';
    }
    if (deps.achievementsStorage == null ||
        deps.giftsStorage == null ||
        deps.characterEventsStorage == null) {
      return 'Progress storage unavailable';
    }
    if (deps.gachaPityStorage == null || deps.gachaDailyStorage == null) {
      return 'Gacha storage unavailable';
    }
    return null;
  }

  void _collectSkippedSections(
    ClashSyncSnapshot remote,
    List<String> skippedSections,
  ) {
    if (remote.lineups.lineupCount > 0 ||
        remote.lineups.activeLineupId != null) {
      skippedSections.add(ClashSyncApplySection.lineups);
    }
    if (remote.gachaState.historyEntryCount > 0) {
      skippedSections.add(ClashSyncApplySection.gachaHistory);
    }
    if (remote.rewardHistorySummary.entryCount > 0) {
      skippedSections.add(ClashSyncApplySection.rewardHistory);
    }
    if (remote.collection.ownedCardIds.isNotEmpty) {
      skippedSections.add(ClashSyncApplySection.collectionCardProgress);
    }
  }

  Future<List<String>> _writeRemoteSnapshot(
    ClashSyncSnapshot remote,
    List<String> skippedSections,
  ) async {
    final applied = <String>[];
    final deps = dependencies;

    await _applyWalletAndStory(remote);
    applied.add(ClashSyncApplySection.wallet);
    applied.add(ClashSyncApplySection.storyProgress);

    await _applyCollection(remote);
    applied.add(ClashSyncApplySection.collection);

    await _applyInventories(remote);
    applied.add(ClashSyncApplySection.inventories);

    await _applyCharacterEvents(remote);
    applied.add(ClashSyncApplySection.characterEventsProgress);

    await _applyMissions(remote);
    applied.add(ClashSyncApplySection.missionsProgress);

    await _applyAchievements(remote);
    applied.add(ClashSyncApplySection.achievementsProgress);

    await _applyGifts(remote);
    applied.add(ClashSyncApplySection.giftsProgress);

    await _applyGachaPity(remote);
    applied.add(ClashSyncApplySection.gachaPity);

    await _applyGachaDaily(remote);
    applied.add(ClashSyncApplySection.gachaDaily);

    if (!skippedSections.contains(ClashSyncApplySection.gachaHistory) &&
        deps.gachaHistoryStorage != null) {
      await deps.gachaHistoryStorage!.writeEntries(const []);
      applied.add(ClashSyncApplySection.gachaHistory);
    }

    if (!skippedSections.contains(ClashSyncApplySection.rewardHistory) &&
        deps.rewardHistoryStorage != null) {
      await deps.rewardHistoryStorage!.writeEntries(const []);
      applied.add(ClashSyncApplySection.rewardHistory);
    }

    await _applySchemaMetadata(remote);
    applied.add(ClashSyncApplySection.schemaMetadata);

    return applied;
  }

  Future<void> _applyWalletAndStory(ClashSyncSnapshot remote) async {
    final storage = dependencies.storyProgressStorage!;
    final existing = storage.readProgress();
    final story = remote.storyProgress;

    await storage.writeProgress(
      existing.copyWith(
        walletCoins: remote.wallet.coins,
        walletGems: remote.wallet.gems,
        completedLevelIds: story.completedLevelIds.toSet(),
        claimedRewardLevelIds: story.claimedRewardLevelIds.toSet(),
        claimedObjectiveRewardKeys: story.claimedObjectiveRewardKeys.toSet(),
        currentSagaId: story.currentSagaId,
        currentChapterId: story.currentChapterId,
        eternalXiCardsGranted: story.eternalXiCardsGranted,
        unlocks: ClashStoryCompletionUnlocks(
          clashTeamUnlocked: story.clashTeamUnlocked,
          firstLineupUnlocked: existing.unlocks.firstLineupUnlocked,
          nextPlayableLevelUnlocked: existing.unlocks.nextPlayableLevelUnlocked,
        ),
      ),
    );
  }

  Future<void> _applyCollection(ClashSyncSnapshot remote) async {
    final storage = dependencies.collectionStorage!;
    final existing = storage.readSnapshot();
    final owned = remote.collection.ownedCardIds.toSet();
    final progress = <String, ClashCardProgress>{};
    for (final cardId in owned) {
      progress[cardId] =
          existing.cardProgress[cardId] ??
          ClashCardXpService.initialProgress(cardId);
    }
    await storage.writeSnapshot(
      ClashPlayerCollectionSnapshot(
        ownedCardIds: owned,
        cardProgress: progress,
      ),
    );
  }

  Future<void> _applyInventories(ClashSyncSnapshot remote) async {
    final inventories = remote.inventories;
    await dependencies.expMaterialStorage!.writeSnapshot(
      ClashExpMaterialInventorySnapshot(
        quantities: Map<String, int>.from(inventories.expMaterials),
      ),
    );
    await dependencies.techniqueBookStorage!.writeSnapshot(
      ClashTechniqueBookInventorySnapshot(
        quantities: Map<String, int>.from(inventories.techniqueBooks),
      ),
    );
    await dependencies.evolutionMaterialStorage!.writeSnapshot(
      ClashEvolutionMaterialInventorySnapshot(
        quantities: Map<String, int>.from(inventories.evolutionMaterials),
      ),
    );
    await dependencies.ticketInventoryStorage!.writeQuantities(
      Map<String, int>.from(inventories.tickets),
    );
  }

  Future<void> _applyCharacterEvents(ClashSyncSnapshot remote) async {
    final events = remote.characterEventsProgress;
    await dependencies.characterEventsStorage!.writeState(
      ClashCharacterEventsProgressState(
        completedStageIds: events.completedStageIds.toSet(),
        claimedFirstClearRewardKeys: events.claimedFirstClearRewardKeys.toSet(),
        clearCounts: Map<String, int>.from(events.clearCounts),
        lastPlayedAt: events.lastPlayedAt,
      ),
    );
  }

  Future<void> _applyMissions(ClashSyncSnapshot remote) async {
    final missions = remote.missionsProgress;
    await dependencies.dailyMissionsStorage!.writeState(
      ClashDailyMissionsDayState(
        localDate: missions.dailyLocalDate,
        progress: Map<String, int>.from(missions.dailyProgress),
        claimedMissionIds: missions.dailyClaimedMissionIds.toSet(),
      ),
    );
    await dependencies.weeklyMissionsStorage!.writeState(
      ClashWeeklyMissionsWeekState(
        weekKey: missions.weeklyWeekKey,
        progress: Map<String, int>.from(missions.weeklyProgress),
        claimedMissionIds: missions.weeklyClaimedMissionIds.toSet(),
      ),
    );
  }

  Future<void> _applyAchievements(ClashSyncSnapshot remote) async {
    final achievements = remote.achievementsProgress;
    await dependencies.achievementsStorage!.writeState(
      ClashAchievementsState(
        progress: Map<String, int>.from(achievements.progress),
        claimedAchievementIds: achievements.claimedAchievementIds.toSet(),
        updatedAt: achievements.updatedAt,
      ),
    );
  }

  Future<void> _applyGifts(ClashSyncSnapshot remote) async {
    final gifts = remote.giftsProgress;
    await dependencies.giftsStorage!.writeState(
      ClashGiftsState(
        claimedGiftIds: gifts.claimedGiftIds.toSet(),
        lastOpenedAt: gifts.lastOpenedAt,
      ),
    );
  }

  Future<void> _applyGachaPity(ClashSyncSnapshot remote) async {
    final storage = dependencies.gachaPityStorage!;
    for (final pity in remote.gachaState.pityByBanner) {
      if (pity.bannerId.isEmpty) {
        continue;
      }
      await storage.writeState(
        ClashGachaPityState(
          bannerId: pity.bannerId,
          pullsSinceLastPity: pity.pullsSinceLastPity,
          threshold: pity.pityThreshold,
          totalPulls: pity.totalPulls,
          pityHits: pity.pityHits,
        ),
      );
    }
  }

  Future<void> _applyGachaDaily(ClashSyncSnapshot remote) async {
    final storage = dependencies.gachaDailyStorage!;
    for (final entry in remote.gachaState.dailyLastUsedByBanner.entries) {
      if (entry.key.isEmpty || entry.value.isEmpty) {
        continue;
      }
      await storage.writeLastUsedDate(entry.key, entry.value);
    }
  }

  Future<void> _applySchemaMetadata(ClashSyncSnapshot remote) async {
    final prefs = dependencies.sharedPreferences;
    await prefs.setInt(
      ClashSharedPreferencesKeys.schemaVersion,
      remote.schemaVersion,
    );
    final migratedAt = remote.lastMigratedAt;
    if (migratedAt != null && migratedAt.isNotEmpty) {
      await prefs.setString(
        ClashSharedPreferencesKeys.lastMigratedAt,
        migratedAt,
      );
    }
  }

  DateTime _now() => now?.call() ?? DateTime.now().toUtc();
}

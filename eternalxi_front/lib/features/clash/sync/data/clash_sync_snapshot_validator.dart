import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_contract_version.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_validation_result.dart';

/// Catálogos opcionales para validar IDs contra contenido conocido.
///
/// Si un catálogo no se proporciona, no se falla por IDs desconocidos;
/// puede emitirse un [ClashSyncValidationSeverity.warning].
class ClashSyncSnapshotValidatorCatalogs {
  const ClashSyncSnapshotValidatorCatalogs({
    this.knownCardIds = const {},
    this.knownEventIds = const {},
    this.knownEventStageIdsByEvent = const {},
    this.knownMissionIds = const {},
    this.knownAchievementIds = const {},
    this.knownGiftIds = const {},
    this.knownBannerIds = const {},
    this.knownRewardItemIds = const {},
    this.knownExpMaterialIds = const {},
    this.knownTechniqueBookIds = const {},
    this.knownEvolutionMaterialIds = const {},
    this.knownTicketIds = const {},
    this.lineupSlotsByLineupId = const {},
  });

  final Set<String> knownCardIds;
  final Set<String> knownEventIds;
  final Map<String, Set<String>> knownEventStageIdsByEvent;
  final Set<String> knownMissionIds;
  final Set<String> knownAchievementIds;
  final Set<String> knownGiftIds;
  final Set<String> knownBannerIds;
  final Set<String> knownRewardItemIds;
  final Set<String> knownExpMaterialIds;
  final Set<String> knownTechniqueBookIds;
  final Set<String> knownEvolutionMaterialIds;
  final Set<String> knownTicketIds;

  /// `lineupId` → `position` → `cardId` (null o vacío = slot vacío).
  final Map<String, Map<String, String?>> lineupSlotsByLineupId;

  bool get hasCardCatalog => knownCardIds.isNotEmpty;

  bool get hasEventStageCatalog => knownEventStageIdsByEvent.isNotEmpty;

  Set<String> get allKnownEventStageIds =>
      knownEventStageIdsByEvent.values.expand((stages) => stages).toSet();
}

/// Validador local de [ClashSyncSnapshot] antes de una futura sync (Fase 66).
///
/// Solo lectura; no repara datos ni realiza llamadas HTTP.
class ClashSyncSnapshotValidator {
  const ClashSyncSnapshotValidator({
    this.catalogs = const ClashSyncSnapshotValidatorCatalogs(),
    this.checkedAt,
  });

  final ClashSyncSnapshotValidatorCatalogs catalogs;
  final DateTime Function()? checkedAt;

  ClashSyncValidationResult validate(ClashSyncSnapshot snapshot) {
    final errors = <ClashSyncValidationIssue>[];
    final warnings = <ClashSyncValidationIssue>[];

    _validateContract(snapshot, errors);
    _validateWallet(snapshot.wallet, errors);
    _validateInventories(snapshot.inventories, errors, warnings);
    _validateCollection(snapshot.collection, errors, warnings);
    _validateLineups(snapshot.lineups, snapshot.collection, errors, warnings);
    _validateStoryProgress(snapshot.storyProgress, errors);
    _validateCharacterEventsProgress(
      snapshot.characterEventsProgress,
      errors,
      warnings,
    );
    _validateMissionsProgress(snapshot.missionsProgress, errors, warnings);
    _validateAchievementsProgress(
      snapshot.achievementsProgress,
      errors,
      warnings,
    );
    _validateGiftsProgress(snapshot.giftsProgress, errors, warnings);
    _validateGachaState(snapshot.gachaState, errors, warnings);
    _validateRewardHistorySummary(snapshot.rewardHistorySummary, errors);

    return ClashSyncValidationResult(
      errors: errors,
      warnings: warnings,
      checkedAt: checkedAt?.call() ?? DateTime.now().toUtc(),
    );
  }

  void _validateContract(
    ClashSyncSnapshot snapshot,
    List<ClashSyncValidationIssue> errors,
  ) {
    if (snapshot.contractVersion != ClashSyncContractVersion.current) {
      errors.add(
        ClashSyncValidationIssue(
          code: 'invalid_contract_version',
          message:
              'contractVersion ${snapshot.contractVersion} != '
              '${ClashSyncContractVersion.current}',
          path: 'contractVersion',
        ),
      );
    }
    if (snapshot.schemaVersion < ClashStorageSchema.currentVersion) {
      errors.add(
        ClashSyncValidationIssue(
          code: 'invalid_schema_version',
          message:
              'schemaVersion ${snapshot.schemaVersion} < '
              '${ClashStorageSchema.currentVersion}',
          path: 'schemaVersion',
        ),
      );
    }
  }

  void _validateWallet(
    ClashSyncWallet wallet,
    List<ClashSyncValidationIssue> errors,
  ) {
    if (wallet.coins < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_wallet_coins',
          message: 'coins must be >= 0',
          path: 'wallet.coins',
        ),
      );
    }
    if (wallet.gems < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_wallet_gems',
          message: 'gems must be >= 0',
          path: 'wallet.gems',
        ),
      );
    }
  }

  void _validateInventories(
    ClashSyncInventories inventories,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    _validateQuantityMap(
      inventories.expMaterials,
      'inventories.expMaterials',
      errors,
    );
    _validateQuantityMap(
      inventories.techniqueBooks,
      'inventories.techniqueBooks',
      errors,
    );
    _validateQuantityMap(
      inventories.evolutionMaterials,
      'inventories.evolutionMaterials',
      errors,
    );
    _validateQuantityMap(inventories.tickets, 'inventories.tickets', errors);

    _validateKnownInventoryIds(
      inventories.expMaterials.keys,
      catalogs.knownExpMaterialIds,
      'inventories.expMaterials',
      'exp material',
      errors,
      warnings,
    );
    _validateKnownInventoryIds(
      inventories.techniqueBooks.keys,
      catalogs.knownTechniqueBookIds,
      'inventories.techniqueBooks',
      'technique book',
      errors,
      warnings,
    );
    _validateKnownInventoryIds(
      inventories.evolutionMaterials.keys,
      catalogs.knownEvolutionMaterialIds,
      'inventories.evolutionMaterials',
      'evolution material',
      errors,
      warnings,
    );
    _validateKnownInventoryIds(
      inventories.tickets.keys,
      catalogs.knownTicketIds,
      'inventories.tickets',
      'ticket',
      errors,
      warnings,
    );
  }

  void _validateQuantityMap(
    Map<String, int> quantities,
    String pathPrefix,
    List<ClashSyncValidationIssue> errors,
  ) {
    for (final entry in quantities.entries) {
      if (entry.key.isEmpty) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'empty_inventory_item_id',
            message: 'inventory item id must not be empty',
            path: '$pathPrefix[]',
          ),
        );
      }
      if (entry.value < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'negative_inventory_quantity',
            message: 'quantity for ${entry.key} must be >= 0',
            path: '$pathPrefix.${entry.key}',
          ),
        );
      }
    }
  }

  void _validateCollection(
    ClashSyncCollection collection,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    if (collection.duplicateCopies < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_duplicate_copies',
          message: 'duplicateCopies must be >= 0',
          path: 'collection.duplicateCopies',
        ),
      );
    }
    if (collection.totalCopies < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_total_copies',
          message: 'totalCopies must be >= 0',
          path: 'collection.totalCopies',
        ),
      );
    }
    if (collection.uniqueCount != collection.ownedCardIds.length) {
      errors.add(
        ClashSyncValidationIssue(
          code: 'collection_unique_count_mismatch',
          message:
              'uniqueCount (${collection.uniqueCount}) != '
              'ownedCardIds.length (${collection.ownedCardIds.length})',
          path: 'collection.uniqueCount',
        ),
      );
    }
    if (collection.totalCopies > 0 &&
        collection.totalCopies < collection.uniqueCount) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'collection_total_copies_inconsistent',
          message: 'totalCopies must be >= uniqueCount when non-zero',
          path: 'collection.totalCopies',
        ),
      );
    }

    for (final cardId in collection.ownedCardIds) {
      if (cardId.isEmpty) {
        errors.add(
          const ClashSyncValidationIssue(
            code: 'empty_collection_card_id',
            message: 'owned card id must not be empty',
            path: 'collection.ownedCardIds[]',
          ),
        );
      }
    }

    if (collection.ownedCardIds.isNotEmpty && !catalogs.hasCardCatalog) {
      warnings.add(
        const ClashSyncValidationIssue(
          code: 'catalog_missing_card_ids',
          message: 'Card catalog not provided; skipping card ID validation',
          path: 'collection.ownedCardIds',
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
    } else {
      for (final cardId in collection.ownedCardIds) {
        if (cardId.isNotEmpty && !catalogs.knownCardIds.contains(cardId)) {
          errors.add(
            ClashSyncValidationIssue(
              code: 'unknown_card_id',
              message: 'Unknown card id: $cardId',
              path: 'collection.ownedCardIds.$cardId',
            ),
          );
        }
      }
    }
  }

  void _validateLineups(
    ClashSyncLineups lineups,
    ClashSyncCollection collection,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    if (lineups.lineupCount < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_lineup_count',
          message: 'lineupCount must be >= 0',
          path: 'lineups.lineupCount',
        ),
      );
    }
    if (lineups.completeLineupCount < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_complete_lineup_count',
          message: 'completeLineupCount must be >= 0',
          path: 'lineups.completeLineupCount',
        ),
      );
    }
    if (lineups.completeLineupCount > lineups.lineupCount) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'lineup_complete_count_exceeds_total',
          message: 'completeLineupCount must be <= lineupCount',
          path: 'lineups.completeLineupCount',
        ),
      );
    }
    if (lineups.activeLineupId != null && lineups.activeLineupId!.isEmpty) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'empty_active_lineup_id',
          message: 'activeLineupId must not be empty when set',
          path: 'lineups.activeLineupId',
        ),
      );
    }

    final slotsByLineup = catalogs.lineupSlotsByLineupId;
    if (slotsByLineup.isEmpty) {
      if (lineups.lineupCount > 0) {
        warnings.add(
          const ClashSyncValidationIssue(
            code: 'catalog_missing_lineup_slots',
            message:
                'Lineup slot catalog not provided; skipping card reference checks',
            path: 'lineups',
            severity: ClashSyncValidationSeverity.warning,
          ),
        );
      }
      return;
    }

    final owned = collection.ownedCardIds.toSet();
    for (final entry in slotsByLineup.entries) {
      final lineupId = entry.key;
      for (final slotEntry in entry.value.entries) {
        final cardId = slotEntry.value;
        if (cardId == null || cardId.isEmpty) {
          continue;
        }
        if (catalogs.hasCardCatalog &&
            !catalogs.knownCardIds.contains(cardId)) {
          errors.add(
            ClashSyncValidationIssue(
              code: 'unknown_lineup_card_id',
              message: 'Lineup $lineupId references unknown card: $cardId',
              path: 'lineups.$lineupId.${slotEntry.key}',
            ),
          );
        } else if (!owned.contains(cardId)) {
          errors.add(
            ClashSyncValidationIssue(
              code: 'lineup_card_not_owned',
              message: 'Lineup $lineupId references unowned card: $cardId',
              path: 'lineups.$lineupId.${slotEntry.key}',
            ),
          );
        }
      }
    }
  }

  void _validateStoryProgress(
    ClashSyncStoryProgress progress,
    List<ClashSyncValidationIssue> errors,
  ) {
    _validateNonEmptyIds(
      progress.completedLevelIds,
      'storyProgress.completedLevelIds',
      'completed level',
      errors,
    );
    _validateNonEmptyIds(
      progress.claimedRewardLevelIds,
      'storyProgress.claimedRewardLevelIds',
      'claimed reward level',
      errors,
    );
    _validateNonEmptyIds(
      progress.claimedObjectiveRewardKeys,
      'storyProgress.claimedObjectiveRewardKeys',
      'claimed objective reward',
      errors,
    );
  }

  void _validateCharacterEventsProgress(
    ClashSyncCharacterEventsProgress progress,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    _validateNonEmptyIds(
      progress.completedStageIds,
      'characterEventsProgress.completedStageIds',
      'completed stage',
      errors,
    );
    _validateNonEmptyIds(
      progress.claimedFirstClearRewardKeys,
      'characterEventsProgress.claimedFirstClearRewardKeys',
      'claimed first clear reward',
      errors,
    );

    for (final entry in progress.clearCounts.entries) {
      if (entry.key.isEmpty) {
        errors.add(
          const ClashSyncValidationIssue(
            code: 'empty_event_stage_id',
            message: 'clearCounts stage id must not be empty',
            path: 'characterEventsProgress.clearCounts[]',
          ),
        );
      }
      if (entry.value < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'negative_clear_count',
            message: 'clear count for ${entry.key} must be >= 0',
            path: 'characterEventsProgress.clearCounts.${entry.key}',
          ),
        );
      }
    }

    if (progress.completedStageIds.isNotEmpty &&
        !catalogs.hasEventStageCatalog) {
      warnings.add(
        const ClashSyncValidationIssue(
          code: 'catalog_missing_event_stages',
          message:
              'Event stage catalog not provided; skipping stage ID validation',
          path: 'characterEventsProgress.completedStageIds',
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
    } else if (catalogs.hasEventStageCatalog) {
      final knownStages = catalogs.allKnownEventStageIds;
      for (final stageId in progress.completedStageIds) {
        if (stageId.isNotEmpty && !knownStages.contains(stageId)) {
          errors.add(
            ClashSyncValidationIssue(
              code: 'unknown_event_stage_id',
              message: 'Unknown event stage id: $stageId',
              path: 'characterEventsProgress.completedStageIds.$stageId',
            ),
          );
        }
      }
      if (catalogs.knownEventIds.isNotEmpty) {
        for (final eventId in catalogs.knownEventIds) {
          if (eventId.isEmpty) {
            errors.add(
              const ClashSyncValidationIssue(
                code: 'empty_event_id_in_catalog',
                message: 'known event id must not be empty',
                path: 'catalog.knownEventIds[]',
              ),
            );
          }
        }
      }
    }
  }

  void _validateMissionsProgress(
    ClashSyncMissionsProgress progress,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    for (final entry in progress.dailyProgress.entries) {
      if (entry.key.isEmpty || entry.value < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: entry.value < 0
                ? 'negative_mission_progress'
                : 'empty_mission_id',
            message: entry.value < 0
                ? 'daily progress for ${entry.key} must be >= 0'
                : 'daily mission id must not be empty',
            path: 'missionsProgress.dailyProgress.${entry.key}',
          ),
        );
      }
    }
    for (final entry in progress.weeklyProgress.entries) {
      if (entry.key.isEmpty || entry.value < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: entry.value < 0
                ? 'negative_mission_progress'
                : 'empty_mission_id',
            message: entry.value < 0
                ? 'weekly progress for ${entry.key} must be >= 0'
                : 'weekly mission id must not be empty',
            path: 'missionsProgress.weeklyProgress.${entry.key}',
          ),
        );
      }
    }

    _validateKnownMissionIds(
      progress.dailyClaimedMissionIds,
      'missionsProgress.dailyClaimedMissionIds',
      errors,
      warnings,
    );
    _validateKnownMissionIds(
      progress.weeklyClaimedMissionIds,
      'missionsProgress.weeklyClaimedMissionIds',
      errors,
      warnings,
    );
  }

  void _validateAchievementsProgress(
    ClashSyncAchievementsProgress progress,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    for (final entry in progress.progress.entries) {
      if (entry.key.isEmpty || entry.value < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: entry.value < 0
                ? 'negative_achievement_progress'
                : 'empty_achievement_id',
            message: entry.value < 0
                ? 'achievement progress for ${entry.key} must be >= 0'
                : 'achievement id must not be empty',
            path: 'achievementsProgress.progress.${entry.key}',
          ),
        );
      }
    }

    _validateNonEmptyIds(
      progress.claimedAchievementIds,
      'achievementsProgress.claimedAchievementIds',
      'claimed achievement',
      errors,
    );

    if (progress.claimedAchievementIds.isNotEmpty &&
        catalogs.knownAchievementIds.isEmpty) {
      warnings.add(
        const ClashSyncValidationIssue(
          code: 'catalog_missing_achievement_ids',
          message:
              'Achievement catalog not provided; skipping achievement ID validation',
          path: 'achievementsProgress.claimedAchievementIds',
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
    } else {
      for (final id in progress.claimedAchievementIds) {
        if (id.isNotEmpty && !catalogs.knownAchievementIds.contains(id)) {
          errors.add(
            ClashSyncValidationIssue(
              code: 'unknown_achievement_id',
              message: 'Unknown achievement id: $id',
              path: 'achievementsProgress.claimedAchievementIds.$id',
            ),
          );
        }
      }
    }
  }

  void _validateGiftsProgress(
    ClashSyncGiftsProgress progress,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    _validateNonEmptyIds(
      progress.claimedGiftIds,
      'giftsProgress.claimedGiftIds',
      'claimed gift',
      errors,
    );

    if (progress.claimedGiftIds.isNotEmpty && catalogs.knownGiftIds.isEmpty) {
      warnings.add(
        const ClashSyncValidationIssue(
          code: 'catalog_missing_gift_ids',
          message: 'Gift catalog not provided; skipping gift ID validation',
          path: 'giftsProgress.claimedGiftIds',
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
    } else {
      for (final id in progress.claimedGiftIds) {
        if (id.isNotEmpty && !catalogs.knownGiftIds.contains(id)) {
          errors.add(
            ClashSyncValidationIssue(
              code: 'unknown_gift_id',
              message: 'Unknown gift id: $id',
              path: 'giftsProgress.claimedGiftIds.$id',
            ),
          );
        }
      }
    }
  }

  void _validateGachaState(
    ClashSyncGachaState gacha,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    if (gacha.historyEntryCount < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_gacha_history_count',
          message: 'historyEntryCount must be >= 0',
          path: 'gachaState.historyEntryCount',
        ),
      );
    }

    for (final pity in gacha.pityByBanner) {
      if (pity.bannerId.isEmpty) {
        errors.add(
          const ClashSyncValidationIssue(
            code: 'empty_gacha_banner_id',
            message: 'gacha pity bannerId must not be empty',
            path: 'gachaState.pityByBanner[].bannerId',
          ),
        );
      }
      if (pity.pullsSinceLastPity < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'negative_gacha_pity_counter',
            message: 'pullsSinceLastPity for ${pity.bannerId} must be >= 0',
            path: 'gachaState.pityByBanner.${pity.bannerId}.pullsSinceLastPity',
          ),
        );
      }
      if (pity.totalPulls < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'negative_gacha_total_pulls',
            message: 'totalPulls for ${pity.bannerId} must be >= 0',
            path: 'gachaState.pityByBanner.${pity.bannerId}.totalPulls',
          ),
        );
      }
      if (pity.pityHits < 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'negative_gacha_pity_hits',
            message: 'pityHits for ${pity.bannerId} must be >= 0',
            path: 'gachaState.pityByBanner.${pity.bannerId}.pityHits',
          ),
        );
      }
      if (pity.pityThreshold <= 0) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'invalid_gacha_pity_threshold',
            message: 'pityThreshold for ${pity.bannerId} must be > 0',
            path: 'gachaState.pityByBanner.${pity.bannerId}.pityThreshold',
          ),
        );
      }
      if (catalogs.knownBannerIds.isNotEmpty &&
          pity.bannerId.isNotEmpty &&
          !catalogs.knownBannerIds.contains(pity.bannerId)) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'unknown_gacha_banner_id',
            message: 'Unknown gacha banner id: ${pity.bannerId}',
            path: 'gachaState.pityByBanner.${pity.bannerId}',
          ),
        );
      }
    }

    for (final entry in gacha.dailyLastUsedByBanner.entries) {
      if (entry.key.isEmpty) {
        errors.add(
          const ClashSyncValidationIssue(
            code: 'empty_gacha_daily_banner_id',
            message: 'dailyLastUsedByBanner banner id must not be empty',
            path: 'gachaState.dailyLastUsedByBanner[]',
          ),
        );
      }
      if (catalogs.knownBannerIds.isNotEmpty &&
          entry.key.isNotEmpty &&
          !catalogs.knownBannerIds.contains(entry.key)) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'unknown_gacha_banner_id',
            message: 'Unknown gacha banner id: ${entry.key}',
            path: 'gachaState.dailyLastUsedByBanner.${entry.key}',
          ),
        );
      }
    }

    if (gacha.pityByBanner.isNotEmpty && catalogs.knownBannerIds.isEmpty) {
      warnings.add(
        const ClashSyncValidationIssue(
          code: 'catalog_missing_banner_ids',
          message: 'Banner catalog not provided; skipping banner ID validation',
          path: 'gachaState.pityByBanner',
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
    }
  }

  void _validateRewardHistorySummary(
    ClashSyncRewardHistorySummary summary,
    List<ClashSyncValidationIssue> errors,
  ) {
    if (summary.entryCount < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_reward_history_entry_count',
          message: 'entryCount must be >= 0',
          path: 'rewardHistorySummary.entryCount',
        ),
      );
    }
    if (summary.partialCount < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_reward_history_partial_count',
          message: 'partialCount must be >= 0',
          path: 'rewardHistorySummary.partialCount',
        ),
      );
    }
    if (summary.failureCount < 0) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'negative_reward_history_failure_count',
          message: 'failureCount must be >= 0',
          path: 'rewardHistorySummary.failureCount',
        ),
      );
    }
    if (summary.partialCount > summary.entryCount) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'reward_history_partial_exceeds_total',
          message: 'partialCount must be <= entryCount',
          path: 'rewardHistorySummary.partialCount',
        ),
      );
    }
    if (summary.failureCount > summary.entryCount) {
      errors.add(
        const ClashSyncValidationIssue(
          code: 'reward_history_failure_exceeds_total',
          message: 'failureCount must be <= entryCount',
          path: 'rewardHistorySummary.failureCount',
        ),
      );
    }
  }

  void _validateNonEmptyIds(
    List<String> ids,
    String path,
    String label,
    List<ClashSyncValidationIssue> errors,
  ) {
    for (final id in ids) {
      if (id.isEmpty) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'empty_${label.replaceAll(' ', '_')}_id',
            message: '$label id must not be empty',
            path: '$path[]',
          ),
        );
      }
    }
  }

  void _validateKnownInventoryIds(
    Iterable<String> ids,
    Set<String> knownIds,
    String path,
    String label,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    final itemIds = ids.where((id) => id.isNotEmpty).toList();
    if (itemIds.isEmpty) {
      return;
    }
    if (knownIds.isEmpty) {
      warnings.add(
        ClashSyncValidationIssue(
          code: 'catalog_missing_${label.replaceAll(' ', '_')}_ids',
          message: '$label catalog not provided; skipping ID validation',
          path: path,
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
      return;
    }
    for (final id in itemIds) {
      if (!knownIds.contains(id)) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'unknown_inventory_item_id',
            message: 'Unknown $label id: $id',
            path: '$path.$id',
          ),
        );
      }
    }
  }

  void _validateKnownMissionIds(
    List<String> missionIds,
    String path,
    List<ClashSyncValidationIssue> errors,
    List<ClashSyncValidationIssue> warnings,
  ) {
    _validateNonEmptyIds(missionIds, path, 'mission', errors);

    if (missionIds.isEmpty) {
      return;
    }
    if (catalogs.knownMissionIds.isEmpty) {
      warnings.add(
        ClashSyncValidationIssue(
          code: 'catalog_missing_mission_ids',
          message:
              'Mission catalog not provided; skipping mission ID validation',
          path: path,
          severity: ClashSyncValidationSeverity.warning,
        ),
      );
      return;
    }
    for (final id in missionIds) {
      if (id.isNotEmpty && !catalogs.knownMissionIds.contains(id)) {
        errors.add(
          ClashSyncValidationIssue(
            code: 'unknown_mission_id',
            message: 'Unknown mission id: $id',
            path: '$path.$id',
          ),
        );
      }
    }
  }
}

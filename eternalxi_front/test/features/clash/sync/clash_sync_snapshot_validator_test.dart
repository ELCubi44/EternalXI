import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storage/clash_local_storage_compatibility_fixtures.dart';
import 'sync_layer_http_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashSyncSnapshotValidator Fase 66', () {
    test('snapshot válido pasa', () {
      final result = _validator().validate(_validSnapshot());

      expect(result.isValid, isTrue);
      expect(result.hasErrors, isFalse);
    });

    test('contractVersion inválida falla', () {
      final snapshot = _validSnapshot().copyWith(contractVersion: 99);
      final result = _validator().validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('invalid_contract_version'),
      );
    });

    test('schemaVersion 0 falla', () {
      final snapshot = _validSnapshot().copyWith(schemaVersion: 0);
      final result = _validator().validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('invalid_schema_version'),
      );
    });

    test('wallet negativa falla', () {
      final snapshot = _validSnapshot().copyWith(
        wallet: const ClashSyncWallet(coins: -1, gems: 5),
      );
      final result = _validator().validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('negative_wallet_coins'),
      );
    });

    test('inventario negativo falla', () {
      final snapshot = _validSnapshot().copyWith(
        inventories: const ClashSyncInventories(
          expMaterials: {'basic-training-manual': -2},
        ),
      );
      final result = _validator().validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('negative_inventory_quantity'),
      );
    });

    test('itemId desconocido con catálogo falla', () {
      final snapshot = _validSnapshot().copyWith(
        inventories: const ClashSyncInventories(
          expMaterials: {'unknown-material': 1},
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_inventory_item_id'),
      );
    });

    test('cardId desconocido con catálogo falla', () {
      final snapshot = _validSnapshot().copyWith(
        collection: const ClashSyncCollection(
          ownedCardIds: ['phantom-card'],
          uniqueCount: 1,
          totalCopies: 1,
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_card_id'),
      );
    });

    test('lineup referencia carta inexistente falla', () {
      final snapshot = _validSnapshot();
      final result = _validator(
        catalogs: ClashSyncSnapshotValidatorCatalogs(
          knownCardIds: _fixtureCatalogs().knownCardIds,
          lineupSlotsByLineupId: {
            'lineup-1': {'striker': 'phantom-card'},
          },
        ),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_lineup_card_id'),
      );
    });

    test('event stageId desconocido falla', () {
      final snapshot = _validSnapshot().copyWith(
        characterEventsProgress: const ClashSyncCharacterEventsProgress(
          completedStageIds: ['unknown-stage'],
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_event_stage_id'),
      );
    });

    test('mission desconocida falla', () {
      final snapshot = _validSnapshot().copyWith(
        missionsProgress: const ClashSyncMissionsProgress(
          dailyClaimedMissionIds: ['unknown-mission'],
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_mission_id'),
      );
    });

    test('achievement desconocido falla', () {
      final snapshot = _validSnapshot().copyWith(
        achievementsProgress: const ClashSyncAchievementsProgress(
          claimedAchievementIds: ['unknown-achievement'],
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_achievement_id'),
      );
    });

    test('gift desconocido falla', () {
      final snapshot = _validSnapshot().copyWith(
        giftsProgress: const ClashSyncGiftsProgress(
          claimedGiftIds: ['unknown-gift'],
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_gift_id'),
      );
    });

    test('gacha pity negativo falla', () {
      final snapshot = _validSnapshot().copyWith(
        gachaState: const ClashSyncGachaState(
          pityByBanner: [
            ClashSyncGachaPityState(
              bannerId: 'starter-banner-001',
              pullsSinceLastPity: -1,
            ),
          ],
        ),
      );
      final result = _validator().validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('negative_gacha_pity_counter'),
      );
    });

    test('banner desconocido falla', () {
      final snapshot = _validSnapshot().copyWith(
        gachaState: const ClashSyncGachaState(
          pityByBanner: [ClashSyncGachaPityState(bannerId: 'unknown-banner')],
        ),
      );
      final result = _validator(
        catalogs: _fixtureCatalogs(),
      ).validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('unknown_gacha_banner_id'),
      );
    });

    test('rewardHistorySummary inválido falla', () {
      final snapshot = _validSnapshot().copyWith(
        rewardHistorySummary: const ClashSyncRewardHistorySummary(
          entryCount: 1,
          partialCount: 2,
        ),
      );
      final result = _validator().validate(snapshot);

      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('reward_history_partial_exceeds_total'),
      );
    });

    test('sin catálogos no falla por desconocidos pero advierte', () {
      final snapshot = _validSnapshot();
      final result = _validator().validate(snapshot);

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(
        result.warnings.map((issue) => issue.code),
        contains('catalog_missing_card_ids'),
      );
    });

    test('validator no depende de HTTP/API', () {
      expect(findForbiddenHttpImportsInSyncLayer(), isEmpty);
    });

    test(
      'builder + validator con catálogos mínimos produce snapshot válido',
      () async {
        final snapshot = await _buildFromLegacyFixtures();
        final result = _validator(
          catalogs: _fixtureCatalogs(),
        ).validate(snapshot);

        expect(result.isValid, isTrue);
      },
    );
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashSyncSnapshotValidator _validator({
  ClashSyncSnapshotValidatorCatalogs? catalogs,
}) {
  return ClashSyncSnapshotValidator(
    catalogs: catalogs ?? const ClashSyncSnapshotValidatorCatalogs(),
    checkedAt: () => _epoch,
  );
}

ClashSyncSnapshotValidatorCatalogs _fixtureCatalogs() {
  return const ClashSyncSnapshotValidatorCatalogs(
    knownCardIds: {'card-a', 'card-b', 'st-1', 'gk-1'},
    knownEventIds: {'event-mika-speed'},
    knownEventStageIdsByEvent: {
      'event-mika-speed': {'event-mika-stage-01'},
    },
    knownMissionIds: {'daily-play-match', 'weekly-win-matches'},
    knownAchievementIds: {'ach-first-match'},
    knownGiftIds: {'gift-welcome', 'gift-daily'},
    knownBannerIds: {'starter-banner-001'},
    knownExpMaterialIds: {'basic-training-manual'},
    knownTicketIds: {'starter-single-ticket', 'event-ticket'},
  );
}

ClashSyncSnapshot _validSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: ClashStorageSchema.currentVersion,
    wallet: const ClashSyncWallet(coins: 1500, gems: 12),
    collection: const ClashSyncCollection(
      ownedCardIds: ['card-a', 'card-b'],
      uniqueCount: 2,
      totalCopies: 3,
      duplicateCopies: 1,
    ),
    inventories: const ClashSyncInventories(
      expMaterials: {'basic-training-manual': 9},
      tickets: {'starter-single-ticket': 5},
    ),
    lineups: const ClashSyncLineups(lineupCount: 1, activeLineupId: 'lineup-1'),
    storyProgress: const ClashSyncStoryProgress(
      completedLevelIds: ['prologue-lvl-01'],
    ),
    characterEventsProgress: const ClashSyncCharacterEventsProgress(
      completedStageIds: ['event-mika-stage-01'],
      clearCounts: {'event-mika-stage-01': 2},
    ),
    missionsProgress: const ClashSyncMissionsProgress(
      dailyLocalDate: '2026-06-20',
      dailyClaimedMissionIds: ['daily-play-match'],
      weeklyWeekKey: '2026-W25',
      weeklyClaimedMissionIds: ['weekly-win-matches'],
    ),
    achievementsProgress: const ClashSyncAchievementsProgress(
      claimedAchievementIds: ['ach-first-match'],
    ),
    giftsProgress: const ClashSyncGiftsProgress(
      claimedGiftIds: ['gift-welcome'],
    ),
    gachaState: const ClashSyncGachaState(
      historyEntryCount: 1,
      pityByBanner: [
        ClashSyncGachaPityState(
          bannerId: 'starter-banner-001',
          pullsSinceLastPity: 12,
          totalPulls: 40,
        ),
      ],
      dailyLastUsedByBanner: {'starter-banner-001': '2026-06-20'},
    ),
    rewardHistorySummary: const ClashSyncRewardHistorySummary(
      entryCount: 1,
      partialCount: 1,
    ),
  );
}

Future<ClashSyncSnapshot> _buildFromLegacyFixtures() async {
  final legacy =
      ClashLocalStorageCompatibilityFixtures.legacyInstallWithoutSchemaVersion();
  final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
    ClashSharedPreferencesKeys.schemaVersion: ClashStorageSchema.currentVersion,
    ...legacy,
  });

  final builder = ClashSyncSnapshotBuilder(
    generatedAt: () => _epoch,
    dependencies: ClashSyncSnapshotBuilderDependencies(
      sharedPreferences: prefs,
      collectionStorage: SharedPreferencesClashPlayerCollectionBackend(prefs),
      storyProgressStorage: SharedPreferencesClashStoryProgressBackend(prefs),
      expMaterialStorage: SharedPreferencesClashExpMaterialInventoryBackend(
        prefs,
      ),
      techniqueBookStorage: SharedPreferencesClashTechniqueBookInventoryBackend(
        prefs,
      ),
      evolutionMaterialStorage:
          SharedPreferencesClashEvolutionMaterialInventoryBackend(prefs),
      ticketInventoryStorage: SharedPreferencesClashGachaTicketInventoryBackend(
        prefs,
      ),
      lineupsStorage: SharedPreferencesClashLineupsBackend(prefs),
      giftsStorage: SharedPreferencesClashGiftsBackend(prefs),
      dailyMissionsStorage: SharedPreferencesClashDailyMissionsBackend(prefs),
      weeklyMissionsStorage: SharedPreferencesClashWeeklyMissionsBackend(prefs),
      achievementsStorage: SharedPreferencesClashAchievementsBackend(prefs),
      characterEventsStorage: SharedPreferencesClashCharacterEventsBackend(
        prefs,
      ),
      gachaHistoryStorage: SharedPreferencesClashGachaHistoryBackend(prefs),
      gachaPityStorage: SharedPreferencesClashGachaPityBackend(prefs),
      gachaDailyStorage: SharedPreferencesClashGachaDailyBackend(prefs),
      rewardHistoryStorage: SharedPreferencesClashRewardHistoryBackend(prefs),
      knownGachaBannerIds: const ['starter-banner-001'],
    ),
  );

  return builder.build();
}

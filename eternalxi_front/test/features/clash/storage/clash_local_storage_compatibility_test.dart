import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
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
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_local_migration_runner.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clash_local_storage_compatibility_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clash local storage compatibility Fase 64', () {
    group('Keys', () {
      test('todas las data keys están centralizadas sin duplicados', () {
        expect(
          ClashSharedPreferencesKeys.dataKeys.length,
          ClashSharedPreferencesKeys.dataKeys.toSet().length,
        );
        expect(
          ClashSharedPreferencesKeys.dataKeys,
          containsAll(const [
            ClashSharedPreferencesKeys.lineups7v7,
            ClashSharedPreferencesKeys.playerCollectionV1,
            ClashSharedPreferencesKeys.playerCollectionV2,
            ClashSharedPreferencesKeys.expMaterialInventory,
            ClashSharedPreferencesKeys.techniqueBookInventory,
            ClashSharedPreferencesKeys.evolutionMaterialInventory,
            ClashSharedPreferencesKeys.gachaTicketInventory,
            ClashSharedPreferencesKeys.dailyMissions,
            ClashSharedPreferencesKeys.weeklyMissions,
            ClashSharedPreferencesKeys.achievements,
            ClashSharedPreferencesKeys.newsRead,
            ClashSharedPreferencesKeys.gifts,
            ClashSharedPreferencesKeys.characterEvents,
            ClashSharedPreferencesKeys.gachaHistory,
            ClashSharedPreferencesKeys.gachaPity,
            ClashSharedPreferencesKeys.gachaDaily,
            ClashSharedPreferencesKeys.storyProgress,
            ClashSharedPreferencesKeys.rewardHistory,
          ]),
        );
        expect(
          ClashSharedPreferencesKeys.dataKeys,
          isNot(contains(ClashSharedPreferencesKeys.schemaVersion)),
        );
        expect(
          ClashSharedPreferencesKeys.dataKeys,
          isNot(contains(ClashSharedPreferencesKeys.lastMigratedAt)),
        );
      });

      test('storageKey de backups no está en dataKeys', () {
        expect(
          ClashSharedPreferencesKeys.lastLocalBackup,
          'clash_last_local_backup_v1',
        );
        expect(
          ClashSharedPreferencesKeys.dataKeys,
          isNot(contains(ClashSharedPreferencesKeys.lastLocalBackup)),
        );
      });

      test('storageKey de sync metadata no está en dataKeys', () {
        expect(
          ClashSharedPreferencesKeys.syncMetadata,
          'clash_sync_metadata_v1',
        );
        expect(
          ClashSyncMetadataStorage.storageKey,
          ClashSharedPreferencesKeys.syncMetadata,
        );
        expect(
          ClashSharedPreferencesKeys.dataKeys,
          isNot(contains(ClashSharedPreferencesKeys.syncMetadata)),
        );
      });

      test(
        'storageKey de backends coincide con ClashSharedPreferencesKeys',
        () {
          expect(
            SharedPreferencesClashLineupsBackend.storageKey,
            ClashSharedPreferencesKeys.lineups7v7,
          );
          expect(
            SharedPreferencesClashPlayerCollectionBackend.storageKeyV2,
            ClashSharedPreferencesKeys.playerCollectionV2,
          );
          expect(
            SharedPreferencesClashExpMaterialInventoryBackend.storageKey,
            ClashSharedPreferencesKeys.expMaterialInventory,
          );
          expect(
            SharedPreferencesClashTechniqueBookInventoryBackend.storageKey,
            ClashSharedPreferencesKeys.techniqueBookInventory,
          );
          expect(
            SharedPreferencesClashEvolutionMaterialInventoryBackend.storageKey,
            ClashSharedPreferencesKeys.evolutionMaterialInventory,
          );
          expect(
            SharedPreferencesClashGachaTicketInventoryBackend.storageKey,
            ClashSharedPreferencesKeys.gachaTicketInventory,
          );
          expect(
            SharedPreferencesClashDailyMissionsBackend.storageKey,
            ClashSharedPreferencesKeys.dailyMissions,
          );
          expect(
            SharedPreferencesClashWeeklyMissionsBackend.storageKey,
            ClashSharedPreferencesKeys.weeklyMissions,
          );
          expect(
            SharedPreferencesClashAchievementsBackend.storageKey,
            ClashSharedPreferencesKeys.achievements,
          );
          expect(
            SharedPreferencesClashGiftsBackend.storageKey,
            ClashSharedPreferencesKeys.gifts,
          );
          expect(
            SharedPreferencesClashCharacterEventsBackend.storageKey,
            ClashSharedPreferencesKeys.characterEvents,
          );
          expect(
            SharedPreferencesClashGachaHistoryBackend.storageKey,
            ClashSharedPreferencesKeys.gachaHistory,
          );
          expect(
            SharedPreferencesClashGachaPityBackend.storageKey,
            ClashSharedPreferencesKeys.gachaPity,
          );
          expect(
            SharedPreferencesClashGachaDailyBackend.storageKey,
            ClashSharedPreferencesKeys.gachaDaily,
          );
          expect(
            SharedPreferencesClashStoryProgressBackend.storageKey,
            ClashSharedPreferencesKeys.storyProgress,
          );
          expect(
            SharedPreferencesClashRewardHistoryBackend.storageKey,
            ClashSharedPreferencesKeys.rewardHistory,
          );
        },
      );

      test('fixtures usan las mismas keys que ClashSharedPreferencesKeys', () {
        final fixtureKeys =
            ClashLocalStorageCompatibilityFixtures.legacyInstallWithoutSchemaVersion()
                .keys
                .toSet();
        for (final key in fixtureKeys) {
          expect(
            ClashSharedPreferencesKeys.dataKeys.contains(key) ||
                key == ClashSharedPreferencesKeys.schemaVersion ||
                key == ClashSharedPreferencesKeys.lastMigratedAt,
            isTrue,
            reason: 'Key de fixture no registrada: $key',
          );
        }
      });
    });

    group('A) schemaVersion ausente', () {
      test('migra 0→1 y conserva payloads antiguos', () async {
        final legacy =
            ClashLocalStorageCompatibilityFixtures.legacyInstallWithoutSchemaVersion();
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs(
          legacy,
        );

        final result = await ClashLocalMigrationRunner(prefs).run();

        expect(result.fromVersion, 0);
        expect(result.toVersion, 1);
        expect(result.ranMigrations, ['0_to_1']);
        expect(prefs.getInt(ClashSharedPreferencesKeys.schemaVersion), 1);
        expect(
          prefs.getString(ClashSharedPreferencesKeys.lastMigratedAt),
          isNotNull,
        );

        for (final entry in legacy.entries) {
          expect(prefs.getString(entry.key), entry.value);
        }
      });
    });

    group('B) collection v2', () {
      test('carga cartas poseídas y duplicados', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.playerCollectionV2:
              ClashLocalStorageCompatibilityFixtures.collectionV2Minimal,
        });
        final snapshot = SharedPreferencesClashPlayerCollectionBackend(
          prefs,
        ).readSnapshot();

        expect(snapshot.ownedCardIds, containsAll(['card-a', 'card-b']));
        final progress = snapshot.cardProgress['card-a'];
        expect(progress, isNotNull);
        expect(progress!.duplicateCopies, 2);
        expect(progress.unlockedDuplicateNodes, 1);
      });

      test('tolera cardProgress ausente', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.playerCollectionV2:
              ClashLocalStorageCompatibilityFixtures
                  .collectionV2SparseOwnedOnly,
        });
        final snapshot = SharedPreferencesClashPlayerCollectionBackend(
          prefs,
        ).readSnapshot();

        expect(snapshot.ownedCardIds, {'card-a'});
        expect(snapshot.cardProgress, isEmpty);
      });

      test('fallback collection v1 lista de ids', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.playerCollectionV1:
              ClashLocalStorageCompatibilityFixtures.collectionV1,
        });
        final snapshot = SharedPreferencesClashPlayerCollectionBackend(
          prefs,
        ).readSnapshot();

        expect(snapshot.ownedCardIds, containsAll(['card-a', 'card-b']));
        expect(snapshot.cardProgress, isEmpty);
      });
    });

    group('C) inventarios v1', () {
      test('exp materials', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.expMaterialInventory:
              ClashLocalStorageCompatibilityFixtures.expMaterialsV1,
        });
        final snapshot = SharedPreferencesClashExpMaterialInventoryBackend(
          prefs,
        ).readSnapshot();

        expect(snapshot.quantities['basic-training-manual'], 9);
      });

      test('technique books', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.techniqueBookInventory:
              ClashLocalStorageCompatibilityFixtures.techniqueBooksV1,
        });
        final snapshot = SharedPreferencesClashTechniqueBookInventoryBackend(
          prefs,
        ).readSnapshot();

        expect(snapshot.quantities['basic-technique-book'], 2);
      });

      test('evolution materials', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.evolutionMaterialInventory:
              ClashLocalStorageCompatibilityFixtures.evolutionMaterialsV1,
        });
        final snapshot =
            SharedPreferencesClashEvolutionMaterialInventoryBackend(
              prefs,
            ).readSnapshot();

        expect(snapshot.quantities['insignia-r'], 1);
      });

      test('tickets gacha', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.gachaTicketInventory:
              ClashLocalStorageCompatibilityFixtures.ticketsV1,
        });
        final quantities = SharedPreferencesClashGachaTicketInventoryBackend(
          prefs,
        ).readQuantities();

        expect(quantities['starter-single-ticket'], 5);
        expect(quantities['event-ticket'], 1);
      });
    });

    group('D) lineups v1', () {
      test('carga alineación 7v7 guardada', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.lineups7v7:
              ClashLocalStorageCompatibilityFixtures.lineupsV1,
        });
        final lineups = SharedPreferencesClashLineupsBackend(
          prefs,
        ).readLineups();

        expect(lineups, isNotNull);
        expect(lineups!, hasLength(1));
        expect(lineups.first.isActive, isTrue);
        expect(lineups.first.slots[ClashPosition.striker], 'st-1');
        expect(lineups.first.slots[ClashPosition.goalkeeper], 'gk-1');
      });
    });

    group('E) gifts v1', () {
      test('claimedGiftIds antiguos siguen cargando', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.gifts:
              ClashLocalStorageCompatibilityFixtures.giftsV1,
        });
        final state = SharedPreferencesClashGiftsBackend(prefs).readState();

        expect(state, isNotNull);
        expect(
          state!.claimedGiftIds,
          containsAll(['gift-welcome', 'gift-daily']),
        );
        expect(state.lastOpenedAt, '2026-06-11T10:00:00.000Z');
      });
    });

    group('F) missions v1', () {
      test('daily claimed/completed antiguos cargan', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.dailyMissions:
              ClashLocalStorageCompatibilityFixtures.dailyMissionsV1,
        });
        final state = SharedPreferencesClashDailyMissionsBackend(
          prefs,
        ).readState();

        expect(state, isNotNull);
        expect(state!.localDate, '2026-06-20');
        expect(state.progress['daily-play-match'], 2);
        expect(state.claimedMissionIds, contains('daily-play-match'));
      });

      test('weekly claimed/completed antiguos cargan', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.weeklyMissions:
              ClashLocalStorageCompatibilityFixtures.weeklyMissionsV1,
        });
        final state = SharedPreferencesClashWeeklyMissionsBackend(
          prefs,
        ).readState();

        expect(state, isNotNull);
        expect(state!.weekKey, '2026-W25');
        expect(state.progress['weekly-win-matches'], 3);
        expect(state.claimedMissionIds, contains('weekly-win-matches'));
      });
    });

    group('G) achievements v1', () {
      test('claimed/completed antiguos cargan', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.achievements:
              ClashLocalStorageCompatibilityFixtures.achievementsV1,
        });
        final state = SharedPreferencesClashAchievementsBackend(
          prefs,
        ).readState();

        expect(state, isNotNull);
        expect(state!.progress['ach-first-match'], 1);
        expect(state.claimedAchievementIds, contains('ach-first-match'));
      });
    });

    group('H) character events v1', () {
      test('firstClear y progreso por stage se conservan separados', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.characterEvents:
              ClashLocalStorageCompatibilityFixtures.characterEventsV1,
        });
        final state = SharedPreferencesClashCharacterEventsBackend(
          prefs,
        ).readState();

        expect(state, isNotNull);
        expect(state!.completedStageIds, contains('event-mika-stage-01'));
        expect(
          state.claimedFirstClearRewardKeys,
          contains('event-mika-speed:event-mika-stage-01'),
        );
        expect(state.clearCounts['event-mika-stage-01'], 2);
      });
    });

    group('I) gacha', () {
      test('history v1 carga pulls', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.gachaHistory:
              ClashLocalStorageCompatibilityFixtures.gachaHistoryV1,
        });
        final entries = SharedPreferencesClashGachaHistoryBackend(
          prefs,
        ).readEntries();

        expect(entries, hasLength(1));
        expect(entries.first.bannerId, 'starter-banner-001');
        expect(entries.first.results, hasLength(1));
        expect(entries.first.results.first.cardId, 'card-a');
      });

      test('pity v1 carga contador por banner', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.gachaPity:
              ClashLocalStorageCompatibilityFixtures.gachaPityV1,
        });
        final pity = SharedPreferencesClashGachaPityBackend(
          prefs,
        ).readState('starter-banner-001');

        expect(pity, isNotNull);
        expect(pity!.pullsSinceLastPity, 12);
        expect(pity.totalPulls, 40);
        expect(pity.pityHits, 1);
      });

      test('daily v1 carga estado diario', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.gachaDaily:
              ClashLocalStorageCompatibilityFixtures.gachaDailyV1,
        });
        final date = SharedPreferencesClashGachaDailyBackend(
          prefs,
        ).readLastUsedDate('starter-banner-001');

        expect(date, '2026-06-20');
      });
    });

    group('J) story progress/wallet', () {
      test('carga coins/gems/progreso y objectives antiguos', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.storyProgress:
              ClashLocalStorageCompatibilityFixtures.storyProgressV1,
        });
        final progress = SharedPreferencesClashStoryProgressBackend(
          prefs,
        ).readProgress();

        expect(progress.walletCoins, 1500);
        expect(progress.walletGems, 12);
        expect(progress.completedLevelIds, contains('prologue-lvl-01'));
        expect(progress.claimedRewardLevelIds, contains('prologue-lvl-01'));
        expect(
          progress.claimedObjectiveRewardKeys,
          contains('prologue-lvl-02:score-win'),
        );
        expect(progress.eternalXiCardsGranted, isTrue);
        expect(progress.clashTeamUnlocked, isTrue);
      });
    });

    group('K) reward history v1', () {
      test('carga entradas con failedRewards e isPartial', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.rewardHistory:
              ClashLocalStorageCompatibilityFixtures.rewardHistoryV1,
        });
        final entries = SharedPreferencesClashRewardHistoryBackend(
          prefs,
        ).readEntries();

        expect(entries, hasLength(1));
        final entry = entries.first;
        expect(entry.sourceType, ClashRewardHistorySourceType.gift);
        expect(entry.rewards, hasLength(1));
        expect(entry.failedRewards, hasLength(1));
        expect(entry.isPartial, isTrue);
        expect(entry.isFailure, isFalse);
        expect(entry.newlyGrantedCardIds, ['card-a']);
      });

      test('soporta isFailure sin rewards', () async {
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
          ClashSharedPreferencesKeys.rewardHistory:
              ClashLocalStorageCompatibilityFixtures.rewardHistoryFailureV1,
        });
        final entries = SharedPreferencesClashRewardHistoryBackend(
          prefs,
        ).readEntries();

        expect(entries, hasLength(1));
        expect(entries.first.isFailure, isTrue);
        expect(entries.first.isPartial, isFalse);
        expect(entries.first.rewards, isEmpty);
      });
    });

    group('Legacy install completa', () {
      test('todos los storages cargan tras migración 0→1', () async {
        final legacy =
            ClashLocalStorageCompatibilityFixtures.legacyInstallWithoutSchemaVersion();
        final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs(
          legacy,
        );
        await ClashLocalMigrationRunner(prefs).run();

        expect(
          SharedPreferencesClashPlayerCollectionBackend(
            prefs,
          ).readSnapshot().ownedCardIds,
          isNotEmpty,
        );
        expect(
          SharedPreferencesClashExpMaterialInventoryBackend(
            prefs,
          ).readSnapshot().quantities,
          isNotEmpty,
        );
        expect(
          SharedPreferencesClashGiftsBackend(prefs).readState(),
          isNotNull,
        );
        expect(
          SharedPreferencesClashDailyMissionsBackend(prefs).readState(),
          isNotNull,
        );
        expect(
          SharedPreferencesClashCharacterEventsBackend(prefs).readState(),
          isNotNull,
        );
        expect(
          SharedPreferencesClashGachaHistoryBackend(prefs).readEntries(),
          isNotEmpty,
        );
        expect(
          SharedPreferencesClashStoryProgressBackend(
            prefs,
          ).readProgress().walletCoins,
          1500,
        );
        expect(
          SharedPreferencesClashRewardHistoryBackend(prefs).readEntries(),
          isNotEmpty,
        );
      });
    });
  });
}

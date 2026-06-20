import 'dart:io';

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
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_contract_version.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_device_info.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storage/clash_local_storage_compatibility_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashSyncSnapshot Fase 65', () {
    test('contractVersion current es 1', () {
      expect(ClashSyncContractVersion.current, 1);
      expect(
        ClashSyncSnapshot(generatedAt: _epoch).contractVersion,
        ClashSyncContractVersion.current,
      );
    });

    test('serializa y deserializa sin perder campos', () {
      final original = _sampleSnapshot();
      final decoded = ClashSyncSnapshot.fromJson(original.toJson());

      expect(decoded, original);
      expect(decoded.wallet.coins, 1500);
      expect(decoded.collection.ownedCardIds, contains('card-a'));
      expect(decoded.gachaState.pityByBanner, hasLength(1));
      expect(decoded.rewardHistorySummary.entryCount, 1);
    });

    test('fromJson tolera campos opcionales ausentes', () {
      final decoded = ClashSyncSnapshot.fromJson({
        'generatedAt': '2026-06-20T12:00:00.000Z',
      });

      expect(decoded.contractVersion, ClashSyncContractVersion.current);
      expect(decoded.schemaVersion, 0);
      expect(decoded.wallet, const ClashSyncWallet());
      expect(decoded.collection.ownedCardIds, isEmpty);
      expect(decoded.deviceInfo, isNull);
      expect(decoded.rewardHistorySummary.entryCount, 0);
    });

    test('generatedAt es estable cuando se inyecta', () async {
      final fixed = _epoch;
      final snapshot = await _buildFromLegacyFixtures(generatedAt: () => fixed);

      expect(snapshot.generatedAt, fixed);
    });

    test('schemaVersion local aparece en snapshot', () async {
      final snapshot = await _buildFromLegacyFixtures(
        schemaVersion: ClashStorageSchema.currentVersion,
        lastMigratedAt: '2026-06-11T10:00:00.000Z',
      );

      expect(snapshot.schemaVersion, ClashStorageSchema.currentVersion);
      expect(snapshot.lastMigratedAt, '2026-06-11T10:00:00.000Z');
    });

    test('builder genera snapshot desde datos locales mock', () async {
      final snapshot = await _buildFromLegacyFixtures();

      expect(snapshot.wallet.coins, 1500);
      expect(snapshot.wallet.gems, 12);
      expect(snapshot.collection.uniqueCount, 2);
      expect(snapshot.inventories.expMaterials['basic-training-manual'], 9);
      expect(snapshot.lineups.lineupCount, 1);
      expect(snapshot.lineups.activeLineupId, 'lineup-1');
      expect(
        snapshot.storyProgress.completedLevelIds,
        contains('prologue-lvl-01'),
      );
      expect(
        snapshot.characterEventsProgress.completedStageIds,
        contains('event-mika-stage-01'),
      );
      expect(snapshot.missionsProgress.dailyLocalDate, '2026-06-20');
      expect(snapshot.achievementsProgress.claimedAchievementIds, isNotEmpty);
      expect(snapshot.giftsProgress.claimedGiftIds, contains('gift-welcome'));
      expect(snapshot.gachaState.historyEntryCount, 1);
      expect(snapshot.gachaState.pityByBanner.first.pullsSinceLastPity, 12);
      expect(
        snapshot.gachaState.dailyLastUsedByBanner['starter-banner-001'],
        '2026-06-20',
      );
      expect(snapshot.rewardHistorySummary.entryCount, 1);
      expect(snapshot.rewardHistorySummary.partialCount, 1);
    });

    test('rewardHistorySummary no incluye entradas completas', () async {
      final snapshot = await _buildFromLegacyFixtures();
      final json = snapshot.toJson();

      expect(json['rewardHistorySummary'], isA<Map>());
      expect(json.containsKey('rewardHistoryEntries'), isFalse);
      final summary = json['rewardHistorySummary'] as Map;
      expect(summary.keys, containsAll(['entryCount', 'partialCount']));
      expect(summary.containsKey('entries'), isFalse);
    });

    test('módulo sync no importa HTTP ni cliente API', () {
      final syncDir = Directory('lib/features/clash/sync');
      expect(syncDir.existsSync(), isTrue);

      final forbidden = <String>[];
      for (final entity in syncDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        if (content.contains("import 'package:http/") ||
            content.contains('import "package:http/') ||
            content.contains('package:dio/') ||
            content.contains('ClashApiClient') ||
            content.contains('http.get(') ||
            content.contains('http.post(')) {
          forbidden.add(entity.path);
        }
      }

      expect(forbidden, isEmpty);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashSyncSnapshot _sampleSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: 1,
    lastMigratedAt: '2026-06-11T10:00:00.000Z',
    deviceInfo: const ClashSyncDeviceInfo(
      deviceId: 'device-test',
      platform: 'flutter_test',
    ),
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
    lineups: const ClashSyncLineups(
      lineupCount: 1,
      activeLineupId: 'lineup-1',
      completeLineupCount: 0,
    ),
    storyProgress: const ClashSyncStoryProgress(
      completedLevelIds: ['prologue-lvl-01'],
      clashTeamUnlocked: true,
    ),
    characterEventsProgress: const ClashSyncCharacterEventsProgress(
      completedStageIds: ['event-mika-stage-01'],
      clearCounts: {'event-mika-stage-01': 2},
    ),
    missionsProgress: const ClashSyncMissionsProgress(
      dailyLocalDate: '2026-06-20',
      weeklyWeekKey: '2026-W25',
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
      latestEntryAt: '2026-06-11T10:00:00.000Z',
      partialCount: 1,
    ),
  );
}

Future<ClashSyncSnapshot> _buildFromLegacyFixtures({
  DateTime Function()? generatedAt,
  int? schemaVersion,
  String? lastMigratedAt,
}) async {
  final legacy =
      ClashLocalStorageCompatibilityFixtures.legacyInstallWithoutSchemaVersion();
  final prefs = await ClashLocalStorageCompatibilityFixtures.mountPrefs({
    if (schemaVersion != null)
      ClashSharedPreferencesKeys.schemaVersion: schemaVersion,
    if (lastMigratedAt != null)
      ClashSharedPreferencesKeys.lastMigratedAt: lastMigratedAt,
    ...legacy,
  });

  final builder = ClashSyncSnapshotBuilder(
    generatedAt: generatedAt ?? () => _epoch,
    deviceInfo: const ClashSyncDeviceInfo(
      deviceId: 'test-device',
      platform: 'flutter_test',
    ),
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

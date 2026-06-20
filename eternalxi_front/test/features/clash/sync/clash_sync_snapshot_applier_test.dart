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
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_section.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashSyncSnapshotApplier Fase 73', () {
    test('snapshot válido aplica wallet e inventarios mínimos', () async {
      final harness = await _ApplierHarness.create();
      addTearDown(harness.dispose);

      await harness.storyBackend.writeProgress(
        const ClashStoryProgress(walletCoins: 10, walletGems: 1),
      );

      final remote = _validRemote().copyWith(
        wallet: const ClashSyncWallet(coins: 500, gems: 7),
        inventories: const ClashSyncInventories(
          expMaterials: {'basic-training-manual': 3},
        ),
      );

      final result = await harness.applier.applyRemoteSnapshot(
        remote,
        serverRevision: 2,
      );

      expect(result.isSuccess, isTrue);
      expect(result.backupCreated, isTrue);
      expect(result.appliedSections, contains(ClashSyncApplySection.wallet));
      expect(
        result.appliedSections,
        contains(ClashSyncApplySection.inventories),
      );

      final progress = harness.storyBackend.readProgress();
      expect(progress.walletCoins, 500);
      expect(progress.walletGems, 7);
      expect(
        harness.expBackend.readSnapshot().quantities['basic-training-manual'],
        3,
      );
    });

    test('crea backup antes de escribir con snapshot local previo', () async {
      final harness = await _ApplierHarness.create();
      addTearDown(harness.dispose);

      await harness.storyBackend.writeProgress(
        const ClashStoryProgress(walletCoins: 42, walletGems: 2),
      );

      final remote = _validRemote().copyWith(
        wallet: const ClashSyncWallet(coins: 100, gems: 0),
      );

      await harness.applier.applyRemoteSnapshot(remote, serverRevision: 5);

      final backup = ClashSyncLocalBackupStore(
        sharedPreferences: harness.prefs,
      ).read();
      expect(backup, isNotNull);
      expect(backup!.source, ClashSyncLocalBackup.sourceBeforeRemoteApply);
      expect(backup.serverRevision, 5);
      expect(backup.snapshot.wallet.coins, 42);
      expect(backup.snapshot.wallet.gems, 2);
    });

    test('snapshot inválido no aplica y no pisa local', () async {
      final harness = await _ApplierHarness.create();
      addTearDown(harness.dispose);

      await harness.storyBackend.writeProgress(
        const ClashStoryProgress(walletCoins: 77, walletGems: 3),
      );

      final remote = _validRemote().copyWith(
        wallet: const ClashSyncWallet(coins: -1, gems: 0),
      );

      final result = await harness.applier.applyRemoteSnapshot(remote);

      expect(result.isValidationFailed, isTrue);
      expect(result.backupCreated, isFalse);
      expect(harness.storyBackend.readProgress().walletCoins, 77);
      expect(
        harness.prefs.getString(ClashSharedPreferencesKeys.lastLocalBackup),
        isNull,
      );
    });

    test('key backup no duplica otras data keys', () {
      expect(
        ClashSharedPreferencesKeys.dataKeys,
        isNot(contains(ClashSharedPreferencesKeys.lastLocalBackup)),
      );
      expect(
        ClashSharedPreferencesKeys.lastLocalBackup,
        'clash_last_local_backup_v1',
      );
    });

    test('reward history vacío remoto limpia historial local', () async {
      final harness = await _ApplierHarness.create();
      addTearDown(harness.dispose);

      final remote = _validRemote().copyWith(
        rewardHistorySummary: const ClashSyncRewardHistorySummary(
          entryCount: 0,
        ),
      );

      final result = await harness.applier.applyRemoteSnapshot(remote);

      expect(result.isSuccess, isTrue);
      expect(
        result.appliedSections,
        contains(ClashSyncApplySection.rewardHistory),
      );
      expect(harness.rewardHistoryBackend.readEntries(), isEmpty);
    });

    test(
      'reward history remoto con entradas se omite sin borrar local',
      () async {
        final harness = await _ApplierHarness.create();
        addTearDown(harness.dispose);

        final remote = _validRemote().copyWith(
          rewardHistorySummary: const ClashSyncRewardHistorySummary(
            entryCount: 2,
            partialCount: 1,
          ),
        );

        final result = await harness.applier.applyRemoteSnapshot(remote);

        expect(result.isSuccess, isTrue);
        expect(
          result.skippedSections,
          contains(ClashSyncApplySection.rewardHistory),
        );
        expect(
          result.appliedSections,
          isNot(contains(ClashSyncApplySection.rewardHistory)),
        );
      },
    );

    test(
      'backend crítico ausente devuelve unsupported sin escritura',
      () async {
        final harness = await _ApplierHarness.create(
          includeStoryBackend: false,
        );
        addTearDown(harness.dispose);

        await harness.storyBackend.writeProgress(
          const ClashStoryProgress(walletCoins: 11),
        );

        final result = await harness.applier.applyRemoteSnapshot(
          _validRemote(),
        );

        expect(result.isUnsupported, isTrue);
        expect(harness.storyBackend.readProgress().walletCoins, 11);
      },
    );
  });
}

ClashSyncSnapshot _validRemote() {
  return ClashSyncSnapshot(
    generatedAt: DateTime.utc(2026, 6, 20, 15),
    schemaVersion: ClashStorageSchema.currentVersion,
    wallet: const ClashSyncWallet(coins: 200, gems: 4),
    inventories: const ClashSyncInventories(
      tickets: {'starter-single-ticket': 1},
    ),
  );
}

class _ApplierHarness {
  _ApplierHarness({
    required this.prefs,
    required this.applier,
    required this.storyBackend,
    required this.expBackend,
    required this.rewardHistoryBackend,
  });

  final SharedPreferences prefs;
  final ClashSyncSnapshotApplier applier;
  final InMemoryClashStoryProgressBackend storyBackend;
  final InMemoryClashExpMaterialInventoryBackend expBackend;
  final InMemoryClashRewardHistoryBackend rewardHistoryBackend;

  static Future<_ApplierHarness> create({
    bool includeStoryBackend = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storyBackend = InMemoryClashStoryProgressBackend();
    final collectionBackend = InMemoryClashPlayerCollectionBackend();
    final expBackend = InMemoryClashExpMaterialInventoryBackend();
    final techniqueBackend = InMemoryClashTechniqueBookInventoryBackend();
    final evolutionBackend = InMemoryClashEvolutionMaterialInventoryBackend();
    final ticketBackend = InMemoryClashGachaTicketInventoryBackend();
    final dailyBackend = InMemoryClashDailyMissionsBackend();
    final weeklyBackend = InMemoryClashWeeklyMissionsBackend();
    final achievementsBackend = InMemoryClashAchievementsBackend();
    final giftsBackend = InMemoryClashGiftsBackend();
    final eventsBackend = InMemoryClashCharacterEventsBackend();
    final gachaHistoryBackend = InMemoryClashGachaHistoryBackend();
    final gachaPityBackend = InMemoryClashGachaPityBackend();
    final gachaDailyBackend = InMemoryClashGachaDailyBackend();
    final rewardHistoryBackend = InMemoryClashRewardHistoryBackend();

    final builder = ClashSyncSnapshotBuilder(
      dependencies: ClashSyncSnapshotBuilderDependencies(
        sharedPreferences: prefs,
        schemaVersion: ClashStorageSchema.currentVersion,
        storyProgressStorage: storyBackend,
        collectionStorage: collectionBackend,
        expMaterialStorage: expBackend,
        techniqueBookStorage: techniqueBackend,
        evolutionMaterialStorage: evolutionBackend,
        ticketInventoryStorage: ticketBackend,
        dailyMissionsStorage: dailyBackend,
        weeklyMissionsStorage: weeklyBackend,
        achievementsStorage: achievementsBackend,
        giftsStorage: giftsBackend,
        characterEventsStorage: eventsBackend,
        gachaHistoryStorage: gachaHistoryBackend,
        gachaPityStorage: gachaPityBackend,
        gachaDailyStorage: gachaDailyBackend,
        rewardHistoryStorage: rewardHistoryBackend,
      ),
    );

    final applier = ClashSyncSnapshotApplier(
      builder: builder,
      validator: const ClashSyncSnapshotValidator(),
      dependencies: ClashSyncSnapshotApplierDependencies(
        sharedPreferences: prefs,
        storyProgressStorage: includeStoryBackend ? storyBackend : null,
        collectionStorage: collectionBackend,
        expMaterialStorage: expBackend,
        techniqueBookStorage: techniqueBackend,
        evolutionMaterialStorage: evolutionBackend,
        ticketInventoryStorage: ticketBackend,
        dailyMissionsStorage: dailyBackend,
        weeklyMissionsStorage: weeklyBackend,
        achievementsStorage: achievementsBackend,
        giftsStorage: giftsBackend,
        characterEventsStorage: eventsBackend,
        gachaHistoryStorage: gachaHistoryBackend,
        gachaPityStorage: gachaPityBackend,
        gachaDailyStorage: gachaDailyBackend,
        rewardHistoryStorage: rewardHistoryBackend,
      ),
    );

    return _ApplierHarness(
      prefs: prefs,
      applier: applier,
      storyBackend: storyBackend,
      expBackend: expBackend,
      rewardHistoryBackend: rewardHistoryBackend,
    );
  }

  Future<void> dispose() async {
    SharedPreferences.setMockInitialValues({});
  }
}

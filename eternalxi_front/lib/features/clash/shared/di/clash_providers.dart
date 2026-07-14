import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_claim_api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_online_claim_registrar.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_save_api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/http_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievement_event_sink.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_local_datasource.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_books_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_local_datasource.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_storage.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/controllers/clash_chain_trial_controller.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_local_datasource.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_tickets_local_datasource.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_local_datasource.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/decisive_moments/presentation/controllers/clash_decisive_moments_controller.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_mission_progress_event_hub.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_local_datasource.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_read_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_local_migration_runner.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_migration_result.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_local_datasource.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/single_child_widget.dart';

/// Backends y repositorios pre-inicializados para el árbol de providers Clash.
class ClashProviderDependencies {
  const ClashProviderDependencies({
    required this.lineupsBackend,
    required this.collectionBackend,
    required this.expMaterialInventoryBackend,
    required this.expMaterialsRepository,
    required this.techniqueBookInventoryBackend,
    required this.techniqueBooksRepository,
    required this.evolutionMaterialInventoryBackend,
    required this.evolutionMaterialsRepository,
    required this.storyProgressBackend,
    required this.gachaDailyBackend,
    required this.gachaHistoryBackend,
    required this.gachaPityBackend,
    required this.dailyMissionsBackend,
    required this.achievementsBackend,
    required this.weeklyMissionsBackend,
    required this.newsReadBackend,
    required this.giftsBackend,
    required this.characterEventsBackend,
    required this.trialsBackend,
    required this.gachaTicketInventoryBackend,
    required this.gachaTicketRepository,
    required this.rewardHistoryBackend,
    this.sharedPreferences,
    this.migrationResult,
    this.syncClientOverride,
  });

  final ClashLineupsStorageBackend lineupsBackend;
  final ClashPlayerCollectionStorageBackend collectionBackend;
  final ClashExpMaterialInventoryStorageBackend expMaterialInventoryBackend;
  final ClashExpMaterialsRepository expMaterialsRepository;
  final ClashTechniqueBookInventoryStorageBackend techniqueBookInventoryBackend;
  final ClashTechniqueBooksRepository techniqueBooksRepository;
  final ClashEvolutionMaterialInventoryStorageBackend
  evolutionMaterialInventoryBackend;
  final ClashEvolutionMaterialsRepository evolutionMaterialsRepository;
  final ClashStoryProgressStorageBackend storyProgressBackend;
  final ClashGachaDailyStorageBackend gachaDailyBackend;
  final ClashGachaHistoryStorageBackend gachaHistoryBackend;
  final ClashGachaPityStorageBackend gachaPityBackend;
  final ClashDailyMissionsStorageBackend dailyMissionsBackend;
  final ClashAchievementsStorageBackend achievementsBackend;
  final ClashWeeklyMissionsStorageBackend weeklyMissionsBackend;
  final ClashNewsReadStorageBackend newsReadBackend;
  final ClashGiftsStorageBackend giftsBackend;
  final ClashCharacterEventsStorageBackend characterEventsBackend;
  final ClashTrialsStorageBackend trialsBackend;
  final ClashGachaTicketInventoryStorageBackend gachaTicketInventoryBackend;
  final ClashGachaTicketRepository gachaTicketRepository;
  final ClashRewardHistoryStorageBackend rewardHistoryBackend;
  final SharedPreferences? sharedPreferences;
  final ClashMigrationResult? migrationResult;

  /// Cliente sync inyectado (p. ej. [FakeClashSyncClient] en tests). Si es null, usa HTTP.
  final ClashSyncClient? syncClientOverride;
}

/// Inicializa backends SharedPreferences y repositorios con seed por defecto.
Future<ClashProviderDependencies> prepareClashProviders() async {
  final prefs = await SharedPreferences.getInstance();
  ClashMigrationResult migrationResult;
  try {
    migrationResult = await ClashLocalMigrationRunner(prefs).run();
    if (!migrationResult.isSuccess && kDebugMode) {
      debugPrint(
        'ClashLocalMigrationRunner completed with errors: '
        '${migrationResult.errors.join('; ')}',
      );
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('ClashLocalMigrationRunner error: $error\n$stackTrace');
    }
    migrationResult = ClashMigrationResult(
      fromVersion: ClashStorageSchema.legacyUntrackedVersion,
      toVersion: ClashStorageSchema.legacyUntrackedVersion,
      errors: [error.toString()],
    );
  }

  final lineupsBackend = await SharedPreferencesClashLineupsBackend.create();
  final collectionBackend =
      await SharedPreferencesClashPlayerCollectionBackend.create();
  final expMaterialInventoryBackend =
      await SharedPreferencesClashExpMaterialInventoryBackend.create();
  final expMaterialsRepository = ClashExpMaterialsRepository(
    dataSource: ClashExpMaterialsLocalDataSource(),
    inventoryStorage: expMaterialInventoryBackend,
  );
  await expMaterialsRepository.seedDefaultInventoryIfEmpty();
  final techniqueBookInventoryBackend =
      await SharedPreferencesClashTechniqueBookInventoryBackend.create();
  final techniqueBooksRepository = ClashTechniqueBooksRepository(
    dataSource: ClashTechniqueBooksLocalDataSource(),
    inventoryStorage: techniqueBookInventoryBackend,
  );
  await techniqueBooksRepository.seedDefaultInventoryIfEmpty();
  final evolutionMaterialInventoryBackend =
      await SharedPreferencesClashEvolutionMaterialInventoryBackend.create();
  final evolutionMaterialsRepository = ClashEvolutionMaterialsRepository(
    dataSource: ClashEvolutionMaterialsLocalDataSource(),
    inventoryStorage: evolutionMaterialInventoryBackend,
  );
  await evolutionMaterialsRepository.seedDefaultInventoryIfEmpty();
  final storyProgressBackend =
      await SharedPreferencesClashStoryProgressBackend.create();
  final gachaDailyBackend =
      await SharedPreferencesClashGachaDailyBackend.create();
  final gachaHistoryBackend =
      await SharedPreferencesClashGachaHistoryBackend.create();
  final gachaPityBackend =
      await SharedPreferencesClashGachaPityBackend.create();
  final dailyMissionsBackend =
      await SharedPreferencesClashDailyMissionsBackend.create();
  final achievementsBackend =
      await SharedPreferencesClashAchievementsBackend.create();
  final weeklyMissionsBackend =
      await SharedPreferencesClashWeeklyMissionsBackend.create();
  final newsReadBackend = await SharedPreferencesClashNewsReadBackend.create();
  final giftsBackend = await SharedPreferencesClashGiftsBackend.create();
  final characterEventsBackend =
      await SharedPreferencesClashCharacterEventsBackend.create();
  final trialsBackend = await SharedPreferencesClashTrialsBackend.create();
  final gachaTicketInventoryBackend =
      await SharedPreferencesClashGachaTicketInventoryBackend.create();
  final gachaTicketRepository = ClashGachaTicketRepository(
    dataSource: ClashGachaTicketsLocalDataSource(),
    inventoryStorage: gachaTicketInventoryBackend,
  );
  final rewardHistoryBackend =
      await SharedPreferencesClashRewardHistoryBackend.create();

  return ClashProviderDependencies(
    lineupsBackend: lineupsBackend,
    collectionBackend: collectionBackend,
    expMaterialInventoryBackend: expMaterialInventoryBackend,
    expMaterialsRepository: expMaterialsRepository,
    techniqueBookInventoryBackend: techniqueBookInventoryBackend,
    techniqueBooksRepository: techniqueBooksRepository,
    evolutionMaterialInventoryBackend: evolutionMaterialInventoryBackend,
    evolutionMaterialsRepository: evolutionMaterialsRepository,
    storyProgressBackend: storyProgressBackend,
    gachaDailyBackend: gachaDailyBackend,
    gachaHistoryBackend: gachaHistoryBackend,
    gachaPityBackend: gachaPityBackend,
    dailyMissionsBackend: dailyMissionsBackend,
    achievementsBackend: achievementsBackend,
    weeklyMissionsBackend: weeklyMissionsBackend,
    newsReadBackend: newsReadBackend,
    giftsBackend: giftsBackend,
    characterEventsBackend: characterEventsBackend,
    trialsBackend: trialsBackend,
    gachaTicketInventoryBackend: gachaTicketInventoryBackend,
    gachaTicketRepository: gachaTicketRepository,
    rewardHistoryBackend: rewardHistoryBackend,
    sharedPreferences: prefs,
    migrationResult: migrationResult,
  );
}

/// Registra el árbol de providers/repositorios/controladores Clash (Fase 54).
List<SingleChildWidget> buildClashProviders(ClashProviderDependencies deps) {
  return [
    Provider<ClashCardsLocalDataSource>(
      create: (_) => ClashCardsLocalDataSource(),
    ),
    Provider<ClashCardsRepository>(
      create: (context) =>
          ClashCardsRepository(context.read<ClashCardsLocalDataSource>()),
    ),
    Provider<ClashPlayerCollectionStorageBackend>.value(
      value: deps.collectionBackend,
    ),
    Provider<ClashExpMaterialInventoryStorageBackend>.value(
      value: deps.expMaterialInventoryBackend,
    ),
    Provider<ClashExpMaterialsLocalDataSource>(
      create: (_) => ClashExpMaterialsLocalDataSource(),
    ),
    Provider<ClashExpMaterialsRepository>.value(
      value: deps.expMaterialsRepository,
    ),
    Provider<ClashTechniqueBookInventoryStorageBackend>.value(
      value: deps.techniqueBookInventoryBackend,
    ),
    Provider<ClashTechniqueBooksLocalDataSource>(
      create: (_) => ClashTechniqueBooksLocalDataSource(),
    ),
    Provider<ClashTechniqueBooksRepository>.value(
      value: deps.techniqueBooksRepository,
    ),
    Provider<ClashEvolutionMaterialInventoryStorageBackend>.value(
      value: deps.evolutionMaterialInventoryBackend,
    ),
    Provider<ClashEvolutionMaterialsLocalDataSource>(
      create: (_) => ClashEvolutionMaterialsLocalDataSource(),
    ),
    Provider<ClashEvolutionMaterialsRepository>.value(
      value: deps.evolutionMaterialsRepository,
    ),
    Provider<ClashGachaTicketInventoryStorageBackend>.value(
      value: deps.gachaTicketInventoryBackend,
    ),
    Provider<ClashGachaTicketRepository>.value(
      value: deps.gachaTicketRepository,
    ),
    Provider<ClashRewardHistoryStorageBackend>.value(
      value: deps.rewardHistoryBackend,
    ),
    Provider<ClashRewardHistoryRepository>(
      create: (context) => ClashRewardHistoryRepository(
        storage: context.read<ClashRewardHistoryStorageBackend>(),
      ),
    ),
    Provider<ClashDailyMissionsStorageBackend>.value(
      value: deps.dailyMissionsBackend,
    ),
    Provider<ClashAchievementsStorageBackend>.value(
      value: deps.achievementsBackend,
    ),
    Provider<ClashWeeklyMissionsStorageBackend>.value(
      value: deps.weeklyMissionsBackend,
    ),
    Provider<ClashNewsReadStorageBackend>.value(value: deps.newsReadBackend),
    Provider<ClashGiftsStorageBackend>.value(value: deps.giftsBackend),
    Provider<ClashCharacterEventsStorageBackend>.value(
      value: deps.characterEventsBackend,
    ),
    Provider<ClashTrialsStorageBackend>.value(value: deps.trialsBackend),
    Provider<ClashDailyMissionEventSink>(
      create: (_) => ClashDailyMissionEventSink(),
    ),
    Provider<ClashWeeklyMissionEventSink>(
      create: (_) => ClashWeeklyMissionEventSink(),
    ),
    Provider<ClashAchievementEventSink>(
      create: (_) => ClashAchievementEventSink(),
    ),
    Provider<ClashMissionProgressEventHub>(
      create: (context) => ClashMissionProgressEventHub(
        daily: context.read<ClashDailyMissionEventSink>(),
        weekly: context.read<ClashWeeklyMissionEventSink>(),
        achievements: context.read<ClashAchievementEventSink>(),
      ),
    ),
    Provider<ClashInventoryRepository>(
      create: (context) => ClashInventoryRepository(
        expMaterialsRepository: context.read<ClashExpMaterialsRepository>(),
        techniqueBooksRepository: context.read<ClashTechniqueBooksRepository>(),
        evolutionMaterialsRepository: context
            .read<ClashEvolutionMaterialsRepository>(),
        ticketRepository: context.read<ClashGachaTicketRepository>(),
      ),
    ),
    Provider<ClashPlayerCollectionRepository>(
      create: (context) => ClashPlayerCollectionRepository(
        storage: context.read<ClashPlayerCollectionStorageBackend>(),
        cardsRepository: context.read<ClashCardsRepository>(),
        expMaterialsRepository: context.read<ClashExpMaterialsRepository>(),
        techniqueBooksRepository: context.read<ClashTechniqueBooksRepository>(),
        evolutionMaterialsRepository: context
            .read<ClashEvolutionMaterialsRepository>(),
        progressEventHub: context.read<ClashMissionProgressEventHub>(),
      ),
    ),
    ChangeNotifierProvider<ClashCardsController>(
      create: (context) => ClashCardsController(
        context.read<ClashCardsRepository>(),
        context.read<ClashPlayerCollectionRepository>(),
      ),
    ),
    Provider<ClashStoryLocalDataSource>(
      create: (_) => ClashStoryLocalDataSource(),
    ),
    Provider<ClashStoryProgressStorageBackend>.value(
      value: deps.storyProgressBackend,
    ),
    Provider<ClashGachaPityStorageBackend>.value(value: deps.gachaPityBackend),
    Provider<ClashStoryRepository>(
      create: (context) => ClashStoryRepository(
        dataSource: context.read<ClashStoryLocalDataSource>(),
        progressStorage: context.read<ClashStoryProgressStorageBackend>(),
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
        ticketRepository: context.read<ClashGachaTicketRepository>(),
      ),
    ),
    ChangeNotifierProvider<ClashStoryController>(
      create: (context) => ClashStoryController(
        storyRepository: context.read<ClashStoryRepository>(),
      ),
    ),
    Provider<ClashLocalRewardGranter>(
      create: (context) => ClashLocalRewardGranter(
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
        ticketRepository: context.read<ClashGachaTicketRepository>(),
        storyRepository: context.read<ClashStoryRepository>(),
      ),
    ),
    Provider<ClashShopGrantService>(
      create: (context) => ClashShopGrantService(
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
        ticketRepository: context.read<ClashGachaTicketRepository>(),
        rewardGranter: context.read<ClashLocalRewardGranter>(),
      ),
    ),
    Provider<ClashDailyMissionsRepository>(
      create: (context) {
        final repository = ClashDailyMissionsRepository(
          dataSource: ClashDailyMissionsLocalDataSource(),
          storage: context.read<ClashDailyMissionsStorageBackend>(),
          storyRepository: context.read<ClashStoryRepository>(),
          rewardGranter: context.read<ClashLocalRewardGranter>(),
        );
        context.read<ClashDailyMissionEventSink>().bind(repository);
        return repository;
      },
    ),
    Provider<ClashAchievementsRepository>(
      create: (context) {
        final repository = ClashAchievementsRepository(
          dataSource: ClashAchievementsLocalDataSource(),
          storage: context.read<ClashAchievementsStorageBackend>(),
          storyRepository: context.read<ClashStoryRepository>(),
          rewardGranter: context.read<ClashLocalRewardGranter>(),
        );
        context.read<ClashAchievementEventSink>().bind(repository);
        return repository;
      },
    ),
    Provider<ClashWeeklyMissionsRepository>(
      create: (context) {
        final repository = ClashWeeklyMissionsRepository(
          dataSource: ClashWeeklyMissionsLocalDataSource(),
          storage: context.read<ClashWeeklyMissionsStorageBackend>(),
          storyRepository: context.read<ClashStoryRepository>(),
          rewardGranter: context.read<ClashLocalRewardGranter>(),
        );
        context.read<ClashWeeklyMissionEventSink>().bind(repository);
        return repository;
      },
    ),
    Provider<ClashNewsRepository>(
      create: (context) => ClashNewsRepository(
        dataSource: ClashNewsLocalDataSource(),
        storage: context.read<ClashNewsReadStorageBackend>(),
      ),
    ),
    Provider<ClashGiftsRepository>(
      create: (context) => ClashGiftsRepository(
        dataSource: ClashGiftsLocalDataSource(),
        storage: context.read<ClashGiftsStorageBackend>(),
        storyRepository: context.read<ClashStoryRepository>(),
        rewardGranter: context.read<ClashLocalRewardGranter>(),
      ),
    ),
    Provider<ClashCharacterEventsRepository>(
      create: (context) => ClashCharacterEventsRepository(
        dataSource: ClashCharacterEventsLocalDataSource(),
        storage: context.read<ClashCharacterEventsStorageBackend>(),
        storyRepository: context.read<ClashStoryRepository>(),
        rewardGranter: context.read<ClashLocalRewardGranter>(),
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
      ),
    ),
    Provider<ClashTrialsRepository>(
      create: (context) => ClashTrialsRepository(
        dataSource: ClashTrialsLocalDataSource(),
        storage: context.read<ClashTrialsStorageBackend>(),
        rewardGranter: context.read<ClashLocalRewardGranter>(),
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
      ),
    ),
    Provider<ClashHelpRepository>(
      create: (_) =>
          ClashHelpRepository(dataSource: ClashHelpTopicsLocalDataSource()),
    ),
    Provider<ClashShopRepository>(
      create: (context) => ClashShopRepository(
        dataSource: ClashShopLocalDataSource(),
        storyRepository: context.read<ClashStoryRepository>(),
        rewardGranter: context.read<ClashLocalRewardGranter>(),
        progressEventHub: context.read<ClashMissionProgressEventHub>(),
      ),
    ),
    Provider<ClashGachaDailyStorageBackend>.value(
      value: deps.gachaDailyBackend,
    ),
    Provider<ClashGachaHistoryStorageBackend>.value(
      value: deps.gachaHistoryBackend,
    ),
    Provider<ClashGachaRepository>(
      create: (context) => ClashGachaRepository(
        dataSource: ClashGachaLocalDataSource(),
        dailyStorage: context.read<ClashGachaDailyStorageBackend>(),
        historyStorage: context.read<ClashGachaHistoryStorageBackend>(),
        pityStorage: context.read<ClashGachaPityStorageBackend>(),
        ticketRepository: context.read<ClashGachaTicketRepository>(),
        storyRepository: context.read<ClashStoryRepository>(),
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
        cardsRepository: context.read<ClashCardsRepository>(),
        progressEventHub: context.read<ClashMissionProgressEventHub>(),
      ),
    ),
    Provider<ClashLineupsStorageBackend>.value(value: deps.lineupsBackend),
    Provider<ClashLineupsRepository>(
      create: (context) => ClashLineupsRepository(
        storage: context.read<ClashLineupsStorageBackend>(),
        cardsRepository: context.read<ClashCardsRepository>(),
      ),
    ),
    ChangeNotifierProvider<ClashLineupsController>(
      create: (context) => ClashLineupsController(
        lineupsRepository: context.read<ClashLineupsRepository>(),
        collectionRepository: context.read<ClashPlayerCollectionRepository>(),
      ),
    ),
    Provider<ClashRivalsRepository>(create: (_) => ClashRivalsRepository()),
    ChangeNotifierProvider<ClashMatchController>(
      create: (_) => ClashMatchController(),
    ),
    ChangeNotifierProvider<ClashDecisiveMomentsController>(
      create: (_) => ClashDecisiveMomentsController(),
    ),
    ChangeNotifierProvider<ClashChainTrialController>(
      create: (_) => ClashChainTrialController(),
    ),
    ..._buildClashSyncProviders(deps),
  ];
}

List<SingleChildWidget> _buildClashSyncProviders(
  ClashProviderDependencies deps,
) {
  if (deps.syncClientOverride != null) {
    return [
      Provider<ClashSyncSnapshotBuilder>(
        create: (context) => _createClashSyncSnapshotBuilder(context, deps),
      ),
      Provider<ClashSyncSnapshotValidator>(
        create: (_) => const ClashSyncSnapshotValidator(),
      ),
      Provider<ClashSyncClient>.value(value: deps.syncClientOverride!),
      Provider<ClashSyncCoordinator>(
        create: (context) => ClashSyncCoordinator(
          builder: context.read<ClashSyncSnapshotBuilder>(),
          validator: context.read<ClashSyncSnapshotValidator>(),
          client: context.read<ClashSyncClient>(),
        ),
      ),
      ..._buildClashSyncApplierProviders(deps),
    ];
  }

  return [
    Provider<ClashSyncSnapshotBuilder>(
      create: (context) => _createClashSyncSnapshotBuilder(context, deps),
    ),
    Provider<ClashSyncSnapshotValidator>(
      create: (_) => const ClashSyncSnapshotValidator(),
    ),
    Provider<ClashSaveApiClient>(
      create: (context) =>
          ClashSaveApiClient.fromApiClient(context.read<ApiClient>()),
    ),
    Provider<HttpClashSyncClient>(
      create: (context) =>
          HttpClashSyncClient(context.read<ClashSaveApiClient>()),
    ),
    Provider<ClashSyncClient>(
      create: (context) => context.read<HttpClashSyncClient>(),
    ),
    Provider<ClashSyncCoordinator>(
      create: (context) => ClashSyncCoordinator(
        builder: context.read<ClashSyncSnapshotBuilder>(),
        validator: context.read<ClashSyncSnapshotValidator>(),
        client: context.read<ClashSyncClient>(),
      ),
    ),
    ..._buildClashSyncApplierProviders(deps),
  ];
}

List<SingleChildWidget> _buildClashSyncApplierProviders(
  ClashProviderDependencies deps,
) {
  if (deps.sharedPreferences == null) {
    return const [];
  }
  return [
    Provider<ClashSyncLocalBackupStore>(
      create: (_) =>
          ClashSyncLocalBackupStore(sharedPreferences: deps.sharedPreferences!),
    ),
    Provider<ClashSyncMetadataStorage>(
      create: (_) =>
          ClashSyncMetadataStorage(sharedPreferences: deps.sharedPreferences!),
    ),
    Provider<ClashSyncSettingsStorage>(
      create: (_) =>
          ClashSyncSettingsStorage(sharedPreferences: deps.sharedPreferences!),
    ),
    Provider<ClashSyncAutoCheckService>(
      create: (context) => ClashSyncAutoCheckService(
        coordinator: context.read<ClashSyncCoordinator>(),
        settingsStorage: context.read<ClashSyncSettingsStorage>(),
        metadataStorage: context.read<ClashSyncMetadataStorage>(),
        backupStore: context.read<ClashSyncLocalBackupStore>(),
      ),
    ),
    Provider<ClashClaimApiClient>(
      create: (context) =>
          ClashClaimApiClient.fromApiClient(context.read<ApiClient>()),
    ),
    Provider<ClashOnlineClaimRegistrar>(
      create: (context) => ClashOnlineClaimRegistrar(
        settingsStorage: context.read<ClashSyncSettingsStorage>(),
        claimApiClient: context.read<ClashClaimApiClient>(),
      ),
    ),
    Provider<ClashSyncSnapshotApplier>(
      create: (context) => ClashSyncSnapshotApplier(
        builder: context.read<ClashSyncSnapshotBuilder>(),
        validator: context.read<ClashSyncSnapshotValidator>(),
        dependencies: _createClashSyncSnapshotApplierDependencies(
          context,
          deps,
        ),
      ),
    ),
  ];
}

ClashSyncSnapshotBuilder _createClashSyncSnapshotBuilder(
  BuildContext context,
  ClashProviderDependencies deps,
) {
  return ClashSyncSnapshotBuilder(
    dependencies: ClashSyncSnapshotBuilderDependencies(
      schemaVersion: deps.migrationResult?.toVersion,
      collectionStorage: deps.collectionBackend,
      storyProgressStorage: deps.storyProgressBackend,
      expMaterialStorage: deps.expMaterialInventoryBackend,
      techniqueBookStorage: deps.techniqueBookInventoryBackend,
      evolutionMaterialStorage: deps.evolutionMaterialInventoryBackend,
      ticketInventoryStorage: deps.gachaTicketInventoryBackend,
      lineupsStorage: deps.lineupsBackend,
      giftsStorage: deps.giftsBackend,
      dailyMissionsStorage: deps.dailyMissionsBackend,
      weeklyMissionsStorage: deps.weeklyMissionsBackend,
      achievementsStorage: deps.achievementsBackend,
      characterEventsStorage: deps.characterEventsBackend,
      gachaHistoryStorage: deps.gachaHistoryBackend,
      gachaPityStorage: deps.gachaPityBackend,
      gachaDailyStorage: deps.gachaDailyBackend,
      rewardHistoryStorage: deps.rewardHistoryBackend,
      gachaRepository: context.read<ClashGachaRepository>(),
    ),
  );
}

ClashSyncSnapshotApplierDependencies
_createClashSyncSnapshotApplierDependencies(
  BuildContext context,
  ClashProviderDependencies deps,
) {
  return ClashSyncSnapshotApplierDependencies(
    sharedPreferences: deps.sharedPreferences!,
    collectionStorage: deps.collectionBackend,
    storyProgressStorage: deps.storyProgressBackend,
    expMaterialStorage: deps.expMaterialInventoryBackend,
    techniqueBookStorage: deps.techniqueBookInventoryBackend,
    evolutionMaterialStorage: deps.evolutionMaterialInventoryBackend,
    ticketInventoryStorage: deps.gachaTicketInventoryBackend,
    dailyMissionsStorage: deps.dailyMissionsBackend,
    weeklyMissionsStorage: deps.weeklyMissionsBackend,
    achievementsStorage: deps.achievementsBackend,
    giftsStorage: deps.giftsBackend,
    characterEventsStorage: deps.characterEventsBackend,
    gachaHistoryStorage: deps.gachaHistoryBackend,
    gachaPityStorage: deps.gachaPityBackend,
    gachaDailyStorage: deps.gachaDailyBackend,
    rewardHistoryStorage: deps.rewardHistoryBackend,
  );
}

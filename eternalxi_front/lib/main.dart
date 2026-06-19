import 'package:eternal_xi/core/localization/app_locale_resolver.dart';
import 'package:eternal_xi/app/app.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/core/storage/theme_preferences_storage.dart';
import 'package:eternal_xi/data/services/auth_api_service.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/data/services/user_progress_api_service.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_books_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_tickets_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_local_datasource.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievement_event_sink.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_local_datasource.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_mission_progress_event_hub.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_local_datasource.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_read_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_local_datasource.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_local_datasource.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/controller/profile_controller.dart';
import 'package:eternal_xi/features/profile/controller/user_preferences_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

Future<void> _lockPortraitOrientation() {
  return SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockPortraitOrientation();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tzdata.initializeTimeZones();

  final secureStorageService = SecureStorageService();
  final themePreferencesStorage = await ThemePreferencesStorage.create();
  final clashLineupsBackend =
      await SharedPreferencesClashLineupsBackend.create();
  final clashCollectionBackend =
      await SharedPreferencesClashPlayerCollectionBackend.create();
  final clashExpMaterialInventoryBackend =
      await SharedPreferencesClashExpMaterialInventoryBackend.create();
  final clashExpMaterialsRepository = ClashExpMaterialsRepository(
    dataSource: ClashExpMaterialsLocalDataSource(),
    inventoryStorage: clashExpMaterialInventoryBackend,
  );
  await clashExpMaterialsRepository.seedDefaultInventoryIfEmpty();
  final clashTechniqueBookInventoryBackend =
      await SharedPreferencesClashTechniqueBookInventoryBackend.create();
  final clashTechniqueBooksRepository = ClashTechniqueBooksRepository(
    dataSource: ClashTechniqueBooksLocalDataSource(),
    inventoryStorage: clashTechniqueBookInventoryBackend,
  );
  await clashTechniqueBooksRepository.seedDefaultInventoryIfEmpty();
  final clashEvolutionMaterialInventoryBackend =
      await SharedPreferencesClashEvolutionMaterialInventoryBackend.create();
  final clashEvolutionMaterialsRepository = ClashEvolutionMaterialsRepository(
    dataSource: ClashEvolutionMaterialsLocalDataSource(),
    inventoryStorage: clashEvolutionMaterialInventoryBackend,
  );
  await clashEvolutionMaterialsRepository.seedDefaultInventoryIfEmpty();
  final clashStoryProgressBackend =
      await SharedPreferencesClashStoryProgressBackend.create();
  final clashGachaDailyBackend =
      await SharedPreferencesClashGachaDailyBackend.create();
  final clashGachaHistoryBackend =
      await SharedPreferencesClashGachaHistoryBackend.create();
  final clashGachaPityBackend =
      await SharedPreferencesClashGachaPityBackend.create();
  final clashDailyMissionsBackend =
      await SharedPreferencesClashDailyMissionsBackend.create();
  final clashAchievementsBackend =
      await SharedPreferencesClashAchievementsBackend.create();
  final clashWeeklyMissionsBackend =
      await SharedPreferencesClashWeeklyMissionsBackend.create();
  final clashNewsReadBackend =
      await SharedPreferencesClashNewsReadBackend.create();
  final clashGiftsBackend = await SharedPreferencesClashGiftsBackend.create();
  final clashCharacterEventsBackend =
      await SharedPreferencesClashCharacterEventsBackend.create();
  final clashGachaTicketInventoryBackend =
      await SharedPreferencesClashGachaTicketInventoryBackend.create();
  final clashGachaTicketRepository = ClashGachaTicketRepository(
    dataSource: ClashGachaTicketsLocalDataSource(),
    inventoryStorage: clashGachaTicketInventoryBackend,
  );
  final apiClient = ApiClient(
    acceptLanguage: AppLocaleResolver.apiLanguageTag(),
    secureStorage: secureStorageService,
  );
  final savedThemeRaw =
      themePreferencesStorage.readThemeMode() ??
      await secureStorageService.getThemeMode();
  final savedLanguageRaw = await secureStorageService.getLanguageCode();
  final initialThemePreference = UserPreferencesController.themeFromStorage(
    savedThemeRaw,
  );
  final initialLanguagePreference =
      UserPreferencesController.languageFromStorage(savedLanguageRaw);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<AuthApiService>(
          create: (context) => AuthApiService(context.read<ApiClient>()),
        ),
        Provider<UserApiService>(
          create: (context) => UserApiService(context.read<ApiClient>()),
        ),
        Provider<UserProgressApiService>(
          create: (context) =>
              UserProgressApiService(context.read<ApiClient>()),
        ),
        Provider<LeaguesApiService>(
          create: (context) => LeaguesApiService(context.read<ApiClient>()),
        ),
        Provider<RewardsApiService>(
          create: (context) => RewardsApiService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final auth = AuthController(
              authApiService: context.read<AuthApiService>(),
              secureStorageService: context.read<SecureStorageService>(),
              userApiService: context.read<UserApiService>(),
            );
            // Sesión persistente: no expulsar al login automáticamente.
            return auth;
          },
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(
            userApiService: context.read<UserApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
          ),
        ),
        ChangeNotifierProvider<AccountProgressController>(
          create: (context) => AccountProgressController(
            progressApiService: context.read<UserProgressApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, UserPreferencesController>(
          create: (context) => UserPreferencesController(
            userApiService: context.read<UserApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
            apiClient: context.read<ApiClient>(),
            initialThemeMode: initialThemePreference,
            initialLanguageCode: initialLanguagePreference,
          ),
          update: (context, auth, preferences) {
            final controller =
                preferences ??
                UserPreferencesController(
                  userApiService: context.read<UserApiService>(),
                  secureStorageService: context.read<SecureStorageService>(),
                  apiClient: context.read<ApiClient>(),
                  initialThemeMode: initialThemePreference,
                  initialLanguageCode: initialLanguagePreference,
                );
            controller.syncWithUser(auth.currentUser?.id);
            return controller;
          },
        ),
        ChangeNotifierProvider<LeaguesController>(
          create: (context) => LeaguesController(
            leaguesApiService: context.read<LeaguesApiService>(),
          ),
        ),
        Provider<ClashCardsLocalDataSource>(
          create: (_) => ClashCardsLocalDataSource(),
        ),
        Provider<ClashCardsRepository>(
          create: (context) =>
              ClashCardsRepository(context.read<ClashCardsLocalDataSource>()),
        ),
        Provider<ClashPlayerCollectionStorageBackend>.value(
          value: clashCollectionBackend,
        ),
        Provider<ClashExpMaterialInventoryStorageBackend>.value(
          value: clashExpMaterialInventoryBackend,
        ),
        Provider<ClashExpMaterialsLocalDataSource>(
          create: (_) => ClashExpMaterialsLocalDataSource(),
        ),
        Provider<ClashExpMaterialsRepository>.value(
          value: clashExpMaterialsRepository,
        ),
        Provider<ClashTechniqueBookInventoryStorageBackend>.value(
          value: clashTechniqueBookInventoryBackend,
        ),
        Provider<ClashTechniqueBooksLocalDataSource>(
          create: (_) => ClashTechniqueBooksLocalDataSource(),
        ),
        Provider<ClashTechniqueBooksRepository>.value(
          value: clashTechniqueBooksRepository,
        ),
        Provider<ClashEvolutionMaterialInventoryStorageBackend>.value(
          value: clashEvolutionMaterialInventoryBackend,
        ),
        Provider<ClashEvolutionMaterialsLocalDataSource>(
          create: (_) => ClashEvolutionMaterialsLocalDataSource(),
        ),
        Provider<ClashEvolutionMaterialsRepository>.value(
          value: clashEvolutionMaterialsRepository,
        ),
        Provider<ClashGachaTicketInventoryStorageBackend>.value(
          value: clashGachaTicketInventoryBackend,
        ),
        Provider<ClashGachaTicketRepository>.value(
          value: clashGachaTicketRepository,
        ),
        Provider<ClashDailyMissionsStorageBackend>.value(
          value: clashDailyMissionsBackend,
        ),
        Provider<ClashAchievementsStorageBackend>.value(
          value: clashAchievementsBackend,
        ),
        Provider<ClashWeeklyMissionsStorageBackend>.value(
          value: clashWeeklyMissionsBackend,
        ),
        Provider<ClashNewsReadStorageBackend>.value(
          value: clashNewsReadBackend,
        ),
        Provider<ClashGiftsStorageBackend>.value(value: clashGiftsBackend),
        Provider<ClashCharacterEventsStorageBackend>.value(
          value: clashCharacterEventsBackend,
        ),
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
            techniqueBooksRepository: context
                .read<ClashTechniqueBooksRepository>(),
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
            techniqueBooksRepository: context
                .read<ClashTechniqueBooksRepository>(),
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
          value: clashStoryProgressBackend,
        ),
        Provider<ClashGachaPityStorageBackend>.value(
          value: clashGachaPityBackend,
        ),
        Provider<ClashStoryRepository>(
          create: (context) => ClashStoryRepository(
            dataSource: context.read<ClashStoryLocalDataSource>(),
            progressStorage: context.read<ClashStoryProgressStorageBackend>(),
            collectionRepository: context
                .read<ClashPlayerCollectionRepository>(),
            ticketRepository: context.read<ClashGachaTicketRepository>(),
          ),
        ),
        ChangeNotifierProvider<ClashStoryController>(
          create: (context) => ClashStoryController(
            storyRepository: context.read<ClashStoryRepository>(),
          ),
        ),
        Provider<ClashShopGrantService>(
          create: (context) => ClashShopGrantService(
            collectionRepository: context
                .read<ClashPlayerCollectionRepository>(),
            ticketRepository: context.read<ClashGachaTicketRepository>(),
          ),
        ),
        Provider<ClashDailyMissionsRepository>(
          create: (context) {
            final repository = ClashDailyMissionsRepository(
              dataSource: ClashDailyMissionsLocalDataSource(),
              storage: context.read<ClashDailyMissionsStorageBackend>(),
              storyRepository: context.read<ClashStoryRepository>(),
              grantService: context.read<ClashShopGrantService>(),
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
              grantService: context.read<ClashShopGrantService>(),
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
              grantService: context.read<ClashShopGrantService>(),
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
            grantService: context.read<ClashShopGrantService>(),
          ),
        ),
        Provider<ClashCharacterEventsRepository>(
          create: (context) => ClashCharacterEventsRepository(
            dataSource: ClashCharacterEventsLocalDataSource(),
            storage: context.read<ClashCharacterEventsStorageBackend>(),
            storyRepository: context.read<ClashStoryRepository>(),
            grantService: context.read<ClashShopGrantService>(),
            collectionRepository: context
                .read<ClashPlayerCollectionRepository>(),
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
            grantService: context.read<ClashShopGrantService>(),
            progressEventHub: context.read<ClashMissionProgressEventHub>(),
          ),
        ),
        Provider<ClashGachaDailyStorageBackend>.value(
          value: clashGachaDailyBackend,
        ),
        Provider<ClashGachaHistoryStorageBackend>.value(
          value: clashGachaHistoryBackend,
        ),
        Provider<ClashGachaRepository>(
          create: (context) => ClashGachaRepository(
            dataSource: ClashGachaLocalDataSource(),
            dailyStorage: context.read<ClashGachaDailyStorageBackend>(),
            historyStorage: context.read<ClashGachaHistoryStorageBackend>(),
            pityStorage: context.read<ClashGachaPityStorageBackend>(),
            ticketRepository: context.read<ClashGachaTicketRepository>(),
            storyRepository: context.read<ClashStoryRepository>(),
            collectionRepository: context
                .read<ClashPlayerCollectionRepository>(),
            cardsRepository: context.read<ClashCardsRepository>(),
            progressEventHub: context.read<ClashMissionProgressEventHub>(),
          ),
        ),
        Provider<ClashLineupsStorageBackend>.value(value: clashLineupsBackend),
        Provider<ClashLineupsRepository>(
          create: (context) => ClashLineupsRepository(
            storage: context.read<ClashLineupsStorageBackend>(),
            cardsRepository: context.read<ClashCardsRepository>(),
          ),
        ),
        ChangeNotifierProvider<ClashLineupsController>(
          create: (context) => ClashLineupsController(
            lineupsRepository: context.read<ClashLineupsRepository>(),
            collectionRepository: context
                .read<ClashPlayerCollectionRepository>(),
          ),
        ),
        Provider<ClashRivalsRepository>(create: (_) => ClashRivalsRepository()),
        ChangeNotifierProvider<ClashMatchController>(
          create: (_) => ClashMatchController(),
        ),
      ],
      child: const EternalXiApp(),
    ),
  );
}

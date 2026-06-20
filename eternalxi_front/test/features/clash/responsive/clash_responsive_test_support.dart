import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/screens/clash_achievements_screen.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/debug/presentation/clash_debug_screen.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_detail_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_events_screen.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/screens/clash_inventory_screen.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_daily_missions_screen.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_weekly_missions_screen.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/presentation/clash_reward_history_screen.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_reward_screen.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cards/clash_test_support.dart';
import '../di/clash_providers_test.dart';

/// Viewports móviles usados en Fase 63.
abstract final class ClashResponsiveViewports {
  static const smallPhone = Size(360, 640);
  static const mediumPhone = Size(390, 844);
  static const tallPhone = Size(430, 932);

  static const all = [smallPhone, mediumPhone, tallPhone];
  static const denseScreens = [smallPhone, mediumPhone, tallPhone];
}

const mikaEventId = 'event-mika-speed';
const mikaStoryStageId = 'event-mika-stage-01';
const mikaMatchStageId = 'event-mika-stage-02';

class ClashResponsivePumpResult {
  const ClashResponsivePumpResult(this.errors);

  final List<Object> errors;

  bool get hasLayoutError => errors.any(_isLayoutError);
}

bool _isLayoutError(Object error) {
  final message = error.toString();
  return message.contains('overflowed') ||
      message.contains('RenderFlex') ||
      message.contains('BoxConstraints') ||
      message.contains('A RenderFlex');
}

void configureClashResponsiveViewport(WidgetTester tester, Size physicalSize) {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> applyClashResponsiveSurface(
  WidgetTester tester,
  Size physicalSize,
) async {
  await tester.binding.setSurfaceSize(
    Size(physicalSize.width, physicalSize.height),
  );
}

Widget clashResponsiveMaterialApp({
  required Widget child,
  List<SingleChildWidget> providers = const [],
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

Future<ClashResponsivePumpResult> collectFlutterErrorsDuringPump(
  WidgetTester tester,
  Future<void> Function() pumpAction,
) async {
  final errors = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exception);
  };
  try {
    await pumpAction();
  } finally {
    FlutterError.onError = previous;
  }
  final testerError = tester.takeException();
  if (testerError != null) {
    errors.add(testerError);
  }
  return ClashResponsivePumpResult(errors);
}

void expectNoFlutterLayoutErrors(
  WidgetTester tester, {
  ClashResponsivePumpResult? pumpResult,
}) {
  final errors = <Object>[...?pumpResult?.errors];
  final stray = tester.takeException();
  if (stray != null) {
    errors.add(stray);
  }
  final layoutErrors = errors.where(_isLayoutError).toList();
  expect(
    layoutErrors,
    isEmpty,
    reason: layoutErrors.map((error) => error.toString()).join('\n'),
  );
}

Future<void> pumpClashScreen(
  WidgetTester tester, {
  required Widget widget,
  Duration asyncWait = const Duration(milliseconds: 400),
}) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump(asyncWait);
}

Future<void> pumpUntilFinder(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 60,
}) async {
  for (var step = 0; step < maxSteps; step++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('No se encontró $finder tras esperar');
}

Future<void> pumpUntilDebugLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var step = 0; step < 80; step++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        (find.text('Almacenamiento local').evaluate().isNotEmpty ||
            find
                .text('No se pudo cargar el diagnóstico local.')
                .evaluate()
                .isNotEmpty)) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('ClashDebugScreen no terminó de cargar');
}

Future<SharedPreferences> mockDebugPrefs() async {
  return SharedPreferences.getInstance();
}

typedef ClashResponsiveHomeDeps = ({
  ClashStoryController storyController,
  ClashShopRepository shopRepository,
  ClashDailyMissionsRepository missionsRepository,
  ClashWeeklyMissionsRepository weeklyMissionsRepository,
  ClashAchievementsRepository achievementsRepository,
  ClashNewsRepository newsRepository,
  ClashGiftsRepository giftsRepository,
  ClashCharacterEventsRepository eventsRepository,
});

Future<ClashResponsiveHomeDeps> createResponsiveHomeDeps() async {
  final missionsSetup = await createTestMissionsSetup(
    initialCoins: 1500,
    initialGems: 80,
  );
  final weeklySetup = await createTestWeeklyMissionsSetup(
    initialCoins: 1500,
    initialGems: 80,
  );
  final achievementsSetup = await createTestAchievementsSetup(
    initialCoins: 1500,
    initialGems: 80,
  );
  final newsSetup = await createTestNewsSetup();
  final giftsSetup = await createTestGiftsSetup();
  final eventsSetup = await createTestEventsSetup(
    initialCoins: 1500,
    initialGems: 80,
  );
  final shopRepository = await createTestShopRepository(
    storyRepository: missionsSetup.story,
    collectionRepository: missionsSetup.collection,
    initialCoins: 1500,
    initialGems: 80,
  );
  return (
    storyController: ClashStoryController(storyRepository: missionsSetup.story),
    shopRepository: shopRepository,
    missionsRepository: missionsSetup.missions,
    weeklyMissionsRepository: weeklySetup.weekly,
    achievementsRepository: achievementsSetup.achievements,
    newsRepository: newsSetup.news,
    giftsRepository: giftsSetup.gifts,
    eventsRepository: eventsSetup.events,
  );
}

List<SingleChildWidget> responsiveHomeProviders(ClashResponsiveHomeDeps deps) {
  return [
    ChangeNotifierProvider<ClashNavigationController>.value(
      value: ClashNavigationController(),
    ),
    ChangeNotifierProvider<ClashStoryController>.value(
      value: deps.storyController,
    ),
    Provider<ClashShopRepository>.value(value: deps.shopRepository),
    Provider<ClashDailyMissionsRepository>.value(
      value: deps.missionsRepository,
    ),
    Provider<ClashWeeklyMissionsRepository>.value(
      value: deps.weeklyMissionsRepository,
    ),
    Provider<ClashAchievementsRepository>.value(
      value: deps.achievementsRepository,
    ),
    Provider<ClashNewsRepository>.value(value: deps.newsRepository),
    Provider<ClashGiftsRepository>.value(value: deps.giftsRepository),
    Provider<ClashCharacterEventsRepository>.value(
      value: deps.eventsRepository,
    ),
  ];
}

Future<Widget> buildClashHomeScreen() async {
  final deps = await createResponsiveHomeDeps();
  return clashResponsiveMaterialApp(
    providers: responsiveHomeProviders(deps),
    child: const ClashHomeScreen(),
  );
}

Future<Widget> buildClashStoryMapScreen() async {
  final setup = await createTestMissionsSetup();
  final controller = ClashStoryController(storyRepository: setup.story);
  await controller.load();
  return clashResponsiveMaterialApp(
    providers: [
      ChangeNotifierProvider<ClashStoryController>.value(value: controller),
    ],
    child: const ClashStoryMapScreen(),
  );
}

Future<void> scrollUntilVisibleSafe(
  WidgetTester tester,
  Finder finder, {
  double delta = 120,
  int maxScrolls = 24,
}) async {
  if (finder.evaluate().isNotEmpty) {
    return;
  }
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) {
    return;
  }
  final scrollable = scrollables.first;
  for (var step = 0; step < maxScrolls; step++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.pump();
      return;
    }
    await tester.drag(scrollable, Offset(0, -delta));
    await tester.pump();
  }
}

Future<Widget> buildClashStoryRewardScreen() async {
  final setup = await createTestMissionsSetup();
  final controller = ClashStoryController(storyRepository: setup.story);
  await controller.load();
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  return clashResponsiveMaterialApp(
    providers: [
      ChangeNotifierProvider<ClashStoryController>.value(value: controller),
      Provider<ClashCardsRepository>.value(value: cardsRepo),
    ],
    child: const ClashStoryRewardScreen(levelId: 'prologue-lvl-01'),
  );
}

Future<Widget> buildClashEventsListScreen() async {
  final setup = await createTestEventsSetup();
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashCharacterEventsRepository>.value(value: setup.events),
      Provider<ClashCardsRepository>.value(
        value: ClashCardsRepository(GachaTestCardsDataSource()),
      ),
    ],
    child: const ClashEventsScreen(),
  );
}

Future<Widget> buildClashMikaDetailScreen() async {
  final setup = await createTestEventsSetup();
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashCharacterEventsRepository>.value(value: setup.events),
      Provider<ClashCardsRepository>.value(
        value: ClashCardsRepository(GachaTestCardsDataSource()),
      ),
    ],
    child: const ClashEventDetailScreen(eventId: mikaEventId),
  );
}

const _lineupCardsJson = '''
{
  "cards": [
    {"id": "c-gk", "playerId": 1, "name": "Portero", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "goalkeeper", "basicPortraitPath": "p", "stats": {"save": 40, "defense": 10, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-cb", "playerId": 2, "name": "Central", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "centreBack", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 30, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-fb", "playerId": 3, "name": "Lateral", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "fullBack", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 25, "pass": 12, "dribble": 10, "shot": 6, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-dm", "playerId": 4, "name": "MCD", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "defensiveMidfielder", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 20, "pass": 20, "dribble": 10, "shot": 8, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-am", "playerId": 5, "name": "MCO", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "attackingMidfielder", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 12, "pass": 22, "dribble": 14, "shot": 12, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-wg", "playerId": 6, "name": "Extremo", "team": "EXI", "rarity": "n", "level": 1, "style": "agil", "position": "winger", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 10, "pass": 14, "dribble": 22, "shot": 16, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-st", "playerId": 7, "name": "Delantero", "team": "EXI", "rarity": "n", "level": 1, "style": "potente", "position": "striker", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 12, "shot": 30, "techniquePoints": 10, "stamina": 100}, "superTechniques": []}
  ]
}
''';

class _LineupCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async {
    return parseCardsJson(_lineupCardsJson);
  }
}

Future<Widget> buildClashMikaMatchPrepareScreen() async {
  final setup = await createTestEventsSetup();
  await setup.events.completeStoryStage(
    eventId: mikaEventId,
    stageId: mikaStoryStageId,
  );
  final cardsRepo = ClashCardsRepository(_LineupCardsDataSource());
  final lineups = ClashLineupsController(
    lineupsRepository: ClashLineupsRepository(
      storage: InMemoryClashLineupsBackend(),
      cardsRepository: cardsRepo,
    ),
    collectionRepository: createTestCollectionRepository(
      cardsRepository: cardsRepo,
    ),
  );
  await lineups.load();
  return MultiProvider(
    providers: [
      Provider<ClashCharacterEventsRepository>.value(value: setup.events),
      ChangeNotifierProvider<ClashLineupsController>.value(value: lineups),
      Provider<ClashRivalsRepository>(create: (_) => ClashRivalsRepository()),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const ClashEventMatchPrepareScreen(
        eventId: mikaEventId,
        stageId: mikaMatchStageId,
      ),
    ),
  );
}

Future<Widget> buildClashGiftsScreen() async {
  final setup = await createTestGiftsSetup();
  return clashResponsiveMaterialApp(
    providers: [Provider<ClashGiftsRepository>.value(value: setup.gifts)],
    child: const ClashGiftsScreen(),
  );
}

Future<Widget> buildClashDailyMissionsScreen() async {
  final setup = await createTestMissionsSetup();
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashDailyMissionsRepository>.value(value: setup.missions),
    ],
    child: const ClashDailyMissionsScreen(),
  );
}

Future<Widget> buildClashWeeklyMissionsScreen() async {
  final setup = await createTestWeeklyMissionsSetup();
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashWeeklyMissionsRepository>.value(value: setup.weekly),
    ],
    child: const ClashWeeklyMissionsScreen(),
  );
}

Future<Widget> buildClashAchievementsScreen() async {
  final setup = await createTestAchievementsSetup();
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashAchievementsRepository>.value(value: setup.achievements),
    ],
    child: const ClashAchievementsScreen(),
  );
}

Future<Widget> buildClashShopScreen() async {
  final repo = await createTestShopRepository(
    initialCoins: 1500,
    initialGems: 80,
  );
  return clashResponsiveMaterialApp(
    providers: [Provider<ClashShopRepository>.value(value: repo)],
    child: const ClashShopScreen(),
  );
}

Future<Widget> buildClashInventoryScreen() async {
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashInventoryRepository>.value(
        value: createTestInventoryRepository(),
      ),
    ],
    child: const ClashInventoryScreen(),
  );
}

Future<Widget> buildClashRewardHistoryEmptyScreen() async {
  final repository = ClashRewardHistoryRepository(
    storage: InMemoryClashRewardHistoryBackend(),
  );
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashRewardHistoryRepository>.value(value: repository),
    ],
    child: const ClashRewardHistoryScreen(),
  );
}

Future<Widget> buildClashRewardHistoryFilledScreen() async {
  final repository = ClashRewardHistoryRepository(
    storage: InMemoryClashRewardHistoryBackend(),
  );
  await repository.recordGrant(
    sourceType: ClashRewardHistorySourceType.gift,
    sourceId: 'gift-responsive',
    title: 'Recompensa recibida',
    result: ClashRewardGrantResult(
      grantedRewards: [ClashReward.coins(100), ClashReward.gems(2)],
    ),
  );
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashRewardHistoryRepository>.value(value: repository),
    ],
    child: const ClashRewardHistoryScreen(),
  );
}

Future<Widget> buildClashDebugScreen() async {
  final prefs = await mockDebugPrefs();
  return MultiProvider(
    providers: buildClashProviders(testClashProviderDependencies()),
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ClashDebugScreen(sharedPreferences: prefs),
    ),
  );
}

ClashHelpRepository responsiveHelpRepository() {
  final dataSource = ClashHelpTopicsLocalDataSource();
  dataSource.clearCacheForTests();
  return ClashHelpRepository(dataSource: dataSource);
}

Future<Widget> buildClashHelpScreen() async {
  return clashResponsiveMaterialApp(
    providers: [
      Provider<ClashHelpRepository>.value(value: responsiveHelpRepository()),
    ],
    child: const ClashHelpScreen(),
  );
}

Future<ClashResponsivePumpResult> pumpResponsiveWidget(
  WidgetTester tester,
  Future<Widget> Function() buildWidget, {
  Duration asyncWait = const Duration(milliseconds: 400),
}) async {
  return collectFlutterErrorsDuringPump(tester, () async {
    await pumpClashScreen(
      tester,
      widget: await buildWidget(),
      asyncWait: asyncWait,
    );
  });
}

Future<void> resetResponsiveTestSurface(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 50),
  int maxSteps = 40,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
  }
}

String viewportLabel(Size size) =>
    '${size.width.toInt()}x${size.height.toInt()}';

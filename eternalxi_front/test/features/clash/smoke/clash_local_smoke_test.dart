import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/debug/presentation/clash_debug_screen.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_detail_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_events_screen.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/screens/clash_inventory_screen.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/presentation/clash_reward_history_screen.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/presentation/clash_reward_history_tile.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_chip.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cards/clash_test_support.dart';
import '../di/clash_providers_test.dart';

const _mikaEventId = 'event-mika-speed';

void _configureSmokeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _localizedApp({
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

Future<void> _pumpEventsLoaded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

Future<SharedPreferences> _mockDebugPrefs() async {
  SharedPreferences.setMockInitialValues({
    ClashSharedPreferencesKeys.schemaVersion: 1,
    ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpUntilDebugLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 80; i++) {
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

void _expectNoFlutterErrors(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

typedef _HomeDeps = ({
  ClashStoryController storyController,
  ClashShopRepository shopRepository,
  ClashDailyMissionsRepository missionsRepository,
  ClashWeeklyMissionsRepository weeklyMissionsRepository,
  ClashAchievementsRepository achievementsRepository,
  ClashNewsRepository newsRepository,
  ClashGiftsRepository giftsRepository,
  ClashCharacterEventsRepository eventsRepository,
});

Future<_HomeDeps> _homeDeps({
  int initialCoins = 1500,
  int initialGems = 80,
}) async {
  final missionsSetup = await createTestMissionsSetup(
    initialCoins: initialCoins,
    initialGems: initialGems,
  );
  final weeklySetup = await createTestWeeklyMissionsSetup(
    initialCoins: initialCoins,
    initialGems: initialGems,
  );
  final achievementsSetup = await createTestAchievementsSetup(
    initialCoins: initialCoins,
    initialGems: initialGems,
  );
  final newsSetup = await createTestNewsSetup();
  final giftsSetup = await createTestGiftsSetup();
  final eventsSetup = await createTestEventsSetup(
    initialCoins: initialCoins,
    initialGems: initialGems,
  );
  final shopRepository = await createTestShopRepository(
    storyRepository: missionsSetup.story,
    collectionRepository: missionsSetup.collection,
    initialCoins: initialCoins,
    initialGems: initialGems,
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

List<SingleChildWidget> _homeProviders(_HomeDeps deps) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clash local smoke Fase 62', () {
    testWidgets('A) home renderiza accesos principales', (tester) async {
      _configureSmokeViewport(tester);
      final deps = await _homeDeps();
      await tester.pumpWidget(
        MultiProvider(
          providers: _homeProviders(deps),
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Historia'), findsNothing);
      expect(find.text('Eventos'), findsNothing);
      _expectNoFlutterErrors(tester);
    });

    testWidgets('B) story muestra capítulo y recompensas', (tester) async {
      _configureSmokeViewport(tester);
      final missionsSetup = await createTestMissionsSetup();
      final controller = ClashStoryController(
        storyRepository: missionsSetup.story,
      );
      await controller.load();

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            ChangeNotifierProvider<ClashStoryController>.value(
              value: controller,
            ),
          ],
          child: const ClashStoryMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClashStoryMapScreen), findsOneWidget);
      expect(find.text('Historia'), findsWidgets);
      expect(find.textContaining('Torneo Eterno Campeón!'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsWidgets);
      _expectNoFlutterErrors(tester);
    });

    testWidgets('C) events lista y detalle Mika', (tester) async {
      _configureSmokeViewport(tester);
      final setup = await createTestEventsSetup();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: setup.events),
            Provider<ClashCardsRepository>.value(value: cardsRepo),
          ],
          child: const ClashEventsScreen(),
        ),
      );
      await _pumpEventsLoaded(tester);

      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Carrera de Mika'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Carrera de Mika'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: setup.events),
            Provider<ClashCardsRepository>.value(value: cardsRepo),
          ],
          child: const ClashEventDetailScreen(eventId: _mikaEventId),
        ),
      );
      await _pumpEventsLoaded(tester);

      expect(find.text('Carrera de Mika'), findsOneWidget);
      expect(find.text('Carta destacada'), findsWidgets);
      expect(find.text('Arranque rápido'), findsOneWidget);
      _expectNoFlutterErrors(tester);
    });

    testWidgets('D) gifts reclama reward y registra historial', (tester) async {
      _configureSmokeViewport(tester);
      final setup = await createTestGiftsSetup(initialCoins: 0);
      final historyRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashGiftsRepository>.value(value: setup.gifts),
            Provider<ClashRewardHistoryRepository>.value(
              value: historyRepository,
            ),
          ],
          child: const ClashGiftsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reclamar todos'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });

      expect(find.text('Recompensas recibidas'), findsOneWidget);
      expect(historyRepository.loadEntries(), isNotEmpty);
      expect(
        historyRepository.loadEntries().first.sourceType,
        ClashRewardHistorySourceType.gift,
      );
      _expectNoFlutterErrors(tester);
    });

    testWidgets('E) shop compra producto y registra historial', (tester) async {
      _configureSmokeViewport(tester);
      final shopRepository = await createTestShopRepository(initialCoins: 1500);
      final historyRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashShopRepository>.value(value: shopRepository),
            Provider<ClashRewardHistoryRepository>.value(
              value: historyRepository,
            ),
          ],
          child: const ClashShopScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
      _expectNoFlutterErrors(tester);
    });

    testWidgets('F) inventario muestra materiales y enlace historial', (
      tester,
    ) async {
      _configureSmokeViewport(tester);
      final inventoryRepository = createTestInventoryRepository();

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashInventoryRepository>.value(
              value: inventoryRepository,
            ),
          ],
          child: const ClashInventoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Manual básico de entrenamiento'), findsOneWidget);
      expect(find.text('Tickets'), findsWidgets);
      expect(find.text('Ver historial'), findsOneWidget);
      _expectNoFlutterErrors(tester);
    });

    testWidgets('G) reward history vacío y con entrada', (tester) async {
      _configureSmokeViewport(tester);
      final emptyRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashRewardHistoryRepository>.value(
              value: emptyRepository,
            ),
          ],
          child: const ClashRewardHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Historial de recompensas'), findsOneWidget);
      expect(find.text('Aún no hay recompensas registradas.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final filledRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );
      await filledRepository.recordGrant(
        sourceType: ClashRewardHistorySourceType.gift,
        sourceId: 'gift-smoke',
        title: 'Recompensa recibida',
        result: ClashRewardGrantResult(
          grantedRewards: [ClashReward.coins(100)],
        ),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashRewardHistoryRepository>.value(
              value: filledRepository,
            ),
          ],
          child: const ClashRewardHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClashRewardHistoryTile), findsOneWidget);
      expect(find.textContaining('Monedas'), findsWidgets);
      _expectNoFlutterErrors(tester);
    });

    testWidgets('H) debug muestra diagnóstico sin acciones destructivas', (
      tester,
    ) async {
      _configureSmokeViewport(tester);
      final prefs = await _mockDebugPrefs();

      await tester.pumpWidget(
        MultiProvider(
          providers: buildClashProviders(testClashProviderDependencies()),
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ClashDebugScreen(sharedPreferences: prefs),
          ),
        ),
      );
      await _pumpUntilDebugLoaded(tester);

      expect(find.text('Diagnóstico Clash'), findsOneWidget);
      expect(find.text('Schema version'), findsOneWidget);
      expect(find.text('Almacenamiento local'), findsOneWidget);
      expect(find.text('Colección'), findsOneWidget);
      expect(find.text('Claims'), findsOneWidget);
      expect(find.textContaining('Reset'), findsNothing);
      expect(find.textContaining('Delete'), findsNothing);
      expect(find.textContaining('Clear'), findsNothing);
      expect(find.textContaining('Borrar'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      _expectNoFlutterErrors(tester);
    });
  });
}

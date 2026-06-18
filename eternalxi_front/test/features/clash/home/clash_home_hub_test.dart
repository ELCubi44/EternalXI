import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_events_screen.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/single_child_widget.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_HomeDeps> homeDeps({
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
      storyController: ClashStoryController(
        storyRepository: missionsSetup.story,
      ),
      shopRepository: shopRepository,
      missionsRepository: missionsSetup.missions,
      weeklyMissionsRepository: weeklySetup.weekly,
      achievementsRepository: achievementsSetup.achievements,
      newsRepository: newsSetup.news,
      giftsRepository: giftsSetup.gifts,
      eventsRepository: eventsSetup.events,
    );
  }

  List<SingleChildWidget> homeProviders(
    _HomeDeps deps, {
    ClashNavigationController? nav,
  }) {
    return [
      ChangeNotifierProvider<ClashNavigationController>.value(
        value: nav ?? ClashNavigationController(),
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

  Future<Widget> homeApp({
    int initialCoins = 1500,
    int initialGems = 80,
    ClashNavigationController? nav,
  }) async {
    final deps = await homeDeps(
      initialCoins: initialCoins,
      initialGems: initialGems,
    );
    return MultiProvider(
      providers: homeProviders(deps, nav: nav),
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ClashHomeScreen(),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('ClashHome hub UI', () {
    testWidgets('muestra Eternal Clash y recursos', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(
        await homeApp(initialCoins: 1500, initialGems: 80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eternal Clash'), findsOneWidget);
      expect(find.textContaining('Gemas 80'), findsOneWidget);
      expect(find.textContaining('Monedas 1500'), findsOneWidget);
    });

    testWidgets('muestra accesos Historia Eventos Equipo Invocar', (
      tester,
    ) async {
      configureViewport(tester);
      await tester.pumpWidget(await homeApp());
      await tester.pumpAndSettle();

      expect(find.text('Historia'), findsWidgets);
      expect(find.text('Eventos'), findsWidgets);
      expect(find.text('Equipo'), findsWidgets);
      expect(find.text('Invocar'), findsWidgets);
    });

    testWidgets('muestra secciones diarias y avisos', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(await homeApp());
      await tester.pumpAndSettle();

      expect(find.text('Actividad diaria'), findsOneWidget);
      expect(find.text('Misiones diarias'), findsOneWidget);
      expect(find.text('Misiones semanales'), findsOneWidget);
      expect(find.text('Logros'), findsOneWidget);
      expect(find.text('Avisos y recompensas'), findsOneWidget);
      expect(find.text('Noticias'), findsOneWidget);
      expect(find.text('Regalos'), findsOneWidget);
      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('muestra evento destacado Entrenamiento de Arin', (
      tester,
    ) async {
      configureViewport(tester);
      await tester.pumpWidget(await homeApp());
      await tester.pumpAndSettle();

      expect(find.text('Evento destacado'), findsOneWidget);
      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      expect(find.text('0/3 fases'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('noticias muestra contador no leídas', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(await homeApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('6 sin leer'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('6 sin leer'), findsOneWidget);
    });

    testWidgets('regalos muestra contador pendientes', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(await homeApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('4 pendientes'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('4 pendientes'), findsOneWidget);
    });

    testWidgets('sin overflow en layout básico', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(await homeApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('pulsar Historia navega a pantalla historia', (tester) async {
      configureViewport(tester);
      final deps = await homeDeps();
      final router = GoRouter(
        initialLocation: AppRoutes.clash,
        routes: [
          GoRoute(
            path: AppRoutes.clash,
            builder: (context, state) => MultiProvider(
              providers: homeProviders(deps),
              child: const ClashHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashStory,
            builder: (context, state) =>
                ChangeNotifierProvider<ClashStoryController>.value(
                  value: deps.storyController,
                  child: const ClashStoryMapScreen(),
                ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historia').first);
      await tester.pumpAndSettle();
      expect(find.byType(ClashStoryMapScreen), findsOneWidget);
    });

    testWidgets('pulsar Eventos navega a lista de eventos', (tester) async {
      configureViewport(tester);
      final deps = await homeDeps();
      final router = GoRouter(
        initialLocation: AppRoutes.clash,
        routes: [
          GoRoute(
            path: AppRoutes.clash,
            builder: (context, state) => MultiProvider(
              providers: homeProviders(deps),
              child: const ClashHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashEvents,
            builder: (context, state) =>
                Provider<ClashCharacterEventsRepository>.value(
                  value: deps.eventsRepository,
                  child: const ClashEventsScreen(),
                ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eventos').first);
      await tester.pumpAndSettle();
      expect(find.byType(ClashEventsScreen), findsOneWidget);
    });

    testWidgets('Invocar cambia pestaña del shell', (tester) async {
      configureViewport(tester);
      final nav = ClashNavigationController();
      await tester.pumpWidget(await homeApp(nav: nav));
      await tester.pumpAndSettle();
      expect(nav.tabIndex, 0);
      await tester.tap(find.text('Invocar').first);
      await tester.pumpAndSettle();
      expect(nav.tabIndex, 2);
    });

    testWidgets('Cambiar modo navega al selector', (tester) async {
      configureViewport(tester);
      final deps = await homeDeps();
      final router = GoRouter(
        initialLocation: AppRoutes.clash,
        routes: [
          GoRoute(
            path: AppRoutes.clash,
            builder: (context, state) => MultiProvider(
              providers: homeProviders(deps),
              child: const ClashHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.mode,
            builder: (context, state) =>
                const Scaffold(body: Text('MODE_SELECTOR_STUB')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar modo'));
      await tester.pumpAndSettle();
      expect(find.text('MODE_SELECTOR_STUB'), findsOneWidget);
    });
  });
}

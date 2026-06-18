import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/models/user_model.dart';
import 'package:eternal_xi/data/services/auth_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/presentation/clash_shell_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_tab_host.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_completion_unlocks.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/mode/screens/mode_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../firebase_test_setup.dart';
import '../clash/cards/clash_test_support.dart';

AuthController _authWithUser(UserModel? user) {
  final auth = AuthController(
    authApiService: AuthApiService(ApiClient()),
    secureStorageService: SecureStorageService(),
    userApiService: UserApiService(ApiClient()),
  );
  auth.currentUser = user;
  return auth;
}

class _EmptyCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [];
}

Future<
  ({
    ClashStoryController storyController,
    ClashGachaRepository gachaRepository,
    ClashCardsController cardsController,
    ClashShopRepository shopRepository,
    ClashDailyMissionsRepository missionsRepository,
    ClashWeeklyMissionsRepository weeklyMissionsRepository,
    ClashAchievementsRepository achievementsRepository,
  })
>
_shellDeps() async {
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
  );
  final storyProgress = InMemoryClashStoryProgressBackend();
  await storyProgress.writeProgress(
    const ClashStoryProgress(
      unlocks: ClashStoryCompletionUnlocks(clashTeamUnlocked: true),
      walletGems: 50,
    ),
  );
  final storyRepo = ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: storyProgress,
    collectionRepository: collectionRepo,
  );
  final gachaRepo = await createTestGachaRepository(
    cardsRepository: cardsRepo,
    collectionRepository: collectionRepo,
    storyRepository: storyRepo,
    initialGems: 50,
  );
  final cardsController = ClashCardsController(cardsRepo, collectionRepo);
  await cardsController.load();
  final shopRepo = await createTestShopRepository(
    storyRepository: storyRepo,
    collectionRepository: collectionRepo,
    initialCoins: 1500,
    initialGems: 50,
  );
  final missionsSetup = await createTestMissionsSetup(
    initialCoins: 1500,
    initialGems: 50,
  );
  final achievementsSetup = await createTestAchievementsSetup(
    initialCoins: 1500,
    initialGems: 50,
  );
  final weeklySetup = await createTestWeeklyMissionsSetup(
    initialCoins: 1500,
    initialGems: 50,
  );
  return (
    storyController: ClashStoryController(storyRepository: storyRepo),
    gachaRepository: gachaRepo,
    cardsController: cardsController,
    shopRepository: shopRepo,
    missionsRepository: missionsSetup.missions,
    weeklyMissionsRepository: weeklySetup.weekly,
    achievementsRepository: achievementsSetup.achievements,
  );
}

Future<(Widget app, ClashNavigationController nav)> _shellApp(
  AuthController auth,
) async {
  final deps = await _shellDeps();
  final nav = ClashNavigationController();
  final app = ChangeNotifierProvider<AuthController>.value(
    value: auth,
    child: ChangeNotifierProvider<ClashNavigationController>.value(
      value: nav,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ClashStoryController>.value(
            value: deps.storyController,
          ),
          Provider<ClashGachaRepository>.value(value: deps.gachaRepository),
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
          ChangeNotifierProvider<ClashCardsController>.value(
            value: deps.cardsController,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ClashShellScreen(body: ClashTabHost()),
        ),
      ),
    ),
  );
  return (app, nav);
}

Future<Widget> _routerApp(GoRouter router, AuthController auth) async {
  final deps = await _shellDeps();
  return ChangeNotifierProvider<AuthController>.value(
    value: auth,
    child: MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>.value(
              value: deps.storyController,
            ),
            Provider<ClashGachaRepository>.value(value: deps.gachaRepository),
            Provider<ClashShopRepository>.value(value: deps.shopRepository),
            ChangeNotifierProvider<ClashCardsController>.value(
              value: deps.cardsController,
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}

GoRouter _clashRouter(AuthController auth) {
  return GoRouter(
    initialLocation: AppRoutes.clash,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ChangeNotifierProvider(
            create: (_) => ClashNavigationController(),
            child: ClashShellScreen(body: child),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.clash,
            builder: (context, state) => const ClashTabHost(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.mode,
        builder: (context, state) => const ModeSelectionScreen(),
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    await ensureFirebaseInitializedForTests();
  });

  const testUser = UserModel(
    id: 1,
    correo: 'test@eternalxi.com',
    nickname: 'Tester',
    nivel: 1,
  );

  AuthController auth() => _authWithUser(testUser);

  group('ClashShellScreen', () {
    testWidgets('renderiza las 4 pestañas', (tester) async {
      final (app, _) = await _shellApp(auth());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Equipo'), findsWidgets);
      expect(find.text('Invocar'), findsOneWidget);
      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('Inicio muestra Historia y Eventos', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (app, _) = await _shellApp(auth());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Historia'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Eventos'), findsOneWidget);
      expect(find.text('Misiones diarias'), findsOneWidget);
      expect(find.text('Misiones semanales'), findsOneWidget);
      expect(find.text('Logros'), findsOneWidget);
    });

    testWidgets('cambiar a Equipo muestra alineaciones', (tester) async {
      final (app, _) = await _shellApp(auth());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Equipo').last);
      await tester.pumpAndSettle();

      expect(find.text('Alineación 7vs7'), findsOneWidget);
      expect(find.text('Alineación 11vs11'), findsOneWidget);
    });

    testWidgets('cambiar a Invocar muestra Single y Multi', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final deps = await _shellDeps();
      expect(deps.storyController.clashTeamUnlocked, isTrue);

      final (app, nav) = await _shellApp(auth());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      nav.selectTab(2);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Simulación local sin compras reales'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
      expect(find.textContaining('95 gemas'), findsOneWidget);
    });

    testWidgets('cambiar a Tienda muestra productos locales', (tester) async {
      final (app, _) = await _shellApp(auth());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tienda'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tienda local de prueba'), findsOneWidget);
      expect(find.textContaining('Monedas:'), findsOneWidget);
      expect(find.text('Comprar'), findsWidgets);
    });

    testWidgets('volver al selector funciona', (tester) async {
      final controller = auth();
      final router = _clashRouter(controller);
      await tester.pumpWidget(await _routerApp(router, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Entrar a Fantasy'), findsOneWidget);
      expect(find.text('Entrar a Clash'), findsOneWidget);
    });
  });
}

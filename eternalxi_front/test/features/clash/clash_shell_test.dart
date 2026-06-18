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
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/presentation/clash_shell_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_tab_host.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/mode/screens/mode_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../firebase_test_setup.dart';
import '../clash/cards/clash_test_support.dart';

class _EmptyCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [];
}

ClashStoryController _storyController() {
  final cardsRepo = ClashCardsRepository(_EmptyCardsDataSource());
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
  );
  final storyRepo = ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: InMemoryClashStoryProgressBackend(),
    collectionRepository: collectionRepo,
  );
  return ClashStoryController(storyRepository: storyRepo);
}

AuthController _authWithUser(UserModel? user) {
  final auth = AuthController(
    authApiService: AuthApiService(ApiClient()),
    secureStorageService: SecureStorageService(),
    userApiService: UserApiService(ApiClient()),
  );
  auth.currentUser = user;
  return auth;
}

Widget _shellApp(AuthController auth) {
  return ChangeNotifierProvider<AuthController>.value(
    value: auth,
    child: ChangeNotifierProvider(
      create: (_) => ClashNavigationController(),
      child: ChangeNotifierProvider(
        create: (_) => _storyController(),
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ClashShellScreen(body: ClashTabHost()),
        ),
      ),
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
            child: ChangeNotifierProvider(
              create: (_) => _storyController(),
              child: ClashShellScreen(body: child),
            ),
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

Widget _routerApp(GoRouter router, AuthController auth) {
  return ChangeNotifierProvider<AuthController>.value(
    value: auth,
    child: MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
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
      await tester.pumpWidget(_shellApp(auth()));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Equipo'), findsWidgets);
      expect(find.text('Invocar'), findsOneWidget);
      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('Inicio muestra Historia y Eventos', (tester) async {
      await tester.pumpWidget(_shellApp(auth()));
      await tester.pumpAndSettle();

      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Eventos'), findsOneWidget);
    });

    testWidgets('cambiar a Equipo muestra alineaciones', (tester) async {
      await tester.pumpWidget(_shellApp(auth()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Equipo').last);
      await tester.pumpAndSettle();

      expect(find.text('Alineación 7vs7'), findsOneWidget);
      expect(find.text('Alineación 11vs11'), findsOneWidget);
    });

    testWidgets('cambiar a Invocar muestra Single y Multi', (tester) async {
      await tester.pumpWidget(_shellApp(auth()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invocar'));
      await tester.pumpAndSettle();

      expect(find.text('Single'), findsOneWidget);
      expect(find.text('Multi'), findsOneWidget);
    });

    testWidgets('cambiar a Tienda muestra Gemas y Packs', (tester) async {
      await tester.pumpWidget(_shellApp(auth()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tienda'));
      await tester.pumpAndSettle();

      expect(find.text('Gemas'), findsWidgets);
      expect(find.text('Packs'), findsOneWidget);
    });

    testWidgets('volver al selector funciona', (tester) async {
      final controller = auth();
      final router = _clashRouter(controller);
      await tester.pumpWidget(_routerApp(router, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Entrar a Fantasy'), findsOneWidget);
      expect(find.text('Entrar a Clash'), findsOneWidget);
    });
  });
}

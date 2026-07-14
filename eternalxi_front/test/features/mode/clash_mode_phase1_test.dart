import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/router_auth.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/models/user_model.dart';
import 'package:eternal_xi/data/services/auth_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/data/services/user_progress_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/presentation/clash_shell_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_tab_host.dart';
import 'package:eternal_xi/features/mode/screens/mode_selection_screen.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../clash/cards/clash_test_support.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../firebase_test_setup.dart';

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

Widget _withProgress(Widget child, AuthController auth) {
  final apiClient = ApiClient();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<AccountProgressController>(
        create: (_) => AccountProgressController(
          progressApiService: UserProgressApiService(apiClient),
          secureStorageService: SecureStorageService(),
        ),
      ),
    ],
    child: child,
  );
}

Widget _localizedApp({required Widget home, AuthController? auth}) {
  final resolvedAuth = auth ?? _authWithUser(null);
  return _withProgress(
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
    resolvedAuth,
  );
}

GoRouter _phase1TestRouter(AuthController auth) {
  return GoRouter(
    initialLocation: AppRoutes.mode,
    routes: [
      GoRoute(
        path: AppRoutes.mode,
        redirect: redirectIfUnauthenticated,
        builder: (context, state) => const ModeSelectionScreen(),
      ),
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
            redirect: redirectIfUnauthenticated,
            builder: (context, state) => const ClashTabHost(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.leagues,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Leagues Test Page'))),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Login Test Page'))),
      ),
    ],
  );
}

Widget _routerApp(GoRouter router, AuthController auth) {
  return _withProgress(
    MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
    auth,
  );
}

void main() {
  setUpAll(() async {
    await ensureFirebaseInitializedForTests();
  });

  group('ModeSelectionScreen', () {
    testWidgets('renderiza opciones Fantasy y Clash', (tester) async {
      final auth = _authWithUser(
        const UserModel(
          id: 1,
          correo: 'test@eternalxi.com',
          nickname: 'Tester',
          nivel: 3,
        ),
      );

      await tester.pumpWidget(
        _localizedApp(home: const ModeSelectionScreen(), auth: auth),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fantasy'), findsOneWidget);
      expect(find.text('Clash'), findsOneWidget);
      expect(find.text('Entrar'), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Fantasy navega a /leagues', (tester) async {
      final auth = _authWithUser(
        const UserModel(
          id: 1,
          correo: 'test@eternalxi.com',
          nickname: 'Tester',
          nivel: 1,
        ),
      );
      final router = _phase1TestRouter(auth);

      await tester.pumpWidget(_routerApp(router, auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar').first);
      await tester.pumpAndSettle();

      expect(find.text('Leagues Test Page'), findsOneWidget);
    });

    testWidgets('Clash navega a /clash', (tester) async {
      final auth = _authWithUser(
        const UserModel(
          id: 1,
          correo: 'test@eternalxi.com',
          nickname: 'Tester',
          nivel: 1,
        ),
      );
      final router = _phase1TestRouter(auth);

      await tester.pumpWidget(_routerApp(router, auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar').last);
      await tester.pumpAndSettle();

      expect(find.text('Eternal XI Clash'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
    });
  });

  group('redirectIfUnauthenticated', () {
    testWidgets('sin sesión redirige /mode a login', (tester) async {
      final auth = _authWithUser(null);
      final router = _phase1TestRouter(auth);

      await tester.pumpWidget(_routerApp(router, auth));
      router.go(AppRoutes.mode);
      await tester.pumpAndSettle();

      expect(find.text('Login Test Page'), findsOneWidget);
    });
  });
}

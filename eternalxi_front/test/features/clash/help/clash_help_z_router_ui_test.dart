import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_screen.dart';
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_topic_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

late ClashHelpTopicsLocalDataSource _helpDataSource;

ClashHelpRepository _helpRepository() {
  return ClashHelpRepository(dataSource: _helpDataSource);
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 40,
}) async {
  for (var step = 0; step < maxSteps; step++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('No se encontró $finder tras esperar');
}

Future<void> _resetTesterSurface(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _helpDataSource = ClashHelpTopicsLocalDataSource();
    _helpDataSource.clearCacheForTests();
  });

  group('ClashHelp router UI Fase 51', () {
    testWidgets('detalle, Leer y rutas relacionadas', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final nav = ClashNavigationController();
      final router = GoRouter(
        initialLocation: AppRoutes.clashHelp,
        routes: [
          GoRoute(
            path: AppRoutes.clashHelp,
            builder: (context, state) => Provider<ClashHelpRepository>.value(
              value: _helpRepository(),
              child: const ClashHelpScreen(),
            ),
            routes: [
              GoRoute(
                path: ':topicId',
                builder: (context, state) => MultiProvider(
                  providers: [
                    Provider<ClashHelpRepository>.value(
                      value: _helpRepository(),
                    ),
                    ChangeNotifierProvider<ClashNavigationController>.value(
                      value: nav,
                    ),
                  ],
                  child: ClashHelpTopicScreen(
                    topicId: state.pathParameters['topicId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.clash,
            builder: (context, state) =>
                ChangeNotifierProvider<ClashNavigationController>.value(
                  value: nav,
                  child: const Scaffold(body: Center(child: Text('Clash hub'))),
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
      await _pumpUntilFound(tester, find.text('¿Qué es Eternal Clash?'));

      await tester.tap(find.text('Leer').first);
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Avanza en historia y eventos'));
      expect(find.text('Mejora tus cartas'), findsOneWidget);

      router.go('/clash/help/summon');
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Invocar y pity'));
      expect(find.text('Pity SR'), findsOneWidget);

      await tester.tap(find.text('Ir a Invocar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(nav.tabIndex, 2);
      expect(find.text('Clash hub'), findsOneWidget);

      await _resetTesterSurface(tester);
      router.dispose();
    });

    testWidgets('Home pulsa Ayuda y navega a guía', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final deps = await createTestMissionsSetup();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ChangeNotifierProvider(
              create: (_) => ClashStoryController(storyRepository: deps.story),
              child: const ClashHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashHelp,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Guía cargada'))),
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
      await _pumpUntilFound(tester, find.text('Guía Clash'));

      await tester.tap(find.text('Guía Clash'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Guía cargada'));

      await _resetTesterSurface(tester);
      router.dispose();
    });
  });
}

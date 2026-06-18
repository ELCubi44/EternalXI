import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_local_datasource.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_read_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_type.dart';
import 'package:eternal_xi/features/clash/news/presentation/screens/clash_news_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashNewsLocalDataSource', () {
    test('carga noticias desde JSON', () {
      final items = ClashNewsLocalDataSource().parseNewsJson(clashTestNewsJson);
      expect(items, hasLength(6));
      expect(items.first.id, 'news-pinned-old');
    });
  });

  group('ClashNewsRepository', () {
    test('ordena pinned primero', () async {
      final setup = await createTestNewsSetup();
      final entries = await setup.news.fetchNewsEntries();
      expect(entries[0].item.id, 'news-pinned-new');
      expect(entries[1].item.id, 'news-pinned-old');
      expect(entries[2].item.isPinned, isFalse);
    });

    test('ordena por fecha descendente', () async {
      final setup = await createTestNewsSetup();
      final entries = await setup.news.fetchNewsEntries();
      final unpinned = entries.where((entry) => !entry.item.isPinned).toList();
      expect(unpinned[0].item.id, 'news-latest');
      expect(unpinned[1].item.id, 'news-maintenance');
      expect(unpinned[2].item.id, 'news-gift');
    });

    test('noticias no leídas inicialmente', () async {
      final setup = await createTestNewsSetup();
      final entries = await setup.news.fetchNewsEntries();
      expect(entries.every((entry) => !entry.isRead), isTrue);
      final summary = await setup.news.fetchSummary();
      expect(summary.unreadCount, 6);
    });

    test('marcar una como leída', () async {
      final setup = await createTestNewsSetup();
      await setup.news.markAsRead('news-latest');
      final entries = await setup.news.fetchNewsEntries();
      final latest = entries.firstWhere(
        (entry) => entry.item.id == 'news-latest',
      );
      expect(latest.isRead, isTrue);
      final summary = await setup.news.fetchSummary();
      expect(summary.unreadCount, 5);
    });

    test('marcar todas como leídas', () async {
      final setup = await createTestNewsSetup();
      await setup.news.markAllAsRead();
      final entries = await setup.news.fetchNewsEntries();
      expect(entries.every((entry) => entry.isRead), isTrue);
      final summary = await setup.news.fetchSummary();
      expect(summary.unreadCount, 0);
      expect(summary.allCaughtUp, isTrue);
    });

    test('noticia nueva queda no leída', () async {
      final storage = InMemoryClashNewsReadBackend();
      await storage.writeState(
        const ClashNewsReadState(
          readNewsIds: {'news-pinned-old', 'news-pinned-new'},
        ),
      );
      final setup = await createTestNewsSetup(storage: storage);
      final latest = (await setup.news.fetchNewsEntries()).firstWhere(
        (entry) => entry.item.id == 'news-latest',
      );
      expect(latest.isRead, isFalse);
    });

    test('filtro no leídas', () async {
      final setup = await createTestNewsSetup();
      await setup.news.markAsRead('news-latest');
      final entries = await setup.news.fetchNewsEntries();
      final unread = ClashNewsRepository.filterEntries(
        entries,
        ClashNewsFilter.unread,
      );
      expect(unread, hasLength(5));
      expect(unread.every((entry) => !entry.isRead), isTrue);
    });

    test('filtro por tipo', () async {
      final setup = await createTestNewsSetup();
      final entries = await setup.news.fetchNewsEntries();
      final events = ClashNewsRepository.filterEntries(
        entries,
        ClashNewsFilter.events,
      );
      expect(events, hasLength(1));
      expect(events.first.item.type, ClashNewsType.event);

      final notices = ClashNewsRepository.filterEntries(
        entries,
        ClashNewsFilter.notices,
      );
      expect(notices, hasLength(2));
      expect(notices.map((entry) => entry.item.type).toSet(), {
        ClashNewsType.maintenance,
        ClashNewsType.gift,
      });
    });
  });

  group('ClashNews UI', () {
    Future<Widget> newsApp(ClashNewsRepository repo) async {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Provider<ClashNewsRepository>.value(
          value: repo,
          child: const ClashNewsScreen(),
        ),
      );
    }

    Future<Widget> homeApp(ClashNewsRepository repo) async {
      final achievementsSetup = await createTestAchievementsSetup();
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>(
              create: (_) => ClashStoryController(
                storyRepository: achievementsSetup.story,
              ),
            ),
            Provider<ClashNewsRepository>.value(value: repo),
          ],
          child: const ClashHomeScreen(),
        ),
      );
    }

    testWidgets('Home muestra tarjeta Noticias', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await homeApp(setup.news));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Noticias'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Noticias'), findsOneWidget);
    });

    testWidgets('tarjeta muestra número no leídas', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await homeApp(setup.news));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('6 sin leer'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('6 sin leer'), findsOneWidget);
    });

    testWidgets('pulsar Ver navega a /clash/news', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestNewsSetup();
      final achievementsSetup = await createTestAchievementsSetup();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.clash,
            builder: (context, state) => MultiProvider(
              providers: [
                ChangeNotifierProvider<ClashStoryController>(
                  create: (_) => ClashStoryController(
                    storyRepository: achievementsSetup.story,
                  ),
                ),
                Provider<ClashNewsRepository>.value(value: setup.news),
              ],
              child: const ClashHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashNews,
            builder: (context, state) => Provider<ClashNewsRepository>.value(
              value: setup.news,
              child: const ClashNewsScreen(),
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
      router.go(AppRoutes.clash);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('6 sin leer'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      final newsCard = find.ancestor(
        of: find.textContaining('6 sin leer'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(of: newsCard, matching: find.text('Ver')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Marcar todas como leídas'), findsOneWidget);
    });

    testWidgets('pantalla muestra lista', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.text('Pinned reciente'), findsOneWidget);
      expect(find.text('Última noticia'), findsOneWidget);
    });

    testWidgets('muestra badge Nuevo', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo'), findsWidgets);
    });

    testWidgets('pulsar noticia la marca como leída', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Última noticia'));
      await tester.pumpAndSettle();
      final entries = await setup.news.fetchNewsEntries();
      final latest = entries.firstWhere(
        (entry) => entry.item.id == 'news-latest',
      );
      expect(latest.isRead, isTrue);
    });

    testWidgets('Marcar todas como leídas elimina badges', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo'), findsWidgets);
      await tester.tap(find.text('Marcar todas como leídas'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo'), findsNothing);
    });

    testWidgets('cabecera muestra no leídas', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.textContaining('sin leer'), findsOneWidget);
    });

    testWidgets('filtro vacío muestra empty state', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar todas como leídas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No leídas'));
      await tester.pumpAndSettle();
      expect(find.text('Sin noticias en este filtro'), findsOneWidget);
    });

    testWidgets('filtros funcionan', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eventos'));
      await tester.pumpAndSettle();
      expect(find.text('Última noticia'), findsOneWidget);
      expect(find.text('Pinned reciente'), findsNothing);

      await tester.tap(find.text('Banners'));
      await tester.pumpAndSettle();
      expect(find.text('Banner local'), findsOneWidget);
      expect(find.text('Última noticia'), findsNothing);
    });
  });
}

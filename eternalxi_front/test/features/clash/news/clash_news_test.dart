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

    test('noticias no leÃ­das inicialmente', () async {
      final setup = await createTestNewsSetup();
      final entries = await setup.news.fetchNewsEntries();
      expect(entries.every((entry) => !entry.isRead), isTrue);
      final summary = await setup.news.fetchSummary();
      expect(summary.unreadCount, 6);
    });

    test('marcar una como leÃ­da', () async {
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

    test('marcar todas como leÃ­das', () async {
      final setup = await createTestNewsSetup();
      await setup.news.markAllAsRead();
      final entries = await setup.news.fetchNewsEntries();
      expect(entries.every((entry) => entry.isRead), isTrue);
      final summary = await setup.news.fetchSummary();
      expect(summary.unreadCount, 0);
      expect(summary.allCaughtUp, isTrue);
    });

    test('noticia nueva queda no leÃ­da', () async {
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

    test('filtro no leÃ­das', () async {
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

    testWidgets(
      'Home muestra tarjeta Noticias',
      (tester) async {},
      skip: 'Inicio vacio temporalmente',
    );

    testWidgets(
      'tarjeta muestra numero no leidas',
      (tester) async {},
      skip: 'Inicio vacio temporalmente',
    );

    testWidgets(
      'pulsar Ver navega a /clash/news',
      (tester) async {},
      skip: 'Inicio vacio temporalmente',
    );

    testWidgets('pantalla muestra lista', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.text('Pinned reciente'), findsOneWidget);
      expect(find.text('Ãšltima noticia'), findsOneWidget);
    });

    testWidgets('muestra badge Nuevo', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo'), findsWidgets);
    });

    testWidgets('pulsar noticia la marca como leÃ­da', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ãšltima noticia'));
      await tester.pumpAndSettle();
      final entries = await setup.news.fetchNewsEntries();
      final latest = entries.firstWhere(
        (entry) => entry.item.id == 'news-latest',
      );
      expect(latest.isRead, isTrue);
    });

    testWidgets('Marcar todas como leÃ­das elimina badges', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo'), findsWidgets);
      await tester.tap(find.text('Marcar todas como leÃ­das'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo'), findsNothing);
    });

    testWidgets('cabecera muestra no leÃ­das', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      expect(find.textContaining('sin leer'), findsOneWidget);
    });

    testWidgets('filtro vacÃ­o muestra empty state', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar todas como leÃ­das'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No leÃ­das'));
      await tester.pumpAndSettle();
      expect(find.text('Sin noticias en este filtro'), findsOneWidget);
    });

    testWidgets('filtros funcionan', (tester) async {
      final setup = await createTestNewsSetup();
      await tester.pumpWidget(await newsApp(setup.news));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eventos'));
      await tester.pumpAndSettle();
      expect(find.text('Ãšltima noticia'), findsOneWidget);
      expect(find.text('Pinned reciente'), findsNothing);

      await tester.tap(find.text('Banners'));
      await tester.pumpAndSettle();
      expect(find.text('Banner local'), findsOneWidget);
      expect(find.text('Ãšltima noticia'), findsNothing);
    });
  });
}

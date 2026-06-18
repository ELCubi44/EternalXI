import 'dart:math';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/clash_gacha_panel.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/screens/clash_gacha_history_screen.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

class _FixedRandom implements Random {
  _FixedRandom(this._value);

  final int _value;

  @override
  int nextInt(int max) {
    if (max <= 0) {
      return 0;
    }
    return _value.clamp(0, max - 1);
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

ClashGachaHistoryEntry _sampleEntry({
  required String id,
  required DateTime createdAt,
  required ClashGachaPullType pullType,
  int resultCount = 1,
  ClashRarity rarity = ClashRarity.n,
}) {
  return ClashGachaHistoryEntry(
    id: id,
    bannerId: 'starter-banner-001',
    bannerName: 'Invocación inicial',
    pullType: pullType,
    spentGems: pullType == ClashGachaPullType.multi ? 95 : 10,
    createdAt: createdAt,
    results: List.generate(
      resultCount,
      (index) => ClashGachaHistoryResultItem(
        cardId: 'gacha-card-a',
        cardName: 'Gacha A',
        rarity: rarity,
        isNew: index == 0,
        isDuplicate: index > 0,
        upgradedRarity: false,
        duplicateCopiesAfter: index,
      ),
      growable: false,
    ),
  );
}

Future<Widget> _panelRouterApp(ClashGachaRepository repo) async {
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collection = createTestCollectionRepository(cardsRepository: cardsRepo);
  final cardsController = ClashCardsController(cardsRepo, collection);
  await cardsController.load();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: ClashGachaPanel()),
      ),
      GoRoute(
        path: AppRoutes.clashSummonHistory,
        builder: (context, state) => const ClashGachaHistoryScreen(),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      Provider<ClashGachaRepository>.value(value: repo),
      ChangeNotifierProvider<ClashCardsController>.value(
        value: cardsController,
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

Future<Widget> _historyScreenApp(ClashGachaRepository repo) async {
  return Provider<ClashGachaRepository>.value(
    value: repo,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const ClashGachaHistoryScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashGachaHistoryStorage', () {
    test('pull exitoso se guarda en historial', () async {
      final history = InMemoryClashGachaHistoryBackend();
      final repo = await createTestGachaRepository(
        historyStorage: history,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );

      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );

      final entries = await repo.loadHistory();
      expect(entries, hasLength(1));
      expect(entries.first.bannerId, 'starter-banner-001');
      expect(entries.first.bannerName, 'Invocación inicial');
      expect(entries.first.pullType, ClashGachaPullType.single);
      expect(entries.first.spentGems, 10);
      expect(entries.first.results, hasLength(1));
    });

    test('pull fallido por gemas no se guarda', () async {
      final history = InMemoryClashGachaHistoryBackend();
      final repo = await createTestGachaRepository(
        historyStorage: history,
        initialGems: 0,
      );

      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );

      expect(await repo.loadHistory(), isEmpty);
    });

    test('historial ordenado más reciente primero', () async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        _sampleEntry(
          id: 'old',
          createdAt: DateTime(2026, 1, 1),
          pullType: ClashGachaPullType.single,
        ),
      );
      await history.appendEntry(
        _sampleEntry(
          id: 'new',
          createdAt: DateTime(2026, 6, 1),
          pullType: ClashGachaPullType.multi,
          resultCount: 10,
        ),
      );

      final repo = await createTestGachaRepository(historyStorage: history);
      final entries = await repo.loadHistory();
      expect(entries.first.id, 'new');
      expect(entries.last.id, 'old');
    });

    test('historial se limita a 50', () async {
      final history = InMemoryClashGachaHistoryBackend();
      for (var i = 0; i < 51; i++) {
        await history.appendEntry(
          _sampleEntry(
            id: 'entry-$i',
            createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
            pullType: ClashGachaPullType.single,
          ),
        );
      }

      final entries = history.readEntries();
      expect(entries, hasLength(50));
      expect(entries.first.id, 'entry-50');
    });

    test('entry conserva banner, tipo, gasto y resultados', () async {
      final history = InMemoryClashGachaHistoryBackend();
      final repo = await createTestGachaRepository(
        historyStorage: history,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
        initialGems: 200,
      );

      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );

      final entry = (await repo.loadHistory()).single;
      expect(entry.bannerName, 'Invocación inicial');
      expect(entry.pullType, ClashGachaPullType.multi);
      expect(entry.spentGems, 95);
      expect(entry.results, hasLength(10));
      expect(entry.results.first.cardName, isNotEmpty);
    });

    test('clearHistory funciona en tests', () async {
      final history = InMemoryClashGachaHistoryBackend();
      final repo = await createTestGachaRepository(historyStorage: history);
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(await repo.loadHistory(), isNotEmpty);

      await repo.clearHistory();
      expect(await repo.loadHistory(), isEmpty);
    });
  });

  group('ClashGachaHistory UI', () {
    testWidgets('pantalla Invocar muestra botón Historial', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await _panelRouterApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Historial'), findsOneWidget);
    });

    testWidgets('pulsar Historial navega a historial', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await _panelRouterApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Historial de invocaciones'), findsOneWidget);
    });

    testWidgets('historial vacío muestra estado vacío', (tester) async {
      final repo = await createTestGachaRepository();
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Todavía no has hecho invocaciones'), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });

    testWidgets('historial muestra filtros y total', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        _sampleEntry(
          id: 'single-1',
          createdAt: DateTime(2026, 6, 11, 15, 30),
          pullType: ClashGachaPullType.single,
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 tiradas guardadas'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Ticket'), findsWidgets);
    });

    testWidgets('filtro Ticket funciona', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        _sampleEntry(
          id: 'single-1',
          createdAt: DateTime(2026, 6, 11),
          pullType: ClashGachaPullType.single,
        ),
      );
      await history.appendEntry(
        ClashGachaHistoryEntry(
          id: 'ticket-1',
          bannerId: 'starter-banner-001',
          bannerName: 'Invocación inicial',
          pullType: ClashGachaPullType.ticketSingle,
          spentGems: 0,
          createdAt: DateTime(2026, 6, 12),
          results: const [
            ClashGachaHistoryResultItem(
              cardId: 'a',
              cardName: 'Ticket pull',
              rarity: ClashRarity.n,
              isNew: true,
              isDuplicate: false,
              upgradedRarity: false,
              duplicateCopiesAfter: 0,
            ),
          ],
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Ticket'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('10 gemas'), findsNothing);
    });

    testWidgets('historial con single muestra 1 resultado', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        _sampleEntry(
          id: 'single-1',
          createdAt: DateTime(2026, 6, 11, 15, 30),
          pullType: ClashGachaPullType.single,
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Invocación inicial'), findsOneWidget);
      expect(find.textContaining('1 cartas'), findsOneWidget);
      await tester.tap(find.text('Invocación inicial'));
      await tester.pumpAndSettle();
      expect(find.text('Gacha A'), findsOneWidget);
    });

    testWidgets('historial con multi muestra 10 resultados', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        _sampleEntry(
          id: 'multi-1',
          createdAt: DateTime(2026, 6, 11, 16),
          pullType: ClashGachaPullType.multi,
          resultCount: 10,
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('10 cartas'), findsOneWidget);
      await tester.tap(find.text('Invocación inicial'));
      await tester.pumpAndSettle();
      expect(find.text('Gacha A'), findsNWidgets(10));
    });

    testWidgets('muestra nueva, duplicado y mejora', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        ClashGachaHistoryEntry(
          id: 'mixed',
          bannerId: 'starter-banner-001',
          bannerName: 'Invocación inicial',
          pullType: ClashGachaPullType.multi,
          spentGems: 95,
          createdAt: DateTime(2026, 6, 11),
          results: const [
            ClashGachaHistoryResultItem(
              cardId: 'a',
              cardName: 'Nueva carta',
              rarity: ClashRarity.n,
              isNew: true,
              isDuplicate: false,
              upgradedRarity: false,
              duplicateCopiesAfter: 0,
            ),
            ClashGachaHistoryResultItem(
              cardId: 'b',
              cardName: 'Dup carta',
              rarity: ClashRarity.n,
              isNew: false,
              isDuplicate: true,
              upgradedRarity: false,
              duplicateCopiesAfter: 2,
            ),
            ClashGachaHistoryResultItem(
              cardId: 'c',
              cardName: 'Up carta',
              rarity: ClashRarity.sr,
              isNew: false,
              isDuplicate: false,
              upgradedRarity: true,
              duplicateCopiesAfter: 0,
            ),
          ],
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invocación inicial'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva'), findsOneWidget);
      expect(find.text('Duplicado'), findsOneWidget);
      expect(find.text('Rareza mejorada'), findsOneWidget);
    });

    testWidgets('muestra mejor rareza en resumen', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        _sampleEntry(
          id: 'sr-entry',
          createdAt: DateTime(2026, 6, 11),
          pullType: ClashGachaPullType.multi,
          resultCount: 3,
          rarity: ClashRarity.sr,
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(await _historyScreenApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mejor rareza: SR'), findsOneWidget);
    });

    testWidgets('result sheet permite ir a historial', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      final result = ClashGachaPullResult(
        bannerId: 'starter-banner-001',
        pullType: ClashGachaPullType.single,
        spentGems: 10,
        results: const [
          ClashGachaPullResultItem(
            cardId: 'gacha-card-a',
            cardName: 'Gacha A',
            rarity: ClashRarity.n,
            isNew: true,
            isDuplicate: false,
            upgradedRarity: false,
            duplicateCopiesAfter: 0,
          ),
        ],
        createdAt: DateTime(2026, 6, 11),
        remainingGems: 110,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => ClashGachaResultSheet.show(context, result),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashSummonHistory,
            builder: (context, state) => const ClashGachaHistoryScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        Provider<ClashGachaRepository>.value(
          value: repo,
          child: MaterialApp.router(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver historial'));
      await tester.pumpAndSettle();

      expect(find.text('Historial de invocaciones'), findsOneWidget);
    });
  });
}

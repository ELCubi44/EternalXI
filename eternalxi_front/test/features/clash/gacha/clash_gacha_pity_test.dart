import 'dart:math';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/clash_gacha_panel.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/screens/clash_gacha_history_screen.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashGachaPityState', () {
    test('pity inicial es 0/30', () {
      final state = ClashGachaPityState.initial('starter-banner-001');
      expect(state.pullsSinceLastPity, 0);
      expect(state.threshold, 30);
      expect(state.pullsRemaining, 30);
    });
  });

  group('ClashGachaEngine rollWithPity', () {
    const rates = ClashGachaRarityRates.provisional;

    test('single suma 1', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 1,
        applyMultiGuarantee: false,
        pityState: ClashGachaPityState.initial('b'),
      );
      expect(result.stateAfter.pullsSinceLastPity, 1);
      expect(result.stateAfter.totalPulls, 1);
    });

    test('daily suma 1', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 1,
        applyMultiGuarantee: false,
        pityState: ClashGachaPityState.initial('b'),
      );
      expect(result.stateAfter.pullsSinceLastPity, 1);
    });

    test('multi suma 10', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 10,
        applyMultiGuarantee: true,
        pityState: ClashGachaPityState.initial('b'),
      );
      expect(result.stateAfter.pullsSinceLastPity, 10);
      expect(result.stateAfter.totalPulls, 10);
      expect(result.slots, hasLength(10));
    });

    test('al llegar a 30 fuerza SR', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 1,
        applyMultiGuarantee: false,
        pityState: ClashGachaPityState.initial(
          'b',
        ).copyWith(pullsSinceLastPity: 29),
      );
      expect(result.pityTriggered, isTrue);
      expect(result.slots.single.rarity, ClashRarity.sr);
      expect(result.slots.single.wasPity, isTrue);
    });

    test('pity reinicia a 0 tras activarse', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 1,
        applyMultiGuarantee: false,
        pityState: ClashGachaPityState.initial(
          'b',
        ).copyWith(pullsSinceLastPity: 29),
      );
      expect(result.stateAfter.pullsSinceLastPity, 0);
      expect(result.stateAfter.pityHits, 1);
    });

    test('multi que cruza pity fuerza SR en posición correcta', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 10,
        applyMultiGuarantee: true,
        pityState: ClashGachaPityState.initial(
          'b',
        ).copyWith(pullsSinceLastPity: 28),
      );
      expect(result.forcedIndex, 1);
      expect(result.slots[1].wasPity, isTrue);
      expect(result.slots[1].rarity, ClashRarity.sr);
      expect(result.stateAfter.pullsSinceLastPity, 8);
    });

    test('pulls posteriores en la misma multi se cuentan tras reset', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 10,
        applyMultiGuarantee: true,
        pityState: ClashGachaPityState.initial(
          'b',
        ).copyWith(pullsSinceLastPity: 28),
      );
      // 28 + 10 = 38 total progression; pity at 30 resets; remaining 8 cards counted
      expect(result.stateAfter.pullsSinceLastPity, 8);
    });

    test('SR natural no reinicia pity', () {
      final engine = ClashGachaEngine(random: _FixedRandom(95));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 1,
        applyMultiGuarantee: false,
        pityState: ClashGachaPityState.initial(
          'b',
        ).copyWith(pullsSinceLastPity: 10),
      );
      expect(result.slots.single.rarity, ClashRarity.sr);
      expect(result.slots.single.wasPity, isFalse);
      expect(result.stateAfter.pullsSinceLastPity, 11);
    });

    test('garantía multi no reinicia pity si no fue pity', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 10,
        applyMultiGuarantee: true,
        pityState: ClashGachaPityState.initial('b'),
      );
      expect(result.slots.last.wasMultiGuarantee, isTrue);
      expect(result.slots.last.wasPity, isFalse);
      expect(result.stateAfter.pullsSinceLastPity, 10);
    });

    test('pity SR satisface garantía multi', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final result = engine.rollWithPity(
        rates: rates,
        cardCount: 10,
        applyMultiGuarantee: true,
        pityState: ClashGachaPityState.initial(
          'b',
        ).copyWith(pullsSinceLastPity: 29),
      );
      expect(result.slots.any((slot) => slot.wasPity), isTrue);
      expect(result.slots.any((slot) => slot.wasMultiGuarantee), isFalse);
    });
  });

  group('ClashGachaPityStorage', () {
    test('pity state persiste por banner', () async {
      final storage = InMemoryClashGachaPityBackend();
      await storage.writeState(
        ClashGachaPityState.initial(
          'starter-banner-001',
        ).copyWith(pullsSinceLastPity: 12, totalPulls: 40),
      );
      final read = storage.readState('starter-banner-001');
      expect(read?.pullsSinceLastPity, 12);
      expect(read?.totalPulls, 40);
    });

    test('banners distintos tienen pity separado', () async {
      final storage = InMemoryClashGachaPityBackend();
      await storage.writeState(
        ClashGachaPityState.initial('banner-a').copyWith(pullsSinceLastPity: 5),
      );
      await storage.writeState(
        ClashGachaPityState.initial(
          'banner-b',
        ).copyWith(pullsSinceLastPity: 18),
      );
      expect(storage.readState('banner-a')?.pullsSinceLastPity, 5);
      expect(storage.readState('banner-b')?.pullsSinceLastPity, 18);
    });
  });

  group('ClashGachaRepository pity', () {
    test('resultado marca wasPity', () async {
      final pity = InMemoryClashGachaPityBackend();
      await pity.writeState(
        ClashGachaPityState.initial(
          'starter-banner-001',
        ).copyWith(pullsSinceLastPity: 29),
      );
      final repo = await createTestGachaRepository(
        pityStorage: pity,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
        initialGems: 50,
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(outcome.result!.results.single.wasPity, isTrue);
      expect(outcome.result!.pityTriggered, isTrue);
    });

    test('historial conserva wasPity', () async {
      final pity = InMemoryClashGachaPityBackend();
      await pity.writeState(
        ClashGachaPityState.initial(
          'starter-banner-001',
        ).copyWith(pullsSinceLastPity: 29),
      );
      final repo = await createTestGachaRepository(
        pityStorage: pity,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
        initialGems: 50,
      );
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      final history = await repo.loadHistory();
      expect(history.single.results.single.wasPity, isTrue);
    });

    test('multi guarantee se marca si se aplica', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
        initialGems: 200,
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );
      expect(
        outcome.result!.results.any((item) => item.wasMultiGuarantee),
        isTrue,
      );
    });
  });

  group('ClashGachaPity UI', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 2000);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().window.clearPhysicalSizeTestValue();
      TestWidgetsFlutterBinding.ensureInitialized().window.clearDevicePixelRatioTestValue();
    });

    Future<Widget> panelApp(ClashGachaRepository repo) async {
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
      );
      final controller = ClashCardsController(cardsRepo, collection);
      await controller.load();
      return MultiProvider(
        providers: [
          Provider<ClashGachaRepository>.value(value: repo),
          ChangeNotifierProvider<ClashCardsController>.value(value: controller),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: ClashGachaPanel()),
        ),
      );
    }

    testWidgets('Invocar muestra Pity SR X/30', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pity SR: 0/30'), findsOneWidget);
    });

    testWidgets('tras single se actualiza contador', (tester) async {
      final repo = await createTestGachaRepository(
        initialGems: 50,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Single ×10 gemas'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.textContaining('Pity SR: 1/30'), findsOneWidget);
    });

    testWidgets('contador cercano al pity muestra Faltan X', (tester) async {
      final pity = InMemoryClashGachaPityBackend();
      await pity.writeState(
        ClashGachaPityState.initial(
          'starter-banner-001',
        ).copyWith(pullsSinceLastPity: 27),
      );
      final repo = await createTestGachaRepository(
        pityStorage: pity,
        initialGems: 120,
      );
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Faltan 3 invocaciones'), findsOneWidget);
    });

    testWidgets('resultado muestra chip Pity SR', (tester) async {
      final result = ClashGachaPullResult(
        bannerId: 'starter-banner-001',
        pullType: ClashGachaPullType.single,
        spentGems: 10,
        results: const [
          ClashGachaPullResultItem(
            cardId: 'gacha-card-a',
            cardName: 'Gacha A',
            rarity: ClashRarity.sr,
            isNew: true,
            isDuplicate: false,
            upgradedRarity: false,
            duplicateCopiesAfter: 0,
            wasPity: true,
          ),
        ],
        createdAt: DateTime(2026, 6, 11),
        remainingGems: 90,
        pityTriggered: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ClashGachaResultSheet(result: result)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pity SR'), findsOneWidget);
    });

    testWidgets('historial muestra chip Pity SR', (tester) async {
      final history = InMemoryClashGachaHistoryBackend();
      await history.appendEntry(
        ClashGachaHistoryEntry(
          id: 'pity-entry',
          bannerId: 'starter-banner-001',
          bannerName: 'Invocación inicial',
          pullType: ClashGachaPullType.single,
          spentGems: 10,
          createdAt: DateTime(2026, 6, 11),
          results: const [
            ClashGachaHistoryResultItem(
              cardId: 'a',
              cardName: 'Gacha A',
              rarity: ClashRarity.sr,
              isNew: true,
              isDuplicate: false,
              upgradedRarity: false,
              duplicateCopiesAfter: 0,
              wasPity: true,
            ),
          ],
        ),
      );
      final repo = await createTestGachaRepository(historyStorage: history);
      await tester.pumpWidget(
        Provider<ClashGachaRepository>.value(
          value: repo,
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashGachaHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invocación inicial'));
      await tester.pumpAndSettle();

      expect(find.text('Pity SR'), findsOneWidget);
    });

    testWidgets('multi con garantía muestra chip Garantía multi', (
      tester,
    ) async {
      final result = ClashGachaPullResult(
        bannerId: 'starter-banner-001',
        pullType: ClashGachaPullType.multi,
        spentGems: 95,
        results: [
          const ClashGachaPullResultItem(
            cardId: 'gacha-card-a',
            cardName: 'Gacha A',
            rarity: ClashRarity.n,
            isNew: true,
            isDuplicate: false,
            upgradedRarity: false,
            duplicateCopiesAfter: 0,
          ),
          const ClashGachaPullResultItem(
            cardId: 'gacha-card-a',
            cardName: 'Gacha A',
            rarity: ClashRarity.sr,
            isNew: false,
            isDuplicate: true,
            upgradedRarity: false,
            duplicateCopiesAfter: 1,
            wasMultiGuarantee: true,
          ),
        ],
        createdAt: DateTime(2026, 6, 11),
        remainingGems: 105,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ClashGachaResultSheet(result: result)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Garantía multi'), findsOneWidget);
    });
  });
}

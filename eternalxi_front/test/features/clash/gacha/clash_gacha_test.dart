import 'dart:math';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/clash_gacha_panel.dart';
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

Future<Widget> _gachaTestApp({
  required ClashGachaRepository gachaRepo,
  ClashCardsRepository? cardsRepo,
  ClashPlayerCollectionRepository? collectionRepo,
}) async {
  final cards = cardsRepo ?? ClashCardsRepository(GachaTestCardsDataSource());
  final collection =
      collectionRepo ?? createTestCollectionRepository(cardsRepository: cards);
  final controller = ClashCardsController(cards, collection);
  await controller.load();

  return MultiProvider(
    providers: [
      Provider<ClashGachaRepository>.value(value: gachaRepo),
      ChangeNotifierProvider<ClashCardsController>.value(value: controller),
      Provider<ClashPlayerCollectionRepository>.value(value: collection),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: ClashGachaPanel()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashGachaEngine', () {
    test('multi garantiza SR si los primeros pulls no lo sacan', () {
      final engine = ClashGachaEngine(random: _FixedRandom(0));
      final results = engine.rollMulti(
        rates: ClashGachaRarityRates.provisional,
        count: 10,
      );
      expect(results, hasLength(10));
      expect(results.where((r) => r == ClashRarity.sr), isNotEmpty);
      expect(results.last, ClashRarity.sr);
    });
  });

  group('ClashGachaLocalDataSource', () {
    test('rates cargan desde JSON', () {
      final catalog = ClashGachaLocalDataSource().parseCatalogJson(
        clashTestGachaBannersJson,
      );
      expect(catalog.rates.nPercent, 60);
      expect(catalog.rates.rPercent, 30);
      expect(catalog.rates.srPercent, 10);
      expect(catalog.banners.first.id, 'starter-banner-001');
    });
  });

  group('ClashGachaRepository', () {
    test('single genera 1 resultado', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(outcome.error, isNull);
      expect(outcome.result!.results, hasLength(1));
    });

    test('multi genera 10 resultados', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );
      expect(outcome.error, isNull);
      expect(outcome.result!.results, hasLength(10));
    });

    test('multi garantiza SR', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );
      expect(
        outcome.result!.results.any((item) => item.rarity == ClashRarity.sr),
        isTrue,
      );
    });

    test('no permite invocar sin gemas', () async {
      final repo = await createTestGachaRepository(initialGems: 0);
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(outcome.error, ClashGachaPullError.insufficientGems);
    });

    test('single descuenta 10 gemas', () async {
      final repo = await createTestGachaRepository(initialGems: 50);
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(repo.walletGems(), 40);
    });

    test('multi descuenta 95 gemas', () async {
      final repo = await createTestGachaRepository(initialGems: 200);
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );
      expect(repo.walletGems(), 105);
    });

    test('daily descuenta 1 gema', () async {
      final fixedNow = DateTime(2026, 6, 11, 12);
      final repo = await createTestGachaRepository(
        initialGems: 20,
        now: () => fixedNow,
      );
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.dailySingle,
      );
      expect(repo.walletGems(), 19);
    });

    test('daily queda bloqueado tras usarlo', () async {
      final fixedNow = DateTime(2026, 6, 11, 12);
      final daily = InMemoryClashGachaDailyBackend();
      final repo = await createTestGachaRepository(
        initialGems: 20,
        dailyStorage: daily,
        now: () => fixedNow,
      );
      expect(repo.isDailyAvailable('starter-banner-001'), isTrue);
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.dailySingle,
      );
      expect(repo.isDailyAvailable('starter-banner-001'), isFalse);
      final second = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.dailySingle,
      );
      expect(second.error, ClashGachaPullError.dailyAlreadyUsed);
    });
  });

  group('grantGachaCard', () {
    late ClashCardsRepository cardsRepo;
    late ClashPlayerCollectionRepository collectionRepo;

    setUp(() {
      cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
      );
    });

    test('carta nueva se añade a colección', () async {
      final grant = await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.n,
      );
      expect(grant.isNew, isTrue);
      expect(collectionRepo.loadOwnedCardIds(), contains('gacha-card-a'));
    });

    test('carta repetida suma duplicado', () async {
      await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.n,
      );
      final grant = await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.n,
      );
      expect(grant.isDuplicate, isTrue);
      expect(grant.duplicateCopiesAfter, 1);
    });

    test('rareza superior mejora effectiveRarity', () async {
      await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.n,
      );
      final grant = await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.sr,
      );
      expect(grant.upgradedRarity, isTrue);
      final progress = collectionRepo.progressFor('gacha-card-a');
      final card = (await cardsRepo.findById('gacha-card-a'))!.card;
      expect(
        ClashCardEvolutionResolver.effectiveRarity(card, progress!),
        ClashRarity.sr,
      );
    });

    test('rareza igual o inferior suma duplicado', () async {
      await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.sr,
      );
      final grant = await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.r,
      );
      expect(grant.isDuplicate, isTrue);
      expect(grant.upgradedRarity, isFalse);
    });

    test('resultado indica new, duplicate y upgraded', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
        initialGems: 200,
      );
      final first = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(first.result!.results.first.isNew, isTrue);

      final second = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(second.result!.results.first.isDuplicate, isTrue);
    });
  });

  group('ClashGachaPanel UI', () {
    testWidgets('muestra saldo, banner y probabilidades', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await _gachaTestApp(gachaRepo: repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gemas: 120'), findsOneWidget);
      expect(find.text('Invocación inicial'), findsOneWidget);
      expect(find.textContaining('60 %'), findsOneWidget);
      expect(
        find.textContaining('Simulación local sin compras reales'),
        findsOneWidget,
      );
    });

    testWidgets('botones single y multi muestran coste', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await _gachaTestApp(gachaRepo: repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Single ×10 gemas'), findsOneWidget);
      expect(
        find.textContaining('Multi ×95 gemas (10 cartas)'),
        findsOneWidget,
      );
    });

    testWidgets('gemas insuficientes muestra SnackBar', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 0);
      await tester.pumpWidget(await _gachaTestApp(gachaRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Single ×10 gemas'));
      await tester.pumpAndSettle();

      expect(find.text('Consigue gemas en Historia'), findsOneWidget);
    });

    testWidgets('pull exitoso muestra resultados y actualiza saldo', (
      tester,
    ) async {
      final repo = await createTestGachaRepository(
        initialGems: 50,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await tester.pumpWidget(await _gachaTestApp(gachaRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Single ×10 gemas'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Resultado de invocación (1)'), findsOneWidget);
      expect(find.textContaining('Gemas: 40'), findsOneWidget);
    });

    testWidgets('duplicado aparece como duplicado', (tester) async {
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
      );
      await collectionRepo.grantGachaCard(
        cardId: 'gacha-card-a',
        rarity: ClashRarity.n,
      );
      final repo = await createTestGachaRepository(
        initialGems: 50,
        cardsRepository: cardsRepo,
        collectionRepository: collectionRepo,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await tester.pumpWidget(
        await _gachaTestApp(
          gachaRepo: repo,
          cardsRepo: cardsRepo,
          collectionRepo: collectionRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Single ×10 gemas'));
      await tester.pumpAndSettle();

      expect(find.text('Duplicado'), findsOneWidget);
    });

    testWidgets('multi muestra 10 resultados', (tester) async {
      final repo = await createTestGachaRepository(
        initialGems: 200,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await tester.pumpWidget(await _gachaTestApp(gachaRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Multi ×95 gemas'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Resultado de invocación (10)'), findsOneWidget);
      expect(find.textContaining('Gastadas: 95'), findsOneWidget);
    });
  });
}

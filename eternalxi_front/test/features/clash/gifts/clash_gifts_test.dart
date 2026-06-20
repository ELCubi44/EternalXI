import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_local_datasource.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_claim_result.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_status.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashGiftsLocalDataSource', () {
    test('carga gifts.json', () {
      final gifts = ClashGiftsLocalDataSource().parseGiftsJson(
        clashTestGiftsJson,
      );
      expect(gifts, hasLength(5));
      expect(gifts.first.id, 'gift-welcome-clash');
    });
  });

  group('ClashGiftsRepository', () {
    test('regalos iniciales disponibles', () async {
      final setup = await createTestGiftsSetup();
      final entries = await setup.gifts.fetchGiftEntries();
      final available = entries.where((entry) => entry.canClaim).toList();
      expect(available, hasLength(4));
      expect(available.every((entry) => !entry.canClaim == false), isTrue);
    });

    test('claim concede gems y coins', () async {
      final setup = await createTestGiftsSetup();
      await setup.gifts.claimGift('gift-welcome-clash');
      expect(setup.story.walletGems(), 5);
      expect(setup.story.walletCoins(), 1000);
    });

    test('claim concede ticket', () async {
      final setup = await createTestGiftsSetup();
      final before = setup.tickets.quantityFor('starter-single-ticket');
      await setup.gifts.claimGift('gift-welcome-clash');
      expect(setup.tickets.quantityFor('starter-single-ticket'), before + 1);
    });

    test('claim concede material EXP', () async {
      final setup = await createTestGiftsSetup();
      final before = setup.expMaterials.quantityFor('basic-training-manual');
      await setup.gifts.claimGift('gift-training-kit');
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        before + 3,
      );
    });

    test('claim concede libro técnica', () async {
      final setup = await createTestGiftsSetup();
      final before = setup.techniqueBooks.quantityFor('basic-technique-book');
      await setup.gifts.claimGift('gift-training-kit');
      expect(
        setup.techniqueBooks.quantityFor('basic-technique-book'),
        before + 1,
      );
    });

    test('claim concede insignia', () async {
      final setup = await createTestGiftsSetup();
      final before = setup.evolutionMaterials.quantityFor('insignia-r');
      await setup.gifts.claimGift('gift-evo-trial');
      expect(setup.evolutionMaterials.quantityFor('insignia-r'), before + 1);
    });

    test('claim marca como reclamado', () async {
      final setup = await createTestGiftsSetup();
      await setup.gifts.claimGift('gift-thanks-beta');
      final entry = (await setup.gifts.fetchGiftEntries()).firstWhere(
        (item) => item.gift.id == 'gift-thanks-beta',
      );
      expect(entry.status, ClashGiftStatus.claimed);
      expect(entry.canClaim, isFalse);
    });

    test('no permite claim doble', () async {
      final setup = await createTestGiftsSetup();
      await setup.gifts.claimGift('gift-thanks-beta');
      final second = await setup.gifts.claimGift('gift-thanks-beta');
      expect(second.success, isFalse);
      expect(second.error, ClashGiftClaimError.alreadyClaimed);
    });

    test('claim all reclama varios', () async {
      final setup = await createTestGiftsSetup(initialCoins: 0);
      final results = await setup.gifts.claimAllPending();
      expect(results.where((item) => item.success).length, 4);
      expect(setup.story.walletCoins(), 3000);
    });

    test('storage persiste claimedGiftIds', () async {
      final storage = InMemoryClashGiftsBackend();
      final setup = await createTestGiftsSetup(storage: storage);
      await setup.gifts.claimGift('gift-thanks-beta');
      final stored = storage.readState();
      expect(stored?.claimedGiftIds.contains('gift-thanks-beta'), isTrue);
    });

    test('regalos reclamados no aparecen como pendientes', () async {
      final setup = await createTestGiftsSetup();
      await setup.gifts.claimGift('gift-welcome-clash');
      final summary = await setup.gifts.fetchSummary();
      expect(summary.pendingCount, 3);
      expect(summary.claimedCount, 1);
    });

    test('pending count correcto', () async {
      final setup = await createTestGiftsSetup();
      final summary = await setup.gifts.fetchSummary();
      expect(summary.pendingCount, 4);
      expect(summary.latestPendingTitle, 'Bienvenida a Clash');
    });
  });

  group('ClashGifts UI', () {
    Future<Widget> giftsApp(ClashGiftsRepository repo) async {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Provider<ClashGiftsRepository>.value(
          value: repo,
          child: const ClashGiftsScreen(),
        ),
      );
    }

    Future<Widget> homeApp(ClashGiftsRepository repo) async {
      final setup = await createTestGiftsSetup();
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>(
              create: (_) => ClashStoryController(storyRepository: setup.story),
            ),
            Provider<ClashGiftsRepository>.value(value: repo),
          ],
          child: const ClashHomeScreen(),
        ),
      );
    }

    testWidgets('Home muestra tarjeta Regalos', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(await homeApp(setup.gifts));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Regalos'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Regalos'), findsOneWidget);
    });

    testWidgets('tarjeta muestra pendientes', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(await homeApp(setup.gifts));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('4 pendientes'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('4 pendientes'), findsOneWidget);
    });

    testWidgets('pulsar Ver navega a /clash/gifts', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
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
                Provider<ClashGiftsRepository>.value(value: setup.gifts),
              ],
              child: const ClashHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashGifts,
            builder: (context, state) => Provider<ClashGiftsRepository>.value(
              value: setup.gifts,
              child: const ClashGiftsScreen(),
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
        find.textContaining('4 pendientes'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      final giftsCard = find.ancestor(
        of: find.textContaining('4 pendientes'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(of: giftsCard, matching: find.text('Ver')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reclamar todos'), findsOneWidget);
    });

    testWidgets('pantalla muestra regalos', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenida a Clash'), findsOneWidget);
      expect(find.text('Kit de entrenamiento inicial'), findsOneWidget);
    });

    testWidgets('botón Reclamar visible en disponible', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Reclamar'), findsWidgets);
    });

    testWidgets('reclamar cambia estado a Reclamado', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup(initialCoins: 0);
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Gracias por probar el modo Clash'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reclamar').first);
      await tester.pumpAndSettle();
      expect(find.text('Reclamado'), findsWidgets);
    });

    testWidgets('reclamar todos funciona', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup(initialCoins: 0);
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reclamar todos'));
      await tester.pumpAndSettle();
      expect(find.text('Recompensas recibidas'), findsOneWidget);
      expect(find.text('Reclamado'), findsWidgets);
    });

    testWidgets('sin pendientes muestra texto correcto', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      await setup.gifts.claimAllPending();
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      expect(find.text('Pendientes 0'), findsOneWidget);
      expect(find.text('Reclamado'), findsWidgets);
    });

    testWidgets('cabecera muestra pendientes y reclamados', (tester) async {
      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pendientes'), findsOneWidget);
      expect(find.textContaining('Reclamados'), findsOneWidget);
    });

    testWidgets('regalo disponible destaca', (tester) async {
      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      expect(find.text('Disponible'), findsWidgets);
      expect(find.text('Recompensa'), findsWidgets);
    });

    testWidgets('wallet se actualiza tras claim', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup(initialCoins: 0, initialGems: 0);
      await tester.pumpWidget(await giftsApp(setup.gifts));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reclamar todos'));
      await tester.pumpAndSettle();
      expect(setup.story.walletCoins(), 3000);
      expect(setup.story.walletGems(), 5);
    });
  });
}

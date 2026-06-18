import 'dart:math';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_tickets_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket_reward_adapter.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/clash_gacha_panel.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/screens/clash_gacha_history_screen.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_result_sheet.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/screens/clash_inventory_screen.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
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

  group('ClashGachaTicketsLocalDataSource', () {
    test('carga tickets desde JSON', () {
      final tickets = ClashGachaTicketsLocalDataSource().parseTicketsJson(
        clashTestGachaTicketsJson,
      );
      expect(tickets, hasLength(2));
      expect(tickets.first.id, 'starter-single-ticket');
      expect(tickets.first.compatibleBannerIds, ['starter-banner-001']);
    });
  });

  group('ClashGachaTicketRepository', () {
    test('inventario inicial tiene 3 tickets', () {
      final repo = createTestTicketRepository();
      expect(repo.quantityFor('starter-single-ticket'), 3);
    });

    test('ticket compatible aparece para starter-banner-001', () async {
      final repo = createTestTicketRepository();
      final compatible = await repo.compatibleTicketsForBanner(
        'starter-banner-001',
      );
      expect(compatible, hasLength(1));
      expect(compatible.single.ticket.id, 'starter-single-ticket');
      expect(compatible.single.quantity, 3);
    });

    test('ticket incompatible no aparece', () async {
      final repo = createTestTicketRepository();
      final compatible = await repo.compatibleTicketsForBanner(
        'starter-banner-001',
      );
      expect(
        compatible.any((entry) => entry.ticket.id == 'other-banner-ticket'),
        isFalse,
      );
    });

    test('usar ticket consume 1', () async {
      final repo = createTestTicketRepository();
      expect(await repo.consume('starter-single-ticket'), isTrue);
      expect(repo.quantityFor('starter-single-ticket'), 2);
    });

    test('ticket reward adapter suma tickets al inventario', () async {
      final repo = createTestTicketRepository(
        inventoryStorage: InMemoryClashGachaTicketInventoryBackend(
          initial: {'starter-single-ticket': 1},
        ),
      );
      final grants = ClashGachaTicketRewardAdapter.quantitiesFromStoryReward(
        const ClashStoryReward(
          items: [
            ClashStoryItemReward(
              id: 'starter-single-ticket',
              name: 'Ticket',
              quantity: 2,
            ),
          ],
        ),
      );
      await repo.grantTickets(grants);
      expect(repo.quantityFor('starter-single-ticket'), 3);
    });
  });

  group('ClashGachaRepository tickets', () {
    test('usar ticket no consume gemas', () async {
      final repo = await createTestGachaRepository(
        initialGems: 50,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      final gemsBefore = repo.walletGems();
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
      expect(outcome.error, isNull);
      expect(outcome.result!.spentGems, 0);
      expect(repo.walletGems(), gemsBefore);
    });

    test('usar ticket genera 1 resultado', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
      expect(outcome.result!.results, hasLength(1));
    });

    test('usar ticket guarda historial', () async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
      final history = await repo.loadHistory();
      expect(history.single.pullType, ClashGachaPullType.ticketSingle);
      expect(history.single.spentGems, 0);
    });

    test('usar ticket cuenta para pity', () async {
      final pity = InMemoryClashGachaPityBackend();
      await pity.writeState(
        ClashGachaPityState.initial(
          'starter-banner-001',
        ).copyWith(pullsSinceLastPity: 10),
      );
      final repo = await createTestGachaRepository(
        pityStorage: pity,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
      expect(repo.loadPityState('starter-banner-001').pullsSinceLastPity, 11);
    });

    test('ticket puede activar pity', () async {
      final pity = InMemoryClashGachaPityBackend();
      await pity.writeState(
        ClashGachaPityState.initial(
          'starter-banner-001',
        ).copyWith(pullsSinceLastPity: 29),
      );
      final repo = await createTestGachaRepository(
        pityStorage: pity,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
      expect(outcome.result!.pityTriggered, isTrue);
      expect(outcome.result!.results.single.wasPity, isTrue);
    });

    test('sin tickets no permite pull', () async {
      final tickets = createTestTicketRepository(
        inventoryStorage: InMemoryClashGachaTicketInventoryBackend(
          initial: const {},
        ),
      );
      final repo = await createTestGachaRepository(ticketRepository: tickets);
      final outcome = await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
      expect(outcome.error, ClashGachaPullError.noTickets);
    });
  });

  group('ClashInventory tickets', () {
    test('inventario central incluye categoría Tickets', () async {
      final items = await createTestInventoryRepository().fetchAllItems();
      final tickets = items.where(
        (item) => item.category == ClashInventoryCategory.tickets,
      );
      expect(tickets, hasLength(1));
      expect(tickets.single.name, contains('Ticket'));
      expect(tickets.single.usageHint, ClashInventoryUsageHint.useInSummon);
    });

    test('filtro Tickets solo muestra tickets', () async {
      final items = await createTestInventoryRepository().fetchAllItems();
      final filtered = ClashInventoryRepository.filterItems(
        items,
        ClashInventoryFilter.tickets,
      );
      expect(filtered, isNotEmpty);
      expect(
        filtered.every(
          (item) => item.category == ClashInventoryCategory.tickets,
        ),
        isTrue,
      );
    });
  });

  group('ClashGachaTicket UI', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 2400);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
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

    testWidgets('Invocar muestra botón Usar ticket', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('Usar ticket'), findsOneWidget);
    });

    testWidgets('muestra cantidad disponible', (tester) async {
      final repo = await createTestGachaRepository(initialGems: 120);
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('Usar ticket (×3)'), findsOneWidget);
    });

    testWidgets('botón deshabilitado con 0 tickets', (tester) async {
      final tickets = createTestTicketRepository(
        inventoryStorage: InMemoryClashGachaTicketInventoryBackend(
          initial: const {'starter-single-ticket': 0},
        ),
      );
      final repo = await createTestGachaRepository(
        ticketRepository: tickets,
        initialGems: 120,
      );
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Usar ticket (×0)'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('usar ticket muestra resultado', (tester) async {
      final repo = await createTestGachaRepository(
        initialGems: 50,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar ticket (×3)'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Resultado de invocación (1)'),
        findsOneWidget,
      );
    });

    testWidgets('saldo de gemas no cambia', (tester) async {
      final repo = await createTestGachaRepository(
        initialGems: 50,
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await tester.pumpWidget(await panelApp(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar ticket (×3)'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ticket · Restantes gemas: 50'),
        findsOneWidget,
      );
    });

    testWidgets('historial muestra tipo Ticket', (tester) async {
      final repo = await createTestGachaRepository(
        engine: ClashGachaEngine(random: _FixedRandom(0)),
      );
      await repo.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.ticketSingle,
        ticketId: 'starter-single-ticket',
      );
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
      expect(find.text('Ticket'), findsWidgets);
    });

    testWidgets('resultado muestra Ticket', (tester) async {
      final result = ClashGachaPullResult(
        bannerId: 'starter-banner-001',
        pullType: ClashGachaPullType.ticketSingle,
        spentGems: 0,
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
        remainingGems: 50,
        ticketId: 'starter-single-ticket',
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
      expect(
        find.textContaining('Ticket · Restantes gemas: 50'),
        findsOneWidget,
      );
    });

    testWidgets('Inventario muestra categoría Tickets y ticket inicial', (
      tester,
    ) async {
      await tester.pumpWidget(
        Provider<ClashInventoryRepository>.value(
          value: createTestInventoryRepository(),
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashInventoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tickets'), findsWidgets);
      expect(
        find.textContaining('Ticket de invocación inicial'),
        findsOneWidget,
      );
      expect(find.text('Usar en Invocar'), findsOneWidget);
    });
  });
}

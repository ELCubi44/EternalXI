import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_local_datasource.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_error.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

class _FailingRewardGranter extends ClashLocalRewardGranter {
  _FailingRewardGranter({
    required super.collectionRepository,
    super.ticketRepository,
  });

  @override
  Future<ClashRewardGrantResult> grantAll(
    List<ClashReward> rewards, {
    bool grantWallet = true,
  }) async {
    return ClashRewardGrantResult.allFailed(rewards);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashShopLocalDataSource', () {
    test('carga productos desde JSON', () {
      final products = ClashShopLocalDataSource().parseProductsJson(
        clashTestShopProductsJson,
      );
      expect(products, hasLength(4));
      expect(products.first.id, 'shop-basic-training-pack');
      expect(products.first.costCoins, 300);
    });
  });

  group('ClashShopRepository', () {
    test('wallet muestra monedas', () async {
      final repo = await createTestShopRepository(initialCoins: 1500);
      expect(repo.walletCoins(), 1500);
    });

    test('compra con monedas suficientes descuenta monedas', () async {
      final repo = await createTestShopRepository(initialCoins: 1500);
      final result = await repo.purchase('shop-basic-training-pack');
      expect(result.success, isTrue);
      expect(result.spentCoins, 300);
      expect(repo.walletCoins(), 1200);
    });

    test('compra sin monedas falla', () async {
      final repo = await createTestShopRepository(initialCoins: 100);
      final result = await repo.purchase('shop-basic-training-pack');
      expect(result.success, isFalse);
      expect(result.error, ClashShopPurchaseError.insufficientCoins);
      expect(repo.walletCoins(), 100);
    });

    test('compra EXP material aumenta inventario EXP', () async {
      final expRepo = createTestExpMaterialsRepository();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
      );
      final repo = await createTestShopRepository(
        collectionRepository: collection,
        initialCoins: 1500,
      );
      final before = expRepo.quantityFor('basic-training-manual');
      await repo.purchase('shop-basic-training-pack');
      expect(expRepo.quantityFor('basic-training-manual'), before + 2);
    });

    test('compra libro técnico aumenta inventario libros', () async {
      final booksRepo = createTestTechniqueBooksRepository();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        techniqueBooksRepository: booksRepo,
      );
      final repo = await createTestShopRepository(
        collectionRepository: collection,
        initialCoins: 1500,
      );
      final before = booksRepo.quantityFor('basic-technique-book');
      await repo.purchase('shop-basic-technique-book');
      expect(booksRepo.quantityFor('basic-technique-book'), before + 1);
    });

    test('compra insignia aumenta inventario evolución', () async {
      final evolutionRepo = createTestEvolutionMaterialsRepository();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        evolutionMaterialsRepository: evolutionRepo,
      );
      final repo = await createTestShopRepository(
        collectionRepository: collection,
        initialCoins: 1500,
      );
      final before = evolutionRepo.quantityFor('insignia-r');
      await repo.purchase('shop-insignia-r');
      expect(evolutionRepo.quantityFor('insignia-r'), before + 1);
    });

    test('compra ticket aumenta inventario tickets', () async {
      final tickets = createTestTicketRepository();
      final repo = await createTestShopRepository(
        ticketRepository: tickets,
        initialCoins: 2000,
      );
      final before = tickets.quantityFor('starter-single-ticket');
      await repo.purchase('shop-starter-ticket');
      expect(tickets.quantityFor('starter-single-ticket'), before + 1);
    });

    test('compra no resta monedas si falla grant', () async {
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
      );
      final tickets = createTestTicketRepository();
      final repo = await createTestShopRepository(
        collectionRepository: collection,
        ticketRepository: tickets,
        rewardGranter: _FailingRewardGranter(
          collectionRepository: collection,
          ticketRepository: tickets,
        ),
        initialCoins: 1500,
      );
      final result = await repo.purchase('shop-basic-training-pack');
      expect(result.success, isFalse);
      expect(result.error, ClashShopPurchaseError.grantFailed);
      expect(repo.walletCoins(), 1500);
    });

    test('resultado devuelve saldo nuevo', () async {
      final repo = await createTestShopRepository(initialCoins: 1500);
      final result = await repo.purchase('shop-basic-training-pack');
      expect(result.newCoinBalance, 1200);
    });

    test('producto inexistente falla', () async {
      final repo = await createTestShopRepository(initialCoins: 1500);
      final result = await repo.purchase('missing-product');
      expect(result.success, isFalse);
      expect(result.error, ClashShopPurchaseError.productNotFound);
    });

    test('inventario central refleja compra', () async {
      final expRepo = createTestExpMaterialsRepository();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
      );
      final tickets = createTestTicketRepository();
      final shopRepo = await createTestShopRepository(
        collectionRepository: collection,
        ticketRepository: tickets,
        initialCoins: 2000,
      );
      final inventoryRepo = createTestInventoryRepository(
        expMaterialsRepository: expRepo,
        ticketRepository: tickets,
      );
      final before = (await inventoryRepo.fetchAllItems()).firstWhere(
        (item) => item.id == 'basic-training-manual',
      );
      await shopRepo.purchase('shop-basic-training-pack');
      final after = (await inventoryRepo.fetchAllItems()).firstWhere(
        (item) => item.id == 'basic-training-manual',
      );
      expect(after.quantity, before.quantity + 2);
    });
  });

  group('ClashShop UI', () {
    void configureViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('por ahora solo muestra el título Tienda', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: ClashShopScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
    });
  });
}

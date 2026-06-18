import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_level_scaling.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_reward_adapter.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_collection_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'clash_test_support.dart';

const _card = ClashCard(
  id: 'exp-material-card',
  playerId: 1,
  rarity: ClashRarity.n,
  level: 1,
  style: ClashPlayerStyle.valiente,
  position: ClashPosition.striker,
  stats: ClashStats(
    save: 10,
    defense: 10,
    pass: 10,
    dribble: 10,
    shot: 10,
    techniquePoints: 10,
    stamina: 100,
  ),
  superTechniques: [],
  basicPortraitPath: 'placeholder',
);

const _entry = ClashCardCatalogEntry(
  card: _card,
  name: 'Tester',
  team: 'Eternal XI',
);

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [_entry];
}

Future<
  ({
    ClashPlayerCollectionRepository collection,
    ClashExpMaterialsRepository materials,
    ClashCardsController controller,
  })
>
_setupRepos({
  InMemoryClashPlayerCollectionBackend? collectionStorage,
  InMemoryClashExpMaterialInventoryBackend? inventoryStorage,
}) async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
  final materialsRepo = createTestExpMaterialsRepository(
    inventoryStorage: inventoryStorage,
  );
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    storage: collectionStorage ?? InMemoryClashPlayerCollectionBackend(),
    expMaterialsRepository: materialsRepo,
  );
  await collectionRepo.grantMissingCardIds([_card.id]);
  final controller = ClashCardsController(cardsRepo, collectionRepo);
  await controller.load();
  return (
    collection: collectionRepo,
    materials: materialsRepo,
    controller: controller,
  );
}

Future<Widget> _detailApp({
  required ClashPlayerCollectionRepository collection,
  required ClashExpMaterialsRepository materials,
  required ClashCardsController controller,
}) {
  return Future.value(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ClashCardsController>.value(value: controller),
        Provider<ClashPlayerCollectionRepository>.value(value: collection),
        Provider<ClashExpMaterialsRepository>.value(value: materials),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: ClashCardDetailScreen(cardId: 'exp-material-card'),
        ),
      ),
    ),
  );
}

void main() {
  group('ClashExpMaterial JSON', () {
    test('parsea materiales desde JSON', () {
      final parsed = TestExpMaterialsDataSource().parseMaterialsJson(
        clashTestExpMaterialsJson,
      );
      expect(parsed, hasLength(3));
      expect(parsed.first.id, 'basic-training-manual');
      expect(parsed.first.xpAmount, 50);
    });
  });

  group('ClashExpMaterialsRepository inventario', () {
    test('inventario inicial tiene 5/2/1', () {
      final repo = createTestExpMaterialsRepository();
      final quantities = repo.loadInventoryQuantities();
      expect(quantities['basic-training-manual'], 5);
      expect(quantities['advanced-training-manual'], 2);
      expect(quantities['master-training-manual'], 1);
    });

    test('inventario baja al usar', () async {
      final inventory = InMemoryClashExpMaterialInventoryBackend();
      final materialsRepo = createTestExpMaterialsRepository(
        inventoryStorage: inventory,
      );
      final consumed = await materialsRepo.consumeMaterial(
        materialId: 'basic-training-manual',
        quantity: 2,
      );
      expect(consumed, isTrue);
      expect(materialsRepo.quantityFor('basic-training-manual'), 3);
    });
  });

  group('ClashExpMaterialRewardAdapter', () {
    test('mapea basic-book a manual básico', () {
      final quantities =
          ClashExpMaterialRewardAdapter.quantitiesFromStoryReward(
            const ClashStoryReward(
              items: [
                ClashStoryItemReward(
                  id: 'basic-book',
                  name: 'Libro básico',
                  quantity: 1,
                ),
              ],
            ),
          );
      expect(quantities['basic-training-manual'], 1);
    });
  });

  group('useExpMaterialOnCard', () {
    test('usar material suma EXP', () async {
      final setup = await _setupRepos();
      final result = await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
      );
      expect(result.succeeded, isTrue);
      expect(result.xpGained, 50);
      expect(result.newLevel, 2);
      expect(setup.collection.progressFor(_card.id)!.currentExperience, 0);
    });

    test('usar material puede subir nivel', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: ClashCardProgress(
              cardId: _card.id,
              currentLevel: 1,
              currentExperience: 40,
              unlockedDuplicateNodes: 0,
              techniqueLevels: const {},
            ),
          },
        ),
      );
      final setup = await _setupRepos(collectionStorage: storage);

      final result = await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
      );
      expect(result.didLevelUp, isTrue);
      expect(result.newLevel, 2);
    });

    test('usar varios materiales puede subir varios niveles', () async {
      final inventory = InMemoryClashExpMaterialInventoryBackend();
      final setup = await _setupRepos(inventoryStorage: inventory);
      await setup.materials.grantMaterials({'master-training-manual': 2});

      final result = await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'master-training-manual',
        quantity: 2,
      );

      expect(result.succeeded, isTrue);
      expect(result.xpGained, 1600);
      expect(result.levelsGained, greaterThan(1));
    });

    test('no supera nivel máximo', () async {
      final setup = await _setupRepos();
      await setup.collection.grantMatchXp(
        cardIds: [_card.id],
        xpPerCard: 50000,
      );

      final result = await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
      );

      expect(result.error, ClashExpMaterialUseError.cardAtMaxLevel);
      expect(result.xpGained, 0);
    });

    test('no gasta material si carta está al máximo', () async {
      final inventory = InMemoryClashExpMaterialInventoryBackend();
      final setup = await _setupRepos(inventoryStorage: inventory);
      await setup.collection.grantMatchXp(
        cardIds: [_card.id],
        xpPerCard: 50000,
      );
      final before = setup.materials.quantityFor('basic-training-manual');

      await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
      );

      expect(setup.materials.quantityFor('basic-training-manual'), before);
    });

    test('no gasta material si cantidad 0', () async {
      final inventory = InMemoryClashExpMaterialInventoryBackend();
      final setup = await _setupRepos(inventoryStorage: inventory);
      await setup.materials.consumeMaterial(
        materialId: 'basic-training-manual',
        quantity: 5,
      );

      final result = await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
      );

      expect(result.error, ClashExpMaterialUseError.insufficientQuantity);
      expect(result.quantityUsed, 0);
    });

    test('no permite usar más cantidad de la disponible', () async {
      final setup = await _setupRepos();
      final result = await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
        quantity: 99,
      );
      expect(result.error, ClashExpMaterialUseError.insufficientQuantity);
      expect(setup.materials.quantityFor('basic-training-manual'), 5);
    });

    test('progreso persiste tras usar', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final setup = await _setupRepos(collectionStorage: storage);

      await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'basic-training-manual',
      );
      setup.collection.clearCacheForTests();

      final progress = setup.collection.progressFor(_card.id);
      expect(progress, isNotNull);
      expect(progress!.currentLevel, 2);
      expect(progress.currentExperience, 0);
    });

    test('colección devuelve nivel actualizado', () async {
      final setup = await _setupRepos();
      await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'advanced-training-manual',
        quantity: 2,
      );
      final owned = await setup.collection.fetchOwnedCards();
      expect(owned.first.displayLevel, greaterThan(1));
    });

    test('potencia cambia si hay escalado por nivel', () async {
      final setup = await _setupRepos();
      final beforeLevel = setup.collection.enrichEntry(_entry).displayLevel;
      await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'master-training-manual',
      );
      final afterLevel = setup.collection.enrichEntry(_entry).displayLevel;
      expect(afterLevel, greaterThan(beforeLevel));
    });
  });

  group('UI materiales EXP', () {
    testWidgets('detalle muestra sección Mejorar', (tester) async {
      final setup = await _setupRepos();
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          materials: setup.materials,
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mejorar'), findsOneWidget);
      expect(find.text('Manual básico de entrenamiento'), findsOneWidget);
    });

    testWidgets('muestra materiales y cantidades', (tester) async {
      final setup = await _setupRepos();
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          materials: setup.materials,
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cantidad: 5'), findsOneWidget);
      expect(find.text('Cantidad: 2'), findsOneWidget);
      expect(find.text('Cantidad: 1'), findsOneWidget);
    });

    testWidgets('botón Usar deshabilitado con cantidad 0', (tester) async {
      final inventory = InMemoryClashExpMaterialInventoryBackend();
      final setup = await _setupRepos(inventoryStorage: inventory);
      await setup.materials.consumeMaterial(
        materialId: 'basic-training-manual',
        quantity: 5,
      );

      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          materials: setup.materials,
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      final useButtons = find.widgetWithText(FilledButton, 'Usar 1');
      expect(
        tester.widget<FilledButton>(useButtons.first).onPressed,
        isNull,
      );
    });

    testWidgets('usar material actualiza EXP/nivel', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final setup = await _setupRepos();
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          materials: setup.materials,
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Usar 1').first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Usar 1').first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Cantidad: 4'), findsOneWidget);
      expect(setup.collection.progressFor(_card.id)!.currentLevel, 2);
    });

    testWidgets('muestra mensaje de subida de nivel', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: ClashCardProgress(
              cardId: _card.id,
              currentLevel: 1,
              currentExperience: 40,
              unlockedDuplicateNodes: 0,
              techniqueLevels: const {},
            ),
          },
        ),
      );
      final refreshed = await _setupRepos(collectionStorage: storage);

      await tester.pumpWidget(
        await _detailApp(
          collection: refreshed.collection,
          materials: refreshed.materials,
          controller: refreshed.controller,
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Usar 1').first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Usar 1').first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final message = (snackBar.content as Text).data ?? '';
      expect(message, contains('Sube de nivel'));
      expect(message, contains('+50 EXP'));
    });

    testWidgets('nivel máximo deshabilita mejorar', (tester) async {
      final setup = await _setupRepos();
      await setup.collection.grantMatchXp(
        cardIds: [_card.id],
        xpPerCard: 50000,
      );

      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          materials: setup.materials,
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Nivel máximo alcanzado. No se pueden usar materiales.'),
        findsOneWidget,
      );
      final useButtons = find.text('Usar 1');
      for (var i = 0; i < useButtons.evaluate().length; i++) {
        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: useButtons.at(i),
            matching: find.byType(FilledButton),
          ),
        );
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('colección refleja nivel actualizado tras volver', (
      tester,
    ) async {
      final setup = await _setupRepos();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashCardsController>.value(
              value: setup.controller,
            ),
            Provider<ClashPlayerCollectionRepository>.value(
              value: setup.collection,
            ),
            Provider<ClashExpMaterialsRepository>.value(value: setup.materials),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashCardCollectionScreen()),
            routes: {
              '/detail': (_) => const Scaffold(
                body: ClashCardDetailScreen(cardId: 'exp-material-card'),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await setup.collection.useExpMaterialOnCard(
        cardId: _card.id,
        materialId: 'advanced-training-manual',
      );
      await setup.controller.reloadOwnedCards();
      await tester.pumpAndSettle();

      final levelLabel = setup.controller.visibleCards.first.displayLevel;
      expect(levelLabel, greaterThan(1));
    });
  });
}

extension on ClashExpMaterialUseResult {
  int get levelsGained => newLevel - previousLevel;
}

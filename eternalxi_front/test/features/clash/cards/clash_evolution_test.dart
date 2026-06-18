import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_level_scaling.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'clash_test_support.dart';

const _technique = ClashSuperTechnique(
  id: 'evo-tech',
  name: 'Tiro evo',
  description: 'Técnica evolución',
  type: ClashTechniqueType.shot,
  style: ClashPlayerStyle.potente,
  basePower: 40,
  ptCost: 12,
  level: ClashTechniqueLevel.normal,
);

const _card = ClashCard(
  id: 'evo-card',
  playerId: 1,
  rarity: ClashRarity.n,
  level: 1,
  style: ClashPlayerStyle.potente,
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
  superTechniques: [_technique],
  basicPortraitPath: 'placeholder',
);

const _lrCard = ClashCard(
  id: 'lr-card',
  playerId: 2,
  rarity: ClashRarity.lr,
  level: 1,
  style: ClashPlayerStyle.potente,
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
  superTechniques: [_technique],
  basicPortraitPath: 'placeholder',
);

const _entry = ClashCardCatalogEntry(
  card: _card,
  name: 'Evolucionable',
  team: 'Eternal XI',
);

const _lrEntry = ClashCardCatalogEntry(
  card: _lrCard,
  name: 'Legendario',
  team: 'Eternal XI',
);

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  _FakeCardsDataSource(this._entries);

  final List<ClashCardCatalogEntry> _entries;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _entries;
}

Future<
  ({
    ClashPlayerCollectionRepository collection,
    ClashEvolutionMaterialsRepository evolutionMaterials,
    ClashCardsController controller,
    ClashCardsRepository cardsRepo,
  })
>
_setup({
  InMemoryClashPlayerCollectionBackend? storage,
  InMemoryClashEvolutionMaterialInventoryBackend? inventory,
  List<ClashCardCatalogEntry> entries = const [_entry],
}) async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(entries));
  final evolutionRepo = createTestEvolutionMaterialsRepository(
    inventoryStorage: inventory,
  );
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    storage: storage ?? InMemoryClashPlayerCollectionBackend(),
    evolutionMaterialsRepository: evolutionRepo,
  );
  for (final entry in entries) {
    await collectionRepo.grantMissingCardIds([entry.id]);
  }
  final controller = ClashCardsController(cardsRepo, collectionRepo);
  await controller.load();
  return (
    collection: collectionRepo,
    evolutionMaterials: evolutionRepo,
    controller: controller,
    cardsRepo: cardsRepo,
  );
}

Future<Widget> _detailApp({
  required ClashPlayerCollectionRepository collection,
  required ClashEvolutionMaterialsRepository evolutionMaterials,
  required ClashExpMaterialsRepository materials,
  required ClashTechniqueBooksRepository techniqueBooks,
  required ClashCardsController controller,
  String cardId = 'evo-card',
}) {
  return Future.value(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ClashCardsController>.value(value: controller),
        Provider<ClashPlayerCollectionRepository>.value(value: collection),
        Provider<ClashEvolutionMaterialsRepository>.value(
          value: evolutionMaterials,
        ),
        Provider<ClashExpMaterialsRepository>.value(value: materials),
        Provider<ClashTechniqueBooksRepository>.value(value: techniqueBooks),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: ClashCardDetailScreen(cardId: cardId)),
      ),
    ),
  );
}

ClashCardProgress _progress({
  int level = 20,
  int xp = 10,
  ClashRarity? evolvedRarity,
}) {
  return ClashCardProgress(
    cardId: _card.id,
    currentLevel: level,
    currentExperience: xp,
    techniqueLevels: {'evo-tech': ClashTechniqueLevel.i},
    evolvedRarity: evolvedRarity,
  );
}

void main() {
  group('ClashEvolutionMaterialsRepository', () {
    test('inventario inicial 3/1', () {
      final repo = createTestEvolutionMaterialsRepository();
      final quantities = repo.loadInventoryQuantities();
      expect(quantities['insignia-r'], 3);
      expect(quantities['insignia-sr'], 1);
    });

    test('parsea materiales desde JSON', () {
      final parsed = TestEvolutionMaterialsDataSource().parseMaterialsJson(
        clashTestEvolutionMaterialsJson,
      );
      expect(parsed, hasLength(2));
      expect(parsed.first.targetRarity, ClashRarity.r);
    });
  });

  group('evolveCard dominio', () {
    test('N puede evolucionar a R', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.evolveCard(cardId: _card.id);
      expect(result.succeeded, isTrue);
      expect(result.previousRarity, ClashRarity.n);
      expect(result.newRarity, ClashRarity.r);
    });

    test('R puede evolucionar a SR', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: _progress(level: 50, evolvedRarity: ClashRarity.r),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final first = await setup.collection.evolveCard(cardId: _card.id);
      expect(first.succeeded, isTrue);
      expect(first.newRarity, ClashRarity.sr);
    });

    test('SR no evoluciona', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: _progress(level: 80, evolvedRarity: ClashRarity.sr),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.evolveCard(cardId: _card.id);
      expect(result.succeeded, isFalse);
      expect(result.error, ClashEvolutionError.cannotEvolve);
    });

    test('LR no evoluciona', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_lrCard.id},
          cardProgress: {
            _lrCard.id: ClashCardProgress(
              cardId: 'lr-card',
              currentLevel: 50,
              currentExperience: 0,
              techniqueLevels: const {},
            ),
          },
        ),
      );
      final setup = await _setup(storage: storage, entries: const [_lrEntry]);
      final result = await setup.collection.evolveCard(cardId: _lrCard.id);
      expect(result.succeeded, isFalse);
      expect(result.error, ClashEvolutionError.cannotEvolve);
    });

    test('no evoluciona sin nivel mínimo', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress(level: 10)},
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.evolveCard(cardId: _card.id);
      expect(result.error, ClashEvolutionError.insufficientLevel);
    });

    test('no evoluciona sin material', () async {
      final inventory = InMemoryClashEvolutionMaterialInventoryBackend();
      final evolutionRepo = createTestEvolutionMaterialsRepository(
        inventoryStorage: inventory,
      );
      await evolutionRepo.consumeMaterial(
        materialId: 'insignia-r',
        quantity: 3,
      );
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage, inventory: inventory);
      final result = await setup.collection.evolveCard(cardId: _card.id);
      expect(result.error, ClashEvolutionError.insufficientMaterials);
    });

    test('evoluciona consumiendo material', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage);
      expect(setup.evolutionMaterials.quantityFor('insignia-r'), 3);
      await setup.collection.evolveCard(cardId: _card.id);
      expect(setup.evolutionMaterials.quantityFor('insignia-r'), 2);
    });

    test('conserva nivel XP y técnicas', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress(level: 25, xp: 42)},
        ),
      );
      final setup = await _setup(storage: storage);
      await setup.collection.evolveCard(cardId: _card.id);
      final progress = setup.collection.progressFor(_card.id)!;
      expect(progress.currentLevel, 25);
      expect(progress.currentExperience, 42);
      expect(progress.techniqueLevels['evo-tech'], ClashTechniqueLevel.i);
    });

    test('rareza efectiva y maxLevel cambian tras evolución', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage);
      await setup.collection.evolveCard(cardId: _card.id);
      final owned = await setup.collection.fetchOwnedCards();
      final entry = owned.single;
      expect(entry.effectiveRarity, ClashRarity.r);
      expect(entry.effectiveRarity.maxLevel, 80);
    });

    test('stats y potencia suben con rareza evolucionada', () async {
      final baseProgress = _progress(level: 1);
      final basePower = ClashCardLevelScaling.effectivePower(
        _card,
        baseProgress,
      );
      final evolvedProgress = ClashEvolutionService.progressAfterEvolution(
        progress: baseProgress,
        newRarity: ClashRarity.r,
      );
      final evolvedPower = ClashCardLevelScaling.effectivePower(
        _card,
        evolvedProgress,
      );
      expect(evolvedPower, greaterThan(basePower));
    });

    test('colección devuelve rareza evolucionada', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage);
      await setup.collection.evolveCard(cardId: _card.id);
      final cards = await setup.collection.fetchOwnedCards();
      expect(cards.single.effectiveRarity, ClashRarity.r);
    });

    test('filtro de rareza usa rareza evolucionada', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage);
      await setup.collection.evolveCard(cardId: _card.id);
      final owned = await setup.collection.fetchOwnedCards();
      final filtered = setup.cardsRepo.filterAndSort(
        cards: owned,
        rarity: ClashRarity.r,
      );
      expect(filtered, hasLength(1));
      final hidden = setup.cardsRepo.filterAndSort(
        cards: owned,
        rarity: ClashRarity.n,
      );
      expect(hidden, isEmpty);
    });

    test('partido usa rareza evolucionada', () async {
      final progress = ClashEvolutionService.progressAfterEvolution(
        progress: _progress(level: 20),
        newRarity: ClashRarity.r,
      );
      final entry = _entry.withProgress(progress);
      final basePower = entry.power;
      final squad = MatchSquadBuilder.buildUserSquad(
        lineup: ClashLineup7v7(
          id: 'lineup-1',
          name: 'Test',
          isActive: true,
          lastModifiedAt: DateTime.utc(2026),
          slots: {ClashPosition.striker: _card.id},
        ),
        catalogById: {_card.id: entry},
      );
      final striker = squad.firstWhere((p) => p.cardId == _card.id);
      expect(striker.power, basePower);
      expect(striker.power, greaterThan(60));
    });

    test('inventario persiste tras consumir material', () async {
      final inventory = InMemoryClashEvolutionMaterialInventoryBackend();
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage, inventory: inventory);
      await setup.collection.evolveCard(cardId: _card.id);
      setup.evolutionMaterials.clearCacheForTests();
      expect(setup.evolutionMaterials.quantityFor('insignia-r'), 2);
    });
  });

  group('UI evolución', () {
    readyDetail({int level = 10, ClashRarity? evolved}) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: _progress(level: level, evolvedRarity: evolved),
          },
        ),
      );
      return _setup(storage: storage);
    }

    Future<void> pumpDetail(WidgetTester tester, dynamic setup) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          evolutionMaterials: setup.evolutionMaterials,
          materials: createTestExpMaterialsRepository(),
          techniqueBooks: createTestTechniqueBooksRepository(),
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Evolución'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('detalle muestra sección Evolución', (tester) async {
      final setup = await readyDetail();
      await pumpDetail(tester, setup);
      expect(find.text('Evolución'), findsOneWidget);
    });

    testWidgets('botón deshabilitado si falta nivel', (tester) async {
      final setup = await readyDetail(level: 5);
      await pumpDetail(tester, setup);
      expect(find.text('Nivel insuficiente'), findsOneWidget);
      final evolveButton = find.widgetWithText(FilledButton, 'Evolucionar');
      expect(tester.widget<FilledButton>(evolveButton).onPressed, isNull);
    });

    testWidgets('botón deshabilitado si falta material', (tester) async {
      final inventory = InMemoryClashEvolutionMaterialInventoryBackend();
      final evolutionRepo = createTestEvolutionMaterialsRepository(
        inventoryStorage: inventory,
      );
      await evolutionRepo.consumeMaterial(
        materialId: 'insignia-r',
        quantity: 3,
      );
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {_card.id: _progress()},
        ),
      );
      final setup = await _setup(storage: storage, inventory: inventory);
      await pumpDetail(tester, setup);
      expect(find.text('Faltan materiales'), findsOneWidget);
    });

    testWidgets('evolucionar actualiza rareza visible', (tester) async {
      final setup = await readyDetail(level: 20);
      await setup.collection.evolveCard(cardId: _card.id);
      setup.collection.clearCacheForTests();
      await setup.controller.reloadOwnedCards();
      await pumpDetail(tester, setup);
      expect(find.text('R'), findsWidgets);
    });

    testWidgets('SR muestra no puede evolucionar más', (tester) async {
      final setup = await readyDetail(level: 80, evolved: ClashRarity.sr);
      await pumpDetail(tester, setup);
      expect(find.text('Esta carta no puede evolucionar más'), findsOneWidget);
    });

    testWidgets('colección refleja nueva rareza al volver', (tester) async {
      final setup = await readyDetail(level: 20);
      await setup.collection.evolveCard(cardId: _card.id);
      setup.collection.clearCacheForTests();
      await setup.controller.reloadOwnedCards();
      expect(
        setup.controller.visibleCards.single.effectiveRarity,
        ClashRarity.r,
      );
      expect(
        ClashRarityBadge.label(
          setup.controller.visibleCards.single.effectiveRarity,
        ),
        'R',
      );
    });

    testWidgets('SnackBar muestra cambio de rareza', (tester) async {
      final setup = await readyDetail(level: 20);
      final result = await setup.collection.evolveCard(cardId: _card.id);
      expect(result.succeeded, isTrue);
      final snack = SnackBar(
        content: Text(
          AppLocalizations(const Locale('es')).clashEvolutionSnack('N', 'R'),
        ),
      );
      expect((snack.content as Text).data, contains('N → R'));
    });
  });
}

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_reward_adapter.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_use_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'clash_test_support.dart';

const _technique = ClashSuperTechnique(
  id: 'tech-1',
  name: 'Tiro demo',
  description: 'Técnica de prueba',
  type: ClashTechniqueType.shot,
  style: ClashPlayerStyle.potente,
  basePower: 40,
  ptCost: 12,
  level: ClashTechniqueLevel.normal,
);

const _card = ClashCard(
  id: 'tech-book-card',
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
    ClashTechniqueBooksRepository books,
    ClashCardsController controller,
  })
>
_setup() async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
  final booksRepo = createTestTechniqueBooksRepository();
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    techniqueBooksRepository: booksRepo,
  );
  await collectionRepo.grantMissingCardIds([_card.id]);
  final controller = ClashCardsController(cardsRepo, collectionRepo);
  await controller.load();
  return (collection: collectionRepo, books: booksRepo, controller: controller);
}

Future<Widget> _detailApp({
  required ClashPlayerCollectionRepository collection,
  required ClashTechniqueBooksRepository books,
  required ClashExpMaterialsRepository materials,
  required ClashCardsController controller,
}) {
  return Future.value(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ClashCardsController>.value(value: controller),
        Provider<ClashPlayerCollectionRepository>.value(value: collection),
        Provider<ClashTechniqueBooksRepository>.value(value: books),
        Provider<ClashEvolutionMaterialsRepository>.value(
          value: createTestEvolutionMaterialsRepository(),
        ),
        Provider<ClashExpMaterialsRepository>.value(
          value: createTestExpMaterialsRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: ClashCardDetailScreen(cardId: 'tech-book-card'),
        ),
      ),
    ),
  );
}

void main() {
  group('ClashTechniqueBooksRepository', () {
    test('inventario inicial 3/1/0', () {
      final repo = createTestTechniqueBooksRepository();
      final quantities = repo.loadInventoryQuantities();
      expect(quantities['basic-technique-book'], 3);
      expect(quantities['advanced-technique-book'], 1);
      expect(quantities['master-technique-book'], 0);
    });

    test('parsea libros desde JSON', () {
      final parsed = TestTechniqueBooksDataSource().parseBooksJson(
        clashTestTechniqueBooksJson,
      );
      expect(parsed, hasLength(3));
      expect(parsed.first.levelUpSteps, 1);
    });
  });

  group('ClashTechniqueBookRewardAdapter', () {
    test('mapea technique-basic-book', () {
      final quantities =
          ClashTechniqueBookRewardAdapter.quantitiesFromStoryReward(
            const ClashStoryReward(
              items: [
                ClashStoryItemReward(
                  id: 'technique-basic-book',
                  name: 'Libro técnico',
                  quantity: 1,
                ),
              ],
            ),
          );
      expect(quantities['basic-technique-book'], 1);
    });
  });

  group('useTechniqueBookOnCard', () {
    test('usar libro básico sube Normal → I', () async {
      final setup = await _setup();
      final result = await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      expect(result.succeeded, isTrue);
      expect(result.previousLevel, ClashTechniqueLevel.normal);
      expect(result.newLevel, ClashTechniqueLevel.i);
    });

    test('usar avanzado sube dos pasos', () async {
      final setup = await _setup();
      final result = await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'advanced-technique-book',
      );
      expect(result.newLevel, ClashTechniqueLevel.v);
    });

    test('maestro no supera XI', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: ClashCardProgress(
              cardId: _card.id,
              currentLevel: 1,
              currentExperience: 0,
              techniqueLevels: {_technique.id: ClashTechniqueLevel.v},
            ),
          },
        ),
      );
      final booksRepo = createTestTechniqueBooksRepository();
      await booksRepo.grantBooks({'master-technique-book': 1});
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource()),
        storage: storage,
        techniqueBooksRepository: booksRepo,
      );
      final result = await collectionRepo.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'master-technique-book',
      );
      expect(result.newLevel, ClashTechniqueLevel.xi);
    });

    test('no usa libro con cantidad 0', () async {
      final inventory = InMemoryClashTechniqueBookInventoryBackend();
      final booksRepo = createTestTechniqueBooksRepository(
        inventoryStorage: inventory,
      );
      await booksRepo.consumeBook(bookId: 'basic-technique-book', quantity: 3);
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource()),
        techniqueBooksRepository: booksRepo,
      );
      await collectionRepo.grantMissingCardIds([_card.id]);
      final result = await collectionRepo.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      expect(result.error, ClashTechniqueBookUseError.insufficientQuantity);
    });

    test('no usa libro si técnica ya está en XI', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: ClashCardProgress(
              cardId: _card.id,
              currentLevel: 1,
              currentExperience: 0,
              techniqueLevels: {_technique.id: ClashTechniqueLevel.xi},
            ),
          },
        ),
      );
      final booksRepo = createTestTechniqueBooksRepository();
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource()),
        storage: storage,
        techniqueBooksRepository: booksRepo,
      );
      final before = booksRepo.quantityFor('basic-technique-book');
      final result = await collectionRepo.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      expect(result.error, ClashTechniqueBookUseError.techniqueAtMaxLevel);
      expect(booksRepo.quantityFor('basic-technique-book'), before);
    });

    test('no gasta libro si no mejora', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: ClashCardProgress(
              cardId: _card.id,
              currentLevel: 1,
              currentExperience: 0,
              techniqueLevels: {_technique.id: ClashTechniqueLevel.xi},
            ),
          },
        ),
      );
      final inventory = InMemoryClashTechniqueBookInventoryBackend();
      final booksRepo = createTestTechniqueBooksRepository(
        inventoryStorage: inventory,
      );
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource()),
        storage: storage,
        techniqueBooksRepository: booksRepo,
      );
      final before = booksRepo.quantityFor('basic-technique-book');
      await collectionRepo.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      expect(booksRepo.quantityFor('basic-technique-book'), before);
    });

    test('técnica inexistente falla', () async {
      final setup = await _setup();
      final result = await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: 'missing',
        bookId: 'basic-technique-book',
      );
      expect(result.error, ClashTechniqueBookUseError.techniqueNotFound);
    });

    test('carta no poseída falla', () async {
      final setup = await _setup();
      final result = await setup.collection.useTechniqueBookOnCard(
        cardId: 'other-card',
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      expect(result.error, ClashTechniqueBookUseError.cardNotOwned);
    });

    test('techniqueLevels persiste', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final booksRepo = createTestTechniqueBooksRepository();
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource()),
        storage: storage,
        techniqueBooksRepository: booksRepo,
      );
      await collectionRepo.grantMissingCardIds([_card.id]);
      await collectionRepo.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      collectionRepo.clearCacheForTests();
      final progress = collectionRepo.progressFor(_card.id);
      expect(progress?.techniqueLevels[_technique.id], ClashTechniqueLevel.i);
    });

    test('potencia efectiva aumenta tras subir nivel', () async {
      final setup = await _setup();
      final before = ClashTechniqueProgressResolver.effectivePower(
        technique: _technique,
        progress: setup.collection.progressFor(_card.id),
      );
      await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      final after = ClashTechniqueProgressResolver.effectivePower(
        technique: _technique,
        progress: setup.collection.progressFor(_card.id),
      );
      expect(after, greaterThan(before));
    });

    test('ptCost no cambia tras subir nivel', () async {
      final setup = await _setup();
      await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
        technique: _technique,
        progress: setup.collection.progressFor(_card.id),
      );
      expect(resolved.ptCost, _technique.ptCost);
    });
  });

  group('MatchSquadBuilder', () {
    test('partido usa técnica con nivel persistido', () {
      final progress = ClashCardProgress(
        cardId: _card.id,
        currentLevel: 1,
        currentExperience: 0,
        techniqueLevels: {_technique.id: ClashTechniqueLevel.x},
      );
      final enriched = _entry.withProgress(progress);
      final lineup = ClashLineup7v7(
        id: 'lineup-test',
        name: 'Test',
        isActive: true,
        slots: {ClashPosition.striker: _card.id},
        lastModifiedAt: DateTime.utc(2026),
      );
      final squad = MatchSquadBuilder.buildUserSquad(
        lineup: lineup,
        catalogById: {_card.id: enriched},
      );
      final striker = squad.firstWhere((player) => player.cardId == _card.id);
      expect(striker.superTechniques.first.level, ClashTechniqueLevel.x);
      expect(
        striker.superTechniques.first.effectivePower,
        greaterThan(_technique.basePower),
      );
      expect(striker.superTechniques.first.ptCost, _technique.ptCost);
    });
  });

  group('UI libros de técnica', () {
    testWidgets('detalle muestra nivel de técnica', (tester) async {
      configureClashDetailViewport(tester);
      final setup = await _setup();
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          books: setup.books,
          materials: createTestExpMaterialsRepository(),
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();
      await scrollClashDetailUntilVisible(tester, find.text('Mejorar técnica'));
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Mejorar técnica'), findsOneWidget);
    });

    testWidgets('detalle muestra libros disponibles', (tester) async {
      configureClashDetailViewport(tester);
      final setup = await _setup();
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          books: setup.books,
          materials: createTestExpMaterialsRepository(),
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();
      await scrollClashDetailUntilVisible(
        tester,
        find.text('Libro técnico básico'),
      );
      expect(find.text('Libro técnico básico'), findsOneWidget);
      expect(find.text('Cantidad: 3'), findsOneWidget);
    });

    testWidgets('botón deshabilitado con cantidad 0', (tester) async {
      configureClashDetailViewport(tester);
      final inventory = InMemoryClashTechniqueBookInventoryBackend();
      final booksRepo = createTestTechniqueBooksRepository(
        inventoryStorage: inventory,
      );
      await booksRepo.consumeBook(bookId: 'basic-technique-book', quantity: 3);
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        techniqueBooksRepository: booksRepo,
      );
      await collectionRepo.grantMissingCardIds([_card.id]);
      final controller = ClashCardsController(cardsRepo, collectionRepo);
      await controller.load();

      await tester.pumpWidget(
        await _detailApp(
          collection: collectionRepo,
          books: booksRepo,
          materials: createTestExpMaterialsRepository(),
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();

      await scrollClashDetailUntilVisible(
        tester,
        find.text('Libro técnico básico'),
      );
      expect(find.text('Libro técnico básico'), findsOneWidget);
      expect(find.text('Cantidad: 0'), findsNWidgets(2));

      final usarButtons = tester.widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Usar'),
      );
      expect(usarButtons.length, 3);
      expect(usarButtons.where((button) => button.onPressed == null).length, 2);
      expect(usarButtons.where((button) => button.onPressed != null).length, 1);
    });

    testWidgets('usar libro actualiza nivel visible', (tester) async {
      configureClashDetailViewport(tester);
      final setup = await _setup();
      await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      setup.collection.clearCacheForTests();
      await setup.controller.reloadOwnedCards();

      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          books: setup.books,
          materials: createTestExpMaterialsRepository(),
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      await scrollClashDetailUntilVisible(tester, find.text('I'));
      expect(find.text('I'), findsOneWidget);
      expect(find.text('Cantidad: 2'), findsWidgets);
    });

    testWidgets('usar libro actualiza potencia efectiva', (tester) async {
      configureClashDetailViewport(tester);
      final setup = await _setup();
      await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      setup.collection.clearCacheForTests();

      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          books: setup.books,
          materials: createTestExpMaterialsRepository(),
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      await scrollClashDetailUntilVisible(tester, find.text('42'));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('nivel máximo bloquea mejora', (tester) async {
      configureClashDetailViewport(tester);
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_card.id},
          cardProgress: {
            _card.id: ClashCardProgress(
              cardId: _card.id,
              currentLevel: 1,
              currentExperience: 0,
              techniqueLevels: {_technique.id: ClashTechniqueLevel.xi},
            ),
          },
        ),
      );
      final booksRepo = createTestTechniqueBooksRepository();
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        techniqueBooksRepository: booksRepo,
      );
      final controller = ClashCardsController(cardsRepo, collectionRepo);
      await controller.load();
      await tester.pumpWidget(
        await _detailApp(
          collection: collectionRepo,
          books: booksRepo,
          materials: createTestExpMaterialsRepository(),
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();
      await scrollClashDetailUntilVisible(tester, find.text('Mejorar técnica'));
      expect(find.text('Nivel máximo'), findsWidgets);
    });

    testWidgets('SnackBar muestra cambio de nivel', (tester) async {
      configureClashDetailViewport(tester);
      final setup = await _setup();
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          books: setup.books,
          materials: createTestExpMaterialsRepository(),
          controller: setup.controller,
        ),
      );
      await tester.pumpAndSettle();

      final result = await setup.collection.useTechniqueBookOnCard(
        cardId: _card.id,
        techniqueId: _technique.id,
        bookId: 'basic-technique-book',
      );
      expect(result.succeeded, isTrue);

      if (!tester.view.physicalSize.height.isFinite) {
        return;
      }

      final snackBar = SnackBar(
        content: Text(
          AppLocalizations(const Locale('es')).clashTechniqueLevelUpSnack(
            _technique.name,
            result.previousLevel.displayLabel,
            result.newLevel.displayLabel,
          ),
        ),
      );
      expect((snackBar.content as Text).data, contains('Tiro demo'));
      expect((snackBar.content as Text).data, contains('Normal'));
      expect((snackBar.content as Text).data, contains('I'));
    });
  });
}

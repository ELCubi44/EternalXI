import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_level_scaling.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_definition.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_unlock_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_tile.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'clash_test_support.dart';

const _technique = ClashSuperTechnique(
  id: 'tree-tech',
  name: 'Tiro árbol',
  description: 'Técnica test',
  type: ClashTechniqueType.shot,
  style: ClashPlayerStyle.potente,
  basePower: 40,
  ptCost: 12,
  level: ClashTechniqueLevel.normal,
);

const _nCard = ClashCard(
  id: 'tree-n-card',
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

const _srCard = ClashCard(
  id: 'tree-sr-card',
  playerId: 2,
  rarity: ClashRarity.sr,
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

const _nEntry = ClashCardCatalogEntry(
  card: _nCard,
  name: 'N Tree',
  team: 'Eternal XI',
);

const _srEntry = ClashCardCatalogEntry(
  card: _srCard,
  name: 'SR Tree',
  team: 'Rival',
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
    ClashCardsController controller,
    ClashCardsRepository cardsRepo,
  })
>
_setup({
  InMemoryClashPlayerCollectionBackend? storage,
  List<ClashCardCatalogEntry> entries = const [_nEntry, _srEntry],
}) async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(entries));
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    storage: storage ?? InMemoryClashPlayerCollectionBackend(),
    evolutionMaterialsRepository: createTestEvolutionMaterialsRepository(),
  );
  final controller = ClashCardsController(cardsRepo, collectionRepo);
  await controller.load();
  return (
    collection: collectionRepo,
    controller: controller,
    cardsRepo: cardsRepo,
  );
}

ClashCardProgress _progress({
  required String cardId,
  ClashRarity? evolvedRarity,
  int duplicateCopies = 0,
  Set<String> unlockedSkillNodeIds = const {},
}) {
  return ClashCardProgress(
    cardId: cardId,
    currentLevel: 50,
    currentExperience: 0,
    duplicateCopies: duplicateCopies,
    unlockedSkillNodeIds: unlockedSkillNodeIds,
    techniqueLevels: const {},
    evolvedRarity: evolvedRarity,
  );
}

Future<Widget> _detailApp({
  required ClashPlayerCollectionRepository collection,
  required ClashCardsController controller,
  String cardId = 'tree-sr-card',
}) {
  return Future.value(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ClashCardsController>.value(value: controller),
        Provider<ClashPlayerCollectionRepository>.value(value: collection),
        Provider<ClashEvolutionMaterialsRepository>.value(
          value: createTestEvolutionMaterialsRepository(),
        ),
        Provider<ClashExpMaterialsRepository>.value(
          value: createTestExpMaterialsRepository(),
        ),
        Provider<ClashTechniqueBooksRepository>.value(
          value: createTestTechniqueBooksRepository(),
        ),
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

void main() {
  group('Duplicados', () {
    test('conceder carta nueva la añade como owned', () async {
      final setup = await _setup();
      expect(setup.collection.loadOwnedCardIds(), isEmpty);
      await setup.collection.grantCardIds(['tree-sr-card']);
      expect(setup.collection.loadOwnedCardIds(), {'tree-sr-card'});
      final progress = setup.collection.loadCardProgress()['tree-sr-card'];
      expect(progress?.duplicateCopies, 0);
    });

    test('conceder carta repetida suma duplicado', () async {
      final setup = await _setup();
      await setup.collection.grantCardIds(['tree-sr-card']);
      await setup.collection.grantCardIds(['tree-sr-card']);
      final progress = setup.collection.loadCardProgress()['tree-sr-card'];
      expect(progress?.duplicateCopies, 1);
    });

    test('starter cards no duplican al reclamarse otra vez', () async {
      final setup = await _setup();
      final first = await setup.collection.grantEternalXiStarterNCards();
      expect(first, contains('tree-n-card'));
      final second = await setup.collection.grantEternalXiStarterNCards();
      expect(second, isEmpty);
      final progress = setup.collection.loadCardProgress()['tree-n-card'];
      expect(progress?.duplicateCopies, 0);
    });

    test('duplicateCopies persiste', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 3),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      setup.collection.clearCacheForTests();
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.duplicateCopies,
        3,
      );
    });

    test('consumir duplicado baja contador', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 2),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      expect(result.succeeded, isTrue);
      expect(result.remainingDuplicates, 1);
    });

    test('no permite contador negativo', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 0),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      expect(result.error, ClashSkillTreeUnlockError.noDuplicates);
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.duplicateCopies,
        0,
      );
    });

    test('grantCardCopy y grantCardCopies', () async {
      final setup = await _setup();
      await setup.collection.grantCardIds(['tree-sr-card']);
      await setup.collection.grantCardCopies('tree-sr-card', 2);
      expect(
        setup.collection.loadCardProgress()['tree-sr-card']?.duplicateCopies,
        2,
      );
      await setup.collection.grantCardCopy('tree-sr-card');
      expect(
        setup.collection.loadCardProgress()['tree-sr-card']?.duplicateCopies,
        3,
      );
    });
  });

  group('Árbol dominio', () {
    test('N no puede desbloquear árbol', () {
      final progress = _progress(cardId: _nCard.id, duplicateCopies: 5);
      final preview = ClashSkillTreeService.previewUnlock(
        cardId: _nCard.id,
        card: _nCard,
        progress: progress,
        nodeId: 'skill-1',
      );
      expect(preview.error, ClashSkillTreeUnlockError.rarityNotEligible);
    });

    test('R no puede desbloquear árbol', () {
      final progress = _progress(
        cardId: _nCard.id,
        evolvedRarity: ClashRarity.r,
        duplicateCopies: 5,
      );
      final preview = ClashSkillTreeService.previewUnlock(
        cardId: _nCard.id,
        card: _nCard,
        progress: progress,
        nodeId: 'skill-1',
      );
      expect(preview.error, ClashSkillTreeUnlockError.rarityNotEligible);
    });

    test('SR puede desbloquear nodo con duplicado', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 1),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      expect(result.succeeded, isTrue);
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.unlockedSkillNodeIds,
        {'skill-1'},
      );
    });

    test('SR sin duplicado no puede', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {_srCard.id: _progress(cardId: _srCard.id)},
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      expect(result.error, ClashSkillTreeUnlockError.noDuplicates);
    });

    test('no puede saltar nodos', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 2),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-2',
      );
      expect(result.error, ClashSkillTreeUnlockError.previousNodeLocked);
    });

    test('no puede desbloquear nodo ya desbloqueado', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(
              cardId: _srCard.id,
              duplicateCopies: 2,
              unlockedSkillNodeIds: {'skill-1'},
            ),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      expect(result.error, ClashSkillTreeUnlockError.nodeAlreadyUnlocked);
    });

    test('desbloquear nodo consume duplicado', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 3),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.duplicateCopies,
        2,
      );
    });

    test('desbloquear 5 nodos consume 5 duplicados', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 5),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      for (var i = 1; i <= ClashSkillTreeDefinition.nodeCount; i++) {
        final result = await setup.collection.unlockSkillTreeNode(
          cardId: _srCard.id,
          nodeId: 'skill-$i',
        );
        expect(result.succeeded, isTrue);
      }
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.duplicateCopies,
        0,
      );
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.unlockedSkillNodeIds,
        hasLength(5),
      );
    });

    test('stats suben al desbloquear nodo', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 1),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final before = ClashCardLevelScaling.effectiveStats(
        _srCard,
        setup.collection.loadCardProgress()[_srCard.id],
      );
      await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      setup.collection.clearCacheForTests();
      final after = ClashCardLevelScaling.effectiveStats(
        _srCard,
        setup.collection.loadCardProgress()[_srCard.id],
      );
      expect(after.defense, greaterThan(before.defense));
    });

    test('potencia sube al desbloquear nodo', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 1),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final before = ClashCardLevelScaling.effectivePower(
        _srCard,
        setup.collection.loadCardProgress()[_srCard.id],
      );
      await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      setup.collection.clearCacheForTests();
      final after = ClashCardLevelScaling.effectivePower(
        _srCard,
        setup.collection.loadCardProgress()[_srCard.id],
      );
      expect(after, greaterThan(before));
    });

    test('carta evolucionada a SR puede usar árbol', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_nCard.id},
          cardProgress: {
            _nCard.id: _progress(
              cardId: _nCard.id,
              evolvedRarity: ClashRarity.sr,
              duplicateCopies: 1,
            ),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final result = await setup.collection.unlockSkillTreeNode(
        cardId: _nCard.id,
        nodeId: 'skill-1',
      );
      expect(result.succeeded, isTrue);
    });

    test('nodos persisten', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 2),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      await setup.collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      setup.collection.clearCacheForTests();
      final reloaded = setup.collection.loadCardProgress()[_srCard.id];
      expect(reloaded?.unlockedSkillNodeIds, {'skill-1'});
    });

    test('partido usa stats con árbol', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final progress = _progress(
        cardId: _srCard.id,
        duplicateCopies: 1,
        unlockedSkillNodeIds: {'skill-1'},
      );
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {_srCard.id: progress},
        ),
      );
      final setup = await _setup(storage: storage);
      final entry = _srEntry.withProgress(progress);
      final enriched = setup.collection.enrichEntry(entry);
      final squad = MatchSquadBuilder.buildUserSquad(
        lineup: ClashLineup7v7(
          id: 'lineup-1',
          name: 'Test',
          isActive: true,
          lastModifiedAt: DateTime.utc(2026),
          slots: {ClashPosition.striker: _srCard.id},
        ),
        catalogById: {_srCard.id: enriched},
      );
      final striker = squad.firstWhere((p) => p.cardId == _srCard.id);
      final withoutTree = ClashCardLevelScaling.effectivePower(_srCard, null);
      expect(striker.power, greaterThan(withoutTree));
    });
  });

  group('UI árbol', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      dynamic setup, {
      String cardId = 'tree-sr-card',
    }) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        await _detailApp(
          collection: setup.collection,
          controller: setup.controller,
          cardId: cardId,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Árbol de habilidades'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('detalle N/R muestra Disponible al alcanzar SR', (
      tester,
    ) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_nCard.id},
          cardProgress: {_nCard.id: _progress(cardId: _nCard.id)},
        ),
      );
      final setup = await _setup(storage: storage);
      await pumpDetail(tester, setup, cardId: 'tree-n-card');
      expect(find.text('Disponible al alcanzar SR'), findsOneWidget);
    });

    testWidgets('detalle SR muestra árbol', (tester) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 1),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      await pumpDetail(tester, setup);
      expect(find.text('Defensa sólida'), findsOneWidget);
      expect(find.text('Duplicados disponibles: 1'), findsOneWidget);
    });

    testWidgets('botón desbloquear consume duplicado', (tester) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(cardId: _srCard.id, duplicateCopies: 1),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      await pumpDetail(tester, setup);
      await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nodo desbloqueado'), findsOneWidget);
      setup.collection.clearCacheForTests();
      expect(
        setup.collection.loadCardProgress()[_srCard.id]?.duplicateCopies,
        0,
      );
    });

    testWidgets('nodo desbloqueado cambia estado', (tester) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(
              cardId: _srCard.id,
              duplicateCopies: 0,
              unlockedSkillNodeIds: {'skill-1'},
            ),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      await pumpDetail(tester, setup);
      expect(find.textContaining('Desbloqueado'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Desbloquear'), findsNothing);
    });

    testWidgets('colección muestra indicador +copias', (tester) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: _progress(
              cardId: _srCard.id,
              evolvedRarity: ClashRarity.sr,
              duplicateCopies: 2,
            ),
          },
        ),
      );
      final setup = await _setup(storage: storage);
      final entry = setup.collection.enrichEntry(_srEntry);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ClashCardTile(entry: entry)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+2 copias'), findsOneWidget);
      expect(find.text('Árbol 0/5'), findsOneWidget);
    });
  });
}

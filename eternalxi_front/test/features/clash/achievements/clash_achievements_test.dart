import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_local_datasource.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_claim_result.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/screens/clash_achievements_screen.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

const _technique = ClashSuperTechnique(
  id: 'ach-technique',
  name: 'Técnica test',
  description: 'Test',
  type: ClashTechniqueType.shot,
  style: ClashPlayerStyle.valiente,
  basePower: 10,
  ptCost: 8,
  level: ClashTechniqueLevel.normal,
);

const _techniqueCard = ClashCard(
  id: 'ach-technique-card',
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
  superTechniques: [_technique],
  basicPortraitPath: 'placeholder',
);

const _techniqueEntry = ClashCardCatalogEntry(
  card: _techniqueCard,
  name: 'Técnica tester',
  team: 'Eternal XI',
);

const _evoCard = ClashCard(
  id: 'ach-evo-card',
  playerId: 2,
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
  superTechniques: [
    ClashSuperTechnique(
      id: 'ach-evo-tech',
      name: 'Tiro evo',
      description: 'T',
      type: ClashTechniqueType.shot,
      style: ClashPlayerStyle.potente,
      basePower: 40,
      ptCost: 12,
      level: ClashTechniqueLevel.normal,
    ),
  ],
  basicPortraitPath: 'placeholder',
);

const _evoEntry = ClashCardCatalogEntry(
  card: _evoCard,
  name: 'Evolucionable',
  team: 'Eternal XI',
);

const _srCard = ClashCard(
  id: 'ach-sr-card',
  playerId: 3,
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

const _srEntry = ClashCardCatalogEntry(
  card: _srCard,
  name: 'SR tester',
  team: 'Eternal XI',
);

class _TechniqueCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [
    _techniqueEntry,
  ];
}

class _EvoCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [_evoEntry];
}

class _TreeCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [_srEntry];
}

class _CollectorCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async {
    return List.generate(
      12,
      (index) => ClashCardCatalogEntry(
        card: ClashCard(
          id: 'collector-card-$index',
          playerId: 100 + index,
          rarity: ClashRarity.n,
          level: 1,
          style: ClashPlayerStyle.valiente,
          position: ClashPosition.striker,
          stats: const ClashStats(
            save: 10,
            defense: 10,
            pass: 10,
            dribble: 10,
            shot: 10,
            techniquePoints: 10,
            stamina: 100,
          ),
          superTechniques: const [],
          basicPortraitPath: 'placeholder',
        ),
        name: 'Collector $index',
        team: 'Test FC',
      ),
    );
  }
}

ClashCardProgress _evoProgress() {
  return ClashCardProgress(
    cardId: _evoCard.id,
    currentLevel: 20,
    currentExperience: 10,
    techniqueLevels: const {'ach-evo-tech': ClashTechniqueLevel.i},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashAchievementsLocalDataSource', () {
    test('carga logros desde JSON', () {
      final achievements = ClashAchievementsLocalDataSource()
          .parseAchievementsJson(clashTestAchievementsJson);
      expect(achievements, hasLength(8));
      expect(achievements.first.id, 'achievement-first-match');
    });
  });

  group('ClashAchievementsRepository', () {
    test('estado inicial vacío', () async {
      final setup = await createTestAchievementsSetup();
      final progress = await setup.achievements.fetchAchievementProgress();
      expect(progress, hasLength(8));
      expect(progress.every((item) => item.current == 0), isTrue);
      expect(progress.every((item) => !item.claimed), isTrue);
    });

    test('progreso no se resetea con cambio de día', () async {
      var day = DateTime(2026, 6, 10);
      final setup = await createTestAchievementsSetup(now: () => day);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      day = DateTime(2026, 6, 11);
      setup.achievements.clearCacheForTests();
      final play = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-first-match',
          );
      expect(play.current, 1);
    });

    test('playMatch progresa', () async {
      final setup = await createTestAchievementsSetup();
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      final play = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-first-match',
          );
      expect(play.current, 1);
      expect(play.isCompleted, isTrue);
    });

    test('winMatch progresa', () async {
      final setup = await createTestAchievementsSetup();
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.winMatch,
      );
      final win = (await setup.achievements.fetchAchievementProgress())
          .firstWhere((item) => item.achievement.id == 'achievement-first-win');
      expect(win.current, 1);
    });

    test('summon multi suma 10', () async {
      final setup = await createTestAchievementsSetup(initialGems: 500);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.summon,
        amount: 3,
      );
      final gacha = await createTestGachaRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        achievementEventSink: setup.sink,
        initialGems: 500,
      );
      final outcome = await gacha.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );
      expect(outcome.result, isNotNull);
      final summon = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-summon-novice',
          );
      expect(summon.current, 5);
      expect(summon.isCompleted, isTrue);
    });

    test('collectCards se completa con 10 cartas únicas', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_CollectorCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        achievementEventSink: setup.sink,
      );
      setup.sink.unbindForTests();
      final achievements = ClashAchievementsRepository(
        dataSource: TestAchievementsDataSource(),
        storage: InMemoryClashAchievementsBackend(),
        storyRepository: setup.story,
        grantService: ClashShopGrantService(
          collectionRepository: collection,
          ticketRepository: createTestTicketRepository(),
        ),
      );
      setup.sink.bind(achievements);
      final ids = List.generate(10, (index) => 'collector-card-$index');
      await collection.grantMissingCardIds(ids);
      final collector = (await achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-collector-starter',
          );
      expect(collector.current, 10);
      expect(collector.isCompleted, isTrue);
    });

    test('levelUpCard progresa al subir cartas', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final expRepo = createTestExpMaterialsRepository();
      await expRepo.grantMaterials({'basic-training-manual': 10});
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
        achievementEventSink: setup.sink,
      );
      await collection.grantGachaCard(
        cardId: 'ach-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useExpMaterialOnCard(
        cardId: 'ach-technique-card',
        materialId: 'basic-training-manual',
      );
      final trainer = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-trainer-beginner',
          );
      expect(trainer.current, greaterThanOrEqualTo(1));
    });

    test('upgradeTechnique progresa', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final booksRepo = createTestTechniqueBooksRepository();
      await booksRepo.grantBooks({'basic-technique-book': 3});
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        techniqueBooksRepository: booksRepo,
        achievementEventSink: setup.sink,
      );
      await collection.grantGachaCard(
        cardId: 'ach-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useTechniqueBookOnCard(
        cardId: 'ach-technique-card',
        techniqueId: 'ach-technique',
        bookId: 'basic-technique-book',
      );
      final technique = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-technique-upgraded',
          );
      expect(technique.current, 1);
    });

    test('evolveCard progresa', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_EvoCardsDataSource());
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_evoCard.id},
          cardProgress: {_evoCard.id: _evoProgress()},
        ),
      );
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        achievementEventSink: setup.sink,
      );
      await collection.evolveCard(cardId: _evoCard.id);
      final evolution = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-first-evolution',
          );
      expect(evolution.current, 1);
    });

    test('unlockSkillNode progresa', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_TreeCardsDataSource());
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: ClashCardProgress(
              cardId: _srCard.id,
              currentLevel: 50,
              currentExperience: 0,
              duplicateCopies: 2,
              techniqueLevels: const {},
            ),
          },
        ),
      );
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        achievementEventSink: setup.sink,
      );
      await collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      final tree = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-skill-tree-unlock',
          );
      expect(tree.current, 1);
    });

    test('claim completado concede recompensa', () async {
      final setup = await createTestAchievementsSetup(initialCoins: 100);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      final result = await setup.achievements.claimAchievement(
        'achievement-first-match',
      );
      expect(result.success, isTrue);
      expect(setup.story.walletCoins(), 600);
    });

    test('no claim incompleto', () async {
      final setup = await createTestAchievementsSetup();
      final result = await setup.achievements.claimAchievement(
        'achievement-first-match',
      );
      expect(result.success, isFalse);
      expect(result.error, ClashAchievementClaimError.notCompleted);
    });

    test('no claim doble', () async {
      final setup = await createTestAchievementsSetup();
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await setup.achievements.claimAchievement('achievement-first-match');
      final second = await setup.achievements.claimAchievement(
        'achievement-first-match',
      );
      expect(second.success, isFalse);
      expect(second.error, ClashAchievementClaimError.alreadyClaimed);
    });

    test('claim all reclama varios', () async {
      final setup = await createTestAchievementsSetup(initialCoins: 0);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.winMatch,
      );
      final results = await setup.achievements.claimAllCompleted();
      expect(results.where((item) => item.success).length, 2);
    });

    test('recompensa gemas va al wallet', () async {
      final setup = await createTestAchievementsSetup(initialGems: 0);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.winMatch,
      );
      await setup.achievements.claimAchievement('achievement-first-win');
      expect(setup.story.walletGems(), 2);
    });

    test('recompensa EXP va al inventario', () async {
      final setup = await createTestAchievementsSetup();
      final expRepo = createTestExpMaterialsRepository();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
      );
      setup.sink.unbindForTests();
      final achievements = ClashAchievementsRepository(
        dataSource: TestAchievementsDataSource(),
        storage: InMemoryClashAchievementsBackend(),
        storyRepository: setup.story,
        grantService: ClashShopGrantService(
          collectionRepository: collection,
          ticketRepository: createTestTicketRepository(),
        ),
      );
      await achievements.recordAchievementEvent(
        ClashAchievementType.levelUpCard,
        amount: 5,
      );
      final before = expRepo.quantityFor('advanced-training-manual');
      await achievements.claimAchievement('achievement-trainer-beginner');
      expect(expRepo.quantityFor('advanced-training-manual'), before + 1);
    });
  });

  group('ClashAchievements integración', () {
    test('ganar partido registra playMatch y winMatch', () async {
      final setup = await createTestAchievementsSetup();
      await setup.sink.record(ClashAchievementType.playMatch);
      await setup.sink.record(ClashAchievementType.winMatch);
      final progress = await setup.achievements.fetchAchievementProgress();
      final play = progress.firstWhere(
        (item) => item.achievement.id == 'achievement-first-match',
      );
      final win = progress.firstWhere(
        (item) => item.achievement.id == 'achievement-first-win',
      );
      expect(play.current, 1);
      expect(win.current, 1);
    });

    test('gacha registra summon por cartas obtenidas', () async {
      final setup = await createTestAchievementsSetup(initialGems: 50);
      final gacha = await createTestGachaRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        achievementEventSink: setup.sink,
        initialGems: 50,
      );
      await gacha.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      final summon = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-summon-novice',
          );
      expect(summon.current, 1);
    });

    test('usar material EXP con level up registra levelUpCard', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final expRepo = createTestExpMaterialsRepository();
      await expRepo.grantMaterials({'basic-training-manual': 5});
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
        achievementEventSink: setup.sink,
      );
      await collection.grantGachaCard(
        cardId: 'ach-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useExpMaterialOnCard(
        cardId: 'ach-technique-card',
        materialId: 'basic-training-manual',
      );
      final trainer = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-trainer-beginner',
          );
      expect(trainer.current, greaterThanOrEqualTo(1));
    });

    test('usar libro técnica registra upgradeTechnique', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final booksRepo = createTestTechniqueBooksRepository();
      await booksRepo.grantBooks({'basic-technique-book': 2});
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        techniqueBooksRepository: booksRepo,
        achievementEventSink: setup.sink,
      );
      await collection.grantGachaCard(
        cardId: 'ach-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useTechniqueBookOnCard(
        cardId: 'ach-technique-card',
        techniqueId: 'ach-technique',
        bookId: 'basic-technique-book',
      );
      final technique = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-technique-upgraded',
          );
      expect(technique.current, 1);
    });

    test('evolucionar registra evolveCard', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_EvoCardsDataSource());
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_evoCard.id},
          cardProgress: {_evoCard.id: _evoProgress()},
        ),
      );
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        achievementEventSink: setup.sink,
      );
      await collection.evolveCard(cardId: _evoCard.id);
      final evolution = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-first-evolution',
          );
      expect(evolution.current, 1);
    });

    test('desbloquear nodo registra unlockSkillNode', () async {
      final setup = await createTestAchievementsSetup();
      final cardsRepo = ClashCardsRepository(_TreeCardsDataSource());
      final storage = InMemoryClashPlayerCollectionBackend();
      await storage.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {_srCard.id},
          cardProgress: {
            _srCard.id: ClashCardProgress(
              cardId: _srCard.id,
              currentLevel: 50,
              currentExperience: 0,
              duplicateCopies: 2,
              techniqueLevels: const {},
            ),
          },
        ),
      );
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        achievementEventSink: setup.sink,
      );
      await collection.unlockSkillTreeNode(
        cardId: _srCard.id,
        nodeId: 'skill-1',
      );
      final tree = (await setup.achievements.fetchAchievementProgress())
          .firstWhere(
            (item) => item.achievement.id == 'achievement-skill-tree-unlock',
          );
      expect(tree.current, 1);
    });
  });

  group('ClashAchievements UI', () {
    Future<Widget> _achievementsApp(ClashAchievementsRepository repo) async {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Provider<ClashAchievementsRepository>.value(
          value: repo,
          child: const ClashAchievementsScreen(),
        ),
      );
    }

    Future<Widget> _homeApp(ClashAchievementsRepository repo) async {
      final setup = await createTestAchievementsSetup();
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>(
              create: (_) => ClashStoryController(storyRepository: setup.story),
            ),
            Provider<ClashAchievementsRepository>.value(value: repo),
          ],
          child: const ClashHomeScreen(),
        ),
      );
    }

    testWidgets('Home muestra tarjeta Logros', (tester) async {
      final setup = await createTestAchievementsSetup();
      await tester.pumpWidget(await _homeApp(setup.achievements));
      await tester.pumpAndSettle();
      expect(find.text('Logros'), findsOneWidget);
    });

    testWidgets('pantalla muestra lista de logros', (tester) async {
      final setup = await createTestAchievementsSetup();
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      expect(find.text('Primer partido'), findsOneWidget);
      expect(find.text('Primera victoria'), findsOneWidget);
    });

    testWidgets('filtro En progreso funciona', (tester) async {
      final setup = await createTestAchievementsSetup();
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'En progreso'));
      await tester.pumpAndSettle();
      expect(find.text('Primera victoria'), findsOneWidget);
      expect(find.text('Primer partido'), findsNothing);
    });

    testWidgets('filtro Completados funciona', (tester) async {
      final setup = await createTestAchievementsSetup();
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Completados'));
      await tester.pumpAndSettle();
      expect(find.text('Primer partido'), findsOneWidget);
      expect(find.text('Primera victoria'), findsNothing);
    });

    testWidgets('logro completado muestra Reclamar', (tester) async {
      final setup = await createTestAchievementsSetup();
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      expect(find.text('Reclamar'), findsWidgets);
    });

    testWidgets('reclamar cambia a Reclamado', (tester) async {
      final setup = await createTestAchievementsSetup(initialCoins: 0);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reclamar'));
      await tester.pumpAndSettle();
      expect(find.text('Reclamado'), findsOneWidget);
    });

    testWidgets('reclamar todas funciona', (tester) async {
      final setup = await createTestAchievementsSetup(initialCoins: 0);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.winMatch,
      );
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reclamar todas'));
      await tester.pumpAndSettle();
      expect(find.text('Reclamado'), findsWidgets);
    });

    testWidgets('recompensa visible', (tester) async {
      final setup = await createTestAchievementsSetup();
      await tester.pumpWidget(await _achievementsApp(setup.achievements));
      await tester.pumpAndSettle();
      expect(find.textContaining('500 monedas'), findsOneWidget);
      expect(find.textContaining('2 gemas'), findsWidgets);
    });
  });
}

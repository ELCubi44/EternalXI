import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_daily_missions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

const _technique = ClashSuperTechnique(
  id: 'mission-technique',
  name: 'TÃ©cnica test',
  description: 'Test',
  type: ClashTechniqueType.shot,
  style: ClashPlayerStyle.valiente,
  basePower: 10,
  ptCost: 8,
  level: ClashTechniqueLevel.normal,
);

const _techniqueCard = ClashCard(
  id: 'mission-technique-card',
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
  name: 'TÃ©cnica tester',
  team: 'Eternal XI',
);

class _TechniqueCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [
    _techniqueEntry,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashDailyMissionsLocalDataSource', () {
    test('carga misiones desde JSON', () {
      final missions = ClashDailyMissionsLocalDataSource().parseMissionsJson(
        clashTestDailyMissionsJson,
      );
      expect(missions, hasLength(6));
      expect(missions.first.id, 'daily-play-match');
    });
  });

  group('ClashDailyMissionsRepository', () {
    test('estado inicial del dÃ­a', () async {
      final setup = await createTestMissionsSetup();
      final progress = await setup.missions.fetchMissionProgress();
      expect(progress, hasLength(6));
      expect(progress.every((item) => item.current == 0), isTrue);
      expect(progress.every((item) => !item.claimed), isTrue);
    });

    test('progreso incrementa playMatch', () async {
      final setup = await createTestMissionsSetup();
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      final play = (await setup.missions.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'daily-play-match',
      );
      expect(play.current, 1);
      expect(play.isCompleted, isTrue);
    });

    test('progreso se capa en target', () async {
      final setup = await createTestMissionsSetup();
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
        amount: 5,
      );
      final play = (await setup.missions.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'daily-play-match',
      );
      expect(play.current, 1);
    });

    test('winMatch separado de playMatch', () async {
      final setup = await createTestMissionsSetup();
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.winMatch,
      );
      final play = (await setup.missions.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'daily-play-match',
      );
      final win = (await setup.missions.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'daily-win-match',
      );
      expect(play.current, 0);
      expect(win.current, 1);
    });

    test('summon progresa al pull exitoso', () async {
      final setup = await createTestMissionsSetup(initialGems: 500);
      final gacha = await createTestGachaRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        missionEventSink: setup.sink,
        initialGems: 500,
      );
      final outcome = await gacha.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      expect(outcome.result, isNotNull);
      final summon = (await setup.missions.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'daily-summon',
      );
      expect(summon.current, 1);
    });

    test('shopPurchase progresa al comprar', () async {
      final setup = await createTestMissionsSetup(initialCoins: 2000);
      final shop = await createTestShopRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        missionEventSink: setup.sink,
        initialCoins: 2000,
      );
      await shop.purchase('shop-basic-training-pack');
      final purchase = (await setup.missions.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'daily-shop-purchase',
      );
      expect(purchase.current, 1);
    });

    test('useExpMaterial progresa al usar manual', () async {
      final setup = await createTestMissionsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final expRepo = createTestExpMaterialsRepository();
      await expRepo.grantMaterials({'basic-training-manual': 5});
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
        missionEventSink: setup.sink,
      );
      await collection.grantGachaCard(
        cardId: 'mission-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useExpMaterialOnCard(
        cardId: 'mission-technique-card',
        materialId: 'basic-training-manual',
      );
      final expMission = (await setup.missions.fetchMissionProgress())
          .firstWhere((item) => item.mission.id == 'daily-use-exp-material');
      expect(expMission.current, 1);
    });

    test('upgradeTechnique progresa al usar libro', () async {
      final setup = await createTestMissionsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final booksRepo = createTestTechniqueBooksRepository();
      await booksRepo.grantBooks({'basic-technique-book': 2});
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        techniqueBooksRepository: booksRepo,
        missionEventSink: setup.sink,
      );
      await collection.grantGachaCard(
        cardId: 'mission-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useTechniqueBookOnCard(
        cardId: 'mission-technique-card',
        techniqueId: 'mission-technique',
        bookId: 'basic-technique-book',
      );
      final techniqueMission = (await setup.missions.fetchMissionProgress())
          .firstWhere((item) => item.mission.id == 'daily-upgrade-technique');
      expect(techniqueMission.current, 1);
    });

    test('reset diario al cambiar fecha', () async {
      final storage = InMemoryClashDailyMissionsBackend();
      var day = DateTime(2026, 6, 10);
      final setup = await createTestMissionsSetup(
        storage: storage,
        now: () => day,
      );
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      day = DateTime(2026, 6, 11);
      setup.missions.clearCacheForTests();
      final progress = await setup.missions.fetchMissionProgress();
      expect(progress.first.current, 0);
    });

    test('no reset si misma fecha', () async {
      final storage = InMemoryClashDailyMissionsBackend();
      final day = DateTime(2026, 6, 10);
      final setup = await createTestMissionsSetup(
        storage: storage,
        now: () => day,
      );
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      setup.missions.clearCacheForTests();
      final progress = await setup.missions.fetchMissionProgress();
      final play = progress.firstWhere(
        (item) => item.mission.id == 'daily-play-match',
      );
      expect(play.current, 1);
    });

    test('claim completada concede recompensa', () async {
      final setup = await createTestMissionsSetup(initialCoins: 100);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      final result = await setup.missions.claimMission('daily-play-match');
      expect(result.success, isTrue);
      expect(setup.story.walletCoins(), 400);
    });

    test('no claim si incompleta', () async {
      final setup = await createTestMissionsSetup();
      final result = await setup.missions.claimMission('daily-play-match');
      expect(result.success, isFalse);
      expect(result.error, ClashDailyMissionClaimError.notCompleted);
    });

    test('no claim doble', () async {
      final setup = await createTestMissionsSetup();
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      await setup.missions.claimMission('daily-play-match');
      final second = await setup.missions.claimMission('daily-play-match');
      expect(second.success, isFalse);
      expect(second.error, ClashDailyMissionClaimError.alreadyClaimed);
    });

    test('claim all reclama varias', () async {
      final setup = await createTestMissionsSetup(initialCoins: 0);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.summon,
      );
      final results = await setup.missions.claimAllCompleted();
      expect(results.where((item) => item.success).length, 2);
    });

    test('recompensa EXP va al inventario', () async {
      final expRepo = createTestExpMaterialsRepository();
      final sink = ClashDailyMissionEventSink();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        expMaterialsRepository: expRepo,
        missionEventSink: sink,
      );
      final storyProgress = InMemoryClashStoryProgressBackend();
      await storyProgress.writeProgress(const ClashStoryProgress());
      final story = ClashStoryRepository(
        dataSource: ClashStoryLocalDataSource(),
        progressStorage: storyProgress,
        collectionRepository: collection,
        ticketRepository: createTestTicketRepository(),
      );
      final missions = ClashDailyMissionsRepository(
        dataSource: TestMissionsDataSource(),
        storage: InMemoryClashDailyMissionsBackend(),
        storyRepository: story,
        rewardGranter: createTestRewardGranter(
          storyRepository: story,
          collectionRepository: collection,
          ticketRepository: createTestTicketRepository(),
        ),
      );
      sink.bind(missions);
      final before = expRepo.quantityFor('basic-training-manual');
      await missions.recordDailyMissionEvent(
        ClashDailyMissionType.shopPurchase,
      );
      await missions.claimMission('daily-shop-purchase');
      expect(expRepo.quantityFor('basic-training-manual'), before + 1);
    });

    test('recompensa gemas va al wallet', () async {
      final setup = await createTestMissionsSetup(initialGems: 0);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.winMatch,
      );
      await setup.missions.claimMission('daily-win-match');
      expect(setup.story.walletGems(), 1);
    });
  });

  group('ClashDailyMissions UI', () {
    Future<Widget> _missionsApp(ClashDailyMissionsRepository repo) async {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Provider<ClashDailyMissionsRepository>.value(
          value: repo,
          child: const ClashDailyMissionsScreen(),
        ),
      );
    }

    Future<Widget> _homeApp(ClashDailyMissionsRepository repo) async {
      final setup = await createTestMissionsSetup();
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>(
              create: (_) => ClashStoryController(storyRepository: setup.story),
            ),
            Provider<ClashDailyMissionsRepository>.value(value: repo),
          ],
          child: const ClashHomeScreen(),
        ),
      );
    }

    testWidgets(
      'Home Clash muestra tarjeta Misiones diarias',
      (tester) async {},
      skip: 'Inicio vacio temporalmente',
    );

    testWidgets('pantalla muestra misiones', (tester) async {
      final setup = await createTestMissionsSetup();
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      expect(find.text('Juega un partido'), findsOneWidget);
      expect(find.text('Gana un partido'), findsOneWidget);
    });

    testWidgets('muestra progreso 0/1', (tester) async {
      final setup = await createTestMissionsSetup();
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      expect(find.text('0/1'), findsWidgets);
    });

    testWidgets('muestra cabecera y progreso global', (tester) async {
      final setup = await createTestMissionsSetup();
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      expect(find.textContaining('Completadas'), findsOneWidget);
      expect(find.textContaining('Reclamadas'), findsOneWidget);
      expect(find.text('Se reinician maÃ±ana'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('tarjeta muestra recompensa y estado', (tester) async {
      final setup = await createTestMissionsSetup();
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      expect(find.text('Recompensa'), findsWidgets);
      expect(find.text('En progreso'), findsWidgets);
      expect(find.text('Monedas'), findsWidgets);
    });

    testWidgets('misiÃ³n completada muestra Reclamar', (tester) async {
      final setup = await createTestMissionsSetup();
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      expect(find.text('Reclamar'), findsWidgets);
    });

    testWidgets('reclamar cambia a Reclamada', (tester) async {
      final setup = await createTestMissionsSetup(initialCoins: 0);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reclamar'));
      await tester.pumpAndSettle();
      expect(find.text('Reclamada'), findsOneWidget);
    });

    testWidgets('reclamar suma recompensa', (tester) async {
      final setup = await createTestMissionsSetup(initialCoins: 0);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reclamar'));
      await tester.pumpAndSettle();
      expect(setup.story.walletCoins(), 300);
    });

    testWidgets('reclamar todas funciona', (tester) async {
      final setup = await createTestMissionsSetup(initialCoins: 0);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.summon,
      );
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reclamar todas'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Reclamadas 2'), findsOneWidget);
      expect(find.text('Reclamada'), findsWidgets);
    });

    testWidgets('reset diario muestra progreso nuevo', (tester) async {
      final storage = InMemoryClashDailyMissionsBackend();
      var day = DateTime(2026, 6, 10);
      final setup = await createTestMissionsSetup(
        storage: storage,
        now: () => day,
      );
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      day = DateTime(2026, 6, 11);
      setup.missions.clearCacheForTests();
      await tester.pumpWidget(await _missionsApp(setup.missions));
      await tester.pumpAndSettle();
      expect(find.text('0/1'), findsWidgets);
    });
  });
}

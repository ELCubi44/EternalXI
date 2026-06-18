import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
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
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_type.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_weekly_missions_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

const _technique = ClashSuperTechnique(
  id: 'weekly-technique',
  name: 'Técnica test',
  description: 'Test',
  type: ClashTechniqueType.shot,
  style: ClashPlayerStyle.valiente,
  basePower: 10,
  ptCost: 8,
  level: ClashTechniqueLevel.normal,
);

const _techniqueCard = ClashCard(
  id: 'weekly-technique-card',
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

class _TechniqueCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [
    _techniqueEntry,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashWeeklyMissionsLocalDataSource', () {
    test('carga weekly_missions.json', () {
      final missions = ClashWeeklyMissionsLocalDataSource().parseMissionsJson(
        clashTestWeeklyMissionsJson,
      );
      expect(missions, hasLength(8));
      expect(missions.first.id, 'weekly-play-matches');
    });
  });

  group('ClashWeeklyMissionsRepository', () {
    test('estado inicial con weekKey actual', () async {
      final setup = await createTestWeeklyMissionsSetup(
        now: () => DateTime(2026, 6, 10),
      );
      final summary = await setup.weekly.fetchSummary();
      expect(summary.weekKey, '2026-06-08');
      final progress = await setup.weekly.fetchMissionProgress();
      expect(progress, hasLength(8));
      expect(progress.every((item) => item.current == 0), isTrue);
    });

    test('progreso incrementa playMatch', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
      );
      final play = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-play-matches',
      );
      expect(play.current, 1);
    });

    test('progreso se capa en target', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 20,
      );
      final play = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-play-matches',
      );
      expect(play.current, 5);
    });

    test('winMatch progresa', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.winMatch,
      );
      final win = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-win-matches',
      );
      expect(win.current, 1);
    });

    test('summon multi suma 1 por acción', () async {
      final setup = await createTestWeeklyMissionsSetup(initialGems: 500);
      final hub = createTestProgressEventHub(
        daily: ClashDailyMissionEventSink(),
        weekly: setup.weeklySink,
      );
      final gacha = await createTestGachaRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        progressEventHub: hub,
        initialGems: 500,
      );
      await gacha.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.multi,
      );
      final summon = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-summon',
      );
      expect(summon.current, 1);
    });

    test('shopPurchase progresa', () async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 5000);
      final hub = createTestProgressEventHub(
        daily: ClashDailyMissionEventSink(),
        weekly: setup.weeklySink,
      );
      final shop = await createTestShopRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        progressEventHub: hub,
        initialCoins: 5000,
      );
      await shop.purchase('shop-basic-training-pack');
      final purchase = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-shop-purchase',
      );
      expect(purchase.current, 1);
    });

    test('levelUpCard progresa', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.levelUpCard,
        amount: 3,
      );
      final level = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-level-up-cards',
      );
      expect(level.current, 3);
    });

    test('upgradeTechnique progresa', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.upgradeTechnique,
        amount: 2,
      );
      final technique = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-upgrade-technique',
      );
      expect(technique.current, 2);
    });

    test('evolveCard progresa', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.evolveCard,
      );
      final evolution = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-evolve-cards',
      );
      expect(evolution.current, 1);
    });

    test('unlockSkillNode progresa', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.unlockSkillNode,
      );
      final tree = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-unlock-skill-nodes',
      );
      expect(tree.current, 1);
    });

    test('no resetea en misma semana', () async {
      var day = DateTime(2026, 6, 10);
      final storage = InMemoryClashWeeklyMissionsBackend();
      final setup = await createTestWeeklyMissionsSetup(
        storage: storage,
        now: () => day,
      );
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 2,
      );
      day = DateTime(2026, 6, 12);
      setup.weekly.clearCacheForTests();
      final play = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-play-matches',
      );
      expect(play.current, 2);
    });

    test('resetea al cambiar de semana', () async {
      var day = DateTime(2026, 6, 10);
      final storage = InMemoryClashWeeklyMissionsBackend();
      final setup = await createTestWeeklyMissionsSetup(
        storage: storage,
        now: () => day,
      );
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 3,
      );
      day = DateTime(2026, 6, 15);
      setup.weekly.clearCacheForTests();
      final play = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-play-matches',
      );
      expect(play.current, 0);
    });

    test('claim completada concede recompensa', () async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 100);
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      final result = await setup.weekly.claimMission('weekly-play-matches');
      expect(result.success, isTrue);
      expect(setup.story.walletCoins(), 2100);
    });

    test('no claim incompleta', () async {
      final setup = await createTestWeeklyMissionsSetup();
      final result = await setup.weekly.claimMission('weekly-play-matches');
      expect(result.success, isFalse);
      expect(result.error, ClashWeeklyMissionClaimError.notCompleted);
    });

    test('no claim doble', () async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      await setup.weekly.claimMission('weekly-play-matches');
      final second = await setup.weekly.claimMission('weekly-play-matches');
      expect(second.success, isFalse);
      expect(second.error, ClashWeeklyMissionClaimError.alreadyClaimed);
    });

    test('claim all reclama varios', () async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 0);
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.winMatch,
        amount: 3,
      );
      final results = await setup.weekly.claimAllCompleted();
      expect(results.where((item) => item.success).length, 2);
    });
  });

  group('ClashWeeklyMissions integración hub', () {
    test('evento partido actualiza daily y weekly', () async {
      final dailySink = ClashDailyMissionEventSink();
      final weeklySetup = await createTestWeeklyMissionsSetup();
      final dailySetup = await createTestMissionsSetup();
      dailySink.bind(dailySetup.missions);
      final hub = createTestProgressEventHub(
        daily: dailySink,
        weekly: weeklySetup.weeklySink,
      );
      await hub.recordPlayMatch();
      await hub.recordWinMatch();
      final dailyPlay = (await dailySetup.missions.fetchMissionProgress())
          .firstWhere((item) => item.mission.id == 'daily-play-match');
      final weeklyPlay = (await weeklySetup.weekly.fetchMissionProgress())
          .firstWhere((item) => item.mission.id == 'weekly-play-matches');
      final weeklyWin = (await weeklySetup.weekly.fetchMissionProgress())
          .firstWhere((item) => item.mission.id == 'weekly-win-matches');
      expect(dailyPlay.current, 1);
      expect(weeklyPlay.current, 1);
      expect(weeklyWin.current, 1);
    });

    test('gacha actualiza weekly summon', () async {
      final setup = await createTestWeeklyMissionsSetup(initialGems: 50);
      final hub = createTestProgressEventHub(
        daily: ClashDailyMissionEventSink(),
        weekly: setup.weeklySink,
      );
      final gacha = await createTestGachaRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        progressEventHub: hub,
        initialGems: 50,
      );
      await gacha.pull(
        bannerId: 'starter-banner-001',
        type: ClashGachaPullType.single,
      );
      final summon = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-summon',
      );
      expect(summon.current, 1);
    });

    test('tienda actualiza weekly shopPurchase', () async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 5000);
      final hub = createTestProgressEventHub(
        daily: ClashDailyMissionEventSink(),
        weekly: setup.weeklySink,
      );
      final shop = await createTestShopRepository(
        storyRepository: setup.story,
        collectionRepository: setup.collection,
        progressEventHub: hub,
        initialCoins: 5000,
      );
      await shop.purchase('shop-basic-training-pack');
      final purchase = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-shop-purchase',
      );
      expect(purchase.current, 1);
    });

    test('mejora técnica actualiza weekly', () async {
      final setup = await createTestWeeklyMissionsSetup();
      final cardsRepo = ClashCardsRepository(_TechniqueCardsDataSource());
      final booksRepo = createTestTechniqueBooksRepository();
      await booksRepo.grantBooks({'basic-technique-book': 2});
      final hub = createTestProgressEventHub(
        daily: ClashDailyMissionEventSink(),
        weekly: setup.weeklySink,
      );
      final collection = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        techniqueBooksRepository: booksRepo,
        progressEventHub: hub,
      );
      await collection.grantGachaCard(
        cardId: 'weekly-technique-card',
        rarity: ClashRarity.n,
      );
      await collection.useTechniqueBookOnCard(
        cardId: 'weekly-technique-card',
        techniqueId: 'weekly-technique',
        bookId: 'basic-technique-book',
      );
      final technique = (await setup.weekly.fetchMissionProgress()).firstWhere(
        (item) => item.mission.id == 'weekly-upgrade-technique',
      );
      expect(technique.current, 1);
    });
  });

  group('ClashWeeklyMissions UI', () {
    Future<Widget> weeklyApp(ClashWeeklyMissionsRepository repo) async {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Provider<ClashWeeklyMissionsRepository>.value(
          value: repo,
          child: const ClashWeeklyMissionsScreen(),
        ),
      );
    }

    Future<Widget> homeApp(ClashWeeklyMissionsRepository repo) async {
      final setup = await createTestWeeklyMissionsSetup();
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>(
              create: (_) => ClashStoryController(storyRepository: setup.story),
            ),
            Provider<ClashWeeklyMissionsRepository>.value(value: repo),
          ],
          child: const ClashHomeScreen(),
        ),
      );
    }

    testWidgets('Home muestra Misiones semanales', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestWeeklyMissionsSetup();
      await tester.pumpWidget(await homeApp(setup.weekly));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Misiones semanales'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Misiones semanales'), findsOneWidget);
    });

    testWidgets('pantalla weekly muestra lista', (tester) async {
      final setup = await createTestWeeklyMissionsSetup();
      await tester.pumpWidget(await weeklyApp(setup.weekly));
      await tester.pumpAndSettle();
      expect(find.text('Juega 5 partidos'), findsOneWidget);
      expect(find.text('Gana 3 partidos'), findsOneWidget);
    });

    testWidgets('muestra progreso', (tester) async {
      final setup = await createTestWeeklyMissionsSetup();
      await tester.pumpWidget(await weeklyApp(setup.weekly));
      await tester.pumpAndSettle();
      expect(find.text('0/5'), findsWidgets);
    });

    testWidgets('reclamar cambia estado', (tester) async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 0);
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      await tester.pumpWidget(await weeklyApp(setup.weekly));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reclamar'));
      await tester.pumpAndSettle();
      expect(find.text('Reclamada'), findsOneWidget);
    });

    testWidgets('reclamar todas funciona', (tester) async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 0);
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.winMatch,
        amount: 3,
      );
      await tester.pumpWidget(await weeklyApp(setup.weekly));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reclamar todas'));
      await tester.pumpAndSettle();
      expect(find.text('Reclamada'), findsWidgets);
    });

    testWidgets('resumen se actualiza', (tester) async {
      final setup = await createTestWeeklyMissionsSetup();
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      await tester.pumpWidget(await weeklyApp(setup.weekly));
      await tester.pumpAndSettle();
      expect(find.textContaining('Completadas 1/8'), findsOneWidget);
    });

    testWidgets('ruta weekly-missions funciona', (tester) async {
      final setup = await createTestWeeklyMissionsSetup();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.clashWeeklyMissions,
            builder: (context, state) =>
                Provider<ClashWeeklyMissionsRepository>.value(
                  value: setup.weekly,
                  child: const ClashWeeklyMissionsScreen(),
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
      router.go(AppRoutes.clashWeeklyMissions);
      await tester.pumpAndSettle();
      expect(find.text('Misiones semanales'), findsOneWidget);
    });
  });
}

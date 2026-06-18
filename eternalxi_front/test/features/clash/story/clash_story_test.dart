import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_chapter.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_saga.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_level_reader_screen.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/clash_team_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cards/clash_test_support.dart';
import 'package:provider/provider.dart';

const _sagasJson = '''
{
  "sagas": [
    {
      "id": "saga-01",
      "title": "Saga test",
      "description": "Descripción saga",
      "order": 1,
      "chapterIds": ["chapter-01"],
      "isUnlocked": true
    }
  ]
}
''';

const _chapterJson = '''
{
  "chapter": {
    "id": "chapter-01",
    "sagaId": "saga-01",
    "title": "Capítulo test",
    "description": "Capítulo de prueba",
    "order": 1,
    "levels": [
      {
        "id": "prologue-lvl-01",
        "chapterId": "chapter-01",
        "title": "Nivel 1",
        "description": "Intro",
        "order": 1,
        "type": "story",
        "energyCost": 5,
        "rewards": { "gems": 1, "items": [{"id": "a", "name": "Objeto A", "quantity": 1}] },
        "scenes": [
          {"id": "s1", "order": 1, "type": "narration", "text": "Escena 1", "isSkippable": true},
          {"id": "s2", "order": 2, "type": "dialogue", "speaker": "Coach", "text": "Escena 2", "isSkippable": true}
        ]
      },
      {
        "id": "prologue-lvl-02",
        "chapterId": "chapter-01",
        "title": "Nivel 2",
        "description": "Compañeros",
        "order": 2,
        "type": "story",
        "energyCost": 5,
        "rewards": { "gems": 1 },
        "scenes": [
          {"id": "s3", "order": 1, "type": "narration", "text": "Escena 3", "isSkippable": true}
        ]
      },
      {
        "id": "prologue-lvl-03",
        "chapterId": "chapter-01",
        "title": "Nivel 3",
        "description": "Formación",
        "order": 3,
        "type": "story",
        "energyCost": 5,
        "rewards": {
          "gems": 1,
          "starterRosterKey": "eternal_xi_starter_n"
        },
        "scenes": [
          {"id": "s4", "order": 1, "type": "narration", "text": "Escena final", "isSkippable": false}
        ],
        "completionUnlocks": {
          "clashTeamUnlocked": true,
          "firstLineupUnlocked": true,
          "nextPlayableLevelUnlocked": true
        }
      },
      {
        "id": "chapter_01_level_04",
        "chapterId": "chapter-01",
        "title": "Nivel match",
        "description": "Match futuro",
        "order": 4,
        "type": "match",
        "energyCost": 8,
        "recommendedPower": 100,
        "rewards": { "gems": 2, "coins": 100 },
        "scenes": [],
        "required": {
          "clashTeamUnlocked": true,
          "completeActiveLineup": true
        }
      }
    ]
  }
}
''';

const _cardsJson = '''
{
  "cards": [
    {
      "id": "exi-n-gk-001",
      "playerId": 1,
      "name": "Portero EXI",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "valiente",
      "position": "goalkeeper",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 40, "defense": 10, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st1", "name": "Parada", "description": "T", "type": "save", "style": "valiente", "basePower": 40, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "exi-n-st-001",
      "playerId": 2,
      "name": "Delantero EXI",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "potente",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 10, "shot": 35, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st2", "name": "Tiro", "description": "T", "type": "shot", "style": "potente", "basePower": 40, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "rival-n-001",
      "playerId": 99,
      "name": "Rival",
      "team": "Rival FC",
      "rarity": "n",
      "level": 1,
      "style": "agil",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 10, "shot": 30, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st3", "name": "Tiro", "description": "T", "type": "shot", "style": "agil", "basePower": 35, "ptCost": 10, "level": "normal"}]
    }
  ]
}
''';

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  _FakeCardsDataSource(this._cards);

  final List<ClashCardCatalogEntry> _cards;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _cards;
}

class _TestStoryDataSource extends ClashStoryLocalDataSource {
  @override
  Future<List<ClashStorySaga>> loadSagas() async {
    return ClashStoryLocalDataSource().parseSagasJson(_sagasJson);
  }

  @override
  Future<ClashStoryChapter> loadChapter(String chapterId) async {
    return ClashStoryLocalDataSource().parseChapterJson(_chapterJson);
  }
}

Future<
  ({
    ClashStoryRepository storyRepo,
    ClashPlayerCollectionRepository collectionRepo,
    InMemoryClashStoryProgressBackend progressStorage,
  })
>
_setup() async {
  final cards = ClashCardsLocalDataSource().parseCardsJson(_cardsJson);
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(cards));
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
  );
  final progressStorage = InMemoryClashStoryProgressBackend();
  final storyRepo = ClashStoryRepository(
    dataSource: _TestStoryDataSource(),
    progressStorage: progressStorage,
    collectionRepository: collectionRepo,
  );
  return (
    storyRepo: storyRepo,
    collectionRepo: collectionRepo,
    progressStorage: progressStorage,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashStoryLocalDataSource', () {
    test('parseo de saga/capítulo/niveles y tipos story/match/mixed', () {
      final ds = ClashStoryLocalDataSource();
      final sagas = ds.parseSagasJson(_sagasJson);
      expect(sagas, hasLength(1));
      expect(sagas.first.chapterIds, ['chapter-01']);

      final chapter = ds.parseChapterJson(_chapterJson);
      expect(chapter.levels, hasLength(4));
      expect(chapter.levels[0].type, ClashStoryLevelType.story);
      expect(chapter.levels[3].type, ClashStoryLevelType.match);
      expect(chapter.levels[0].scenes, hasLength(2));
    });
  });

  group('ClashStoryRepository', () {
    test('completar Nivel 1 desbloquea Nivel 2', () async {
      final setup = await _setup();
      final chapter = await setup.storyRepo.loadChapter('chapter-01');
      final levels = chapter.levels;

      expect(
        setup.storyRepo.levelStatus(level: levels[1], chapterLevels: levels),
        ClashStoryLevelStatus.locked,
      );

      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');

      expect(
        setup.storyRepo.levelStatus(level: levels[1], chapterLevels: levels),
        ClashStoryLevelStatus.available,
      );
    });

    test('completar Nivel 2 desbloquea Nivel 3', () async {
      final setup = await _setup();
      final chapter = await setup.storyRepo.loadChapter('chapter-01');
      final levels = chapter.levels;

      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-02');

      expect(
        setup.storyRepo.levelStatus(level: levels[2], chapterLevels: levels),
        ClashStoryLevelStatus.available,
      );
    });

    test('completar Nivel 3 entrega cartas N una sola vez', () async {
      final setup = await _setup();
      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-02');

      final result = await setup.storyRepo.completeStoryLevel(
        'prologue-lvl-03',
      );
      expect(result.newlyGrantedCardIds, hasLength(2));
      expect(setup.collectionRepo.loadOwnedCardIds(), hasLength(2));
      expect(setup.storyRepo.loadProgress().clashTeamUnlocked, isTrue);
      expect(setup.storyRepo.loadProgress().eternalXiCardsGranted, isTrue);
    });

    test('repetir entrega starter no duplica cartas', () async {
      final setup = await _setup();
      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-02');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-03');

      final extra = await setup.collectionRepo.grantEternalXiStarterNCards();
      expect(extra, isEmpty);
      expect(setup.collectionRepo.loadOwnedCardIds(), hasLength(2));
    });

    test('persistencia local conserva progreso', () async {
      final setup = await _setup();
      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');

      final reloaded = ClashStoryRepository(
        dataSource: _TestStoryDataSource(),
        progressStorage: setup.progressStorage,
        collectionRepository: setup.collectionRepo,
      );
      expect(
        reloaded.loadProgress().isLevelCompleted('prologue-lvl-01'),
        isTrue,
      );
    });

    test('nivel bloqueado no se puede completar', () async {
      final setup = await _setup();
      expect(
        () => setup.storyRepo.completeStoryLevel('prologue-lvl-02'),
        throwsA(isA<ClashStoryOperationException>()),
      );
    });

    test('Nivel 4 match bloqueado antes del Nivel 3', () async {
      final setup = await _setup();
      final chapter = await setup.storyRepo.loadChapter('chapter-01');
      final levels = chapter.levels;
      final level4 = levels.firstWhere((l) => l.id == 'chapter_01_level_04');

      expect(
        setup.storyRepo.levelStatus(level: level4, chapterLevels: levels),
        ClashStoryLevelStatus.locked,
      );
    });

    test('completar Nivel 3 desbloquea Nivel 4 match', () async {
      final setup = await _setup();
      final chapter = await setup.storyRepo.loadChapter('chapter-01');
      final levels = chapter.levels;
      final level4 = levels.firstWhere((l) => l.id == 'chapter_01_level_04');

      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-02');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-03');

      expect(
        setup.storyRepo.levelStatus(level: level4, chapterLevels: levels),
        ClashStoryLevelStatus.available,
      );
    });
  });

  group('ClashStoryController', () {
    test('lector avanza escenas', () async {
      final setup = await _setup();
      final controller = ClashStoryController(storyRepository: setup.storyRepo);
      await controller.load();
      await controller.prepareLevel('prologue-lvl-01');

      expect(controller.sceneIndex, 0);
      controller.nextScene();
      expect(controller.sceneIndex, 1);
      expect(controller.hasNextScene, isFalse);
    });
  });

  group('ClashStory UI', () {
    Future<Widget> _app({
      required ClashStoryController controller,
      required Widget child,
    }) async {
      return ChangeNotifierProvider<ClashStoryController>.value(
        value: controller,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('mapa muestra niveles del prólogo incluido match bloqueado', (
      tester,
    ) async {
      final setup = await _setup();
      final controller = ClashStoryController(storyRepository: setup.storyRepo);
      await controller.load();

      await tester.pumpWidget(
        await _app(controller: controller, child: const ClashStoryMapScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nivel 1'), findsOneWidget);
      expect(find.text('Nivel 2'), findsOneWidget);
      expect(find.text('Nivel 3'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Nivel match'), findsOneWidget);
    });

    test('mapa abre prepare para nivel match', () {
      expect(
        AppRoutes.clashStoryLevelPrepare('chapter_01_level_04'),
        '/clash/story/level/chapter_01_level_04/prepare',
      );
    });

    testWidgets('nivel bloqueado no se puede abrir desde lector', (
      tester,
    ) async {
      final setup = await _setup();
      final controller = ClashStoryController(storyRepository: setup.storyRepo);
      await controller.load();

      await tester.pumpWidget(
        await _app(
          controller: controller,
          child: const ClashStoryLevelReaderScreen(levelId: 'prologue-lvl-02'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nivel bloqueado'), findsOneWidget);
    });

    Future<ClashLineupsController> _lineupsController() async {
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(const []));
      final controller = ClashLineupsController(
        lineupsRepository: ClashLineupsRepository(
          storage: InMemoryClashLineupsBackend(),
          cardsRepository: cardsRepo,
        ),
        collectionRepository: createTestCollectionRepository(
          cardsRepository: cardsRepo,
        ),
      );
      await controller.load();
      return controller;
    }

    Future<Widget> _teamApp(ClashStoryController controller) async {
      final lineups = await _lineupsController();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ClashStoryController>.value(value: controller),
          ChangeNotifierProvider<ClashLineupsController>.value(value: lineups),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: ClashTeamScreen()),
        ),
      );
    }

    testWidgets('Equipo muestra bloqueo antes del Nivel 3', (tester) async {
      final setup = await _setup();
      final controller = ClashStoryController(storyRepository: setup.storyRepo);

      await tester.pumpWidget(await _teamApp(controller));
      await tester.pumpAndSettle();

      expect(
        ClashStoryGate.isTeamUnlocked(
          tester.element(find.byType(ClashTeamScreen)),
        ),
        isFalse,
      );
    });

    testWidgets('Equipo queda desbloqueado después del Nivel 3', (
      tester,
    ) async {
      final setup = await _setup();
      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-02');
      await setup.storyRepo.completeStoryLevel('prologue-lvl-03');

      final controller = ClashStoryController(storyRepository: setup.storyRepo);
      await controller.load();

      await tester.pumpWidget(await _teamApp(controller));
      await tester.pumpAndSettle();

      expect(
        ClashStoryGate.isTeamUnlocked(
          tester.element(find.byType(ClashTeamScreen)),
        ),
        isTrue,
      );
    });
  });
}

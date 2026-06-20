import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/screens/clash_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_chapter.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_saga.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_level_reader_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

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
        "rewards": { "gems": 1, "starterRosterKey": "eternal_xi_starter_n" },
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
        "rivalTeamId": "rival-training-squad",
        "rewards": { "gems": 2, "coins": 100 },
        "scenes": [],
        "required": {
          "clashTeamUnlocked": true,
          "completeActiveLineup": true
        },
        "matchObjectives": [
          {
            "id": "win_match",
            "type": "winMatch",
            "title": "Ganar el partido",
            "description": "Gana el partido."
          }
        ]
      }
    ]
  }
}
''';

const _cardsJson = '''
{
  "cards": [
    {"id": "c-gk", "playerId": 1, "name": "Portero", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "goalkeeper", "basicPortraitPath": "p", "stats": {"save": 40, "defense": 10, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-cb", "playerId": 2, "name": "Central", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "centreBack", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 30, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-fb", "playerId": 3, "name": "Lateral", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "fullBack", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 25, "pass": 12, "dribble": 10, "shot": 6, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-dm", "playerId": 4, "name": "MCD", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "defensiveMidfielder", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 20, "pass": 20, "dribble": 10, "shot": 8, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-am", "playerId": 5, "name": "MCO", "team": "EXI", "rarity": "n", "level": 1, "style": "valiente", "position": "attackingMidfielder", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 12, "pass": 22, "dribble": 14, "shot": 12, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-wg", "playerId": 6, "name": "Extremo", "team": "EXI", "rarity": "n", "level": 1, "style": "agil", "position": "winger", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 10, "pass": 14, "dribble": 22, "shot": 16, "techniquePoints": 10, "stamina": 100}, "superTechniques": []},
    {"id": "c-st", "playerId": 7, "name": "Delantero", "team": "EXI", "rarity": "n", "level": 1, "style": "potente", "position": "striker", "basicPortraitPath": "p", "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 12, "shot": 30, "techniquePoints": 10, "stamina": 100}, "superTechniques": []}
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
    ClashStoryController controller,
    ClashLineupsController lineupsController,
    ClashCardsController cardsController,
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
  final lineupsController = ClashLineupsController(
    lineupsRepository: ClashLineupsRepository(
      storage: InMemoryClashLineupsBackend(),
      cardsRepository: cardsRepo,
    ),
    collectionRepository: collectionRepo,
  );
  final cardsController = ClashCardsController(cardsRepo, collectionRepo);
  final controller = ClashStoryController(storyRepository: storyRepo);
  await controller.load();
  await lineupsController.load();
  await cardsController.load();
  return (
    storyRepo: storyRepo,
    collectionRepo: collectionRepo,
    controller: controller,
    lineupsController: lineupsController,
    cardsController: cardsController,
  );
}

Future<void> _completePrologue(ClashStoryRepository repo) async {
  await repo.completeStoryLevel('prologue-lvl-01');
  await repo.completeStoryLevel('prologue-lvl-02');
  await repo.completeStoryLevel('prologue-lvl-03');
}

Future<void> _fillLineup(ClashLineupsController lineups) async {
  const mapping = {
    ClashPosition.goalkeeper: 'c-gk',
    ClashPosition.centreBack: 'c-cb',
    ClashPosition.fullBack: 'c-fb',
    ClashPosition.defensiveMidfielder: 'c-dm',
    ClashPosition.attackingMidfielder: 'c-am',
    ClashPosition.winger: 'c-wg',
    ClashPosition.striker: 'c-st',
  };
  for (final entry in mapping.entries) {
    await lineups.assignCard(slot: entry.key, cardId: entry.value);
  }
}

Widget _storyShell({
  required ClashStoryController controller,
  required Widget child,
  ClashLineupsController? lineups,
  ClashCardsController? cards,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ClashStoryController>.value(value: controller),
      if (lineups != null)
        ChangeNotifierProvider<ClashLineupsController>.value(value: lineups),
      if (cards != null)
        ChangeNotifierProvider<ClashCardsController>.value(value: cards),
      Provider<ClashRivalsRepository>(create: (_) => ClashRivalsRepository()),
    ],
    child: child,
  );
}

Widget _storyApp({
  required ClashStoryController controller,
  required Widget child,
  ClashLineupsController? lineups,
  ClashCardsController? cards,
}) {
  return _storyShell(
    controller: controller,
    lineups: lineups,
    cards: cards,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashStory map data', () {
    test('nivel match del capítulo test incluye objetivos', () async {
      final setup = await _setup();
      final level = await setup.storyRepo.findLevelById('chapter_01_level_04');
      expect(level, isNotNull);
      expect(level!.matchObjectives, isNotEmpty);
    });
  });

  group('ClashStoryMapScreen Fase 49', () {
    testWidgets('muestra progreso y capítulo', (tester) async {
      final setup = await _setup();

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          child: const ClashStoryMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progreso'), findsOneWidget);
      expect(find.text('0/4 niveles'), findsWidgets);
      expect(find.text('Capítulo actual'), findsOneWidget);
      expect(find.text('Capítulo test'), findsWidgets);
    });

    testWidgets('muestra tipos story y match con estados', (tester) async {
      final setup = await _setup();
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          child: const ClashStoryMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Historia'), findsWidgets);
      expect(find.text('Partido'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Bloqueado'), findsWidgets);
      expect(find.text('Leer'), findsOneWidget);
      expect(find.text('Completa el nivel anterior'), findsWidgets);
    });

    testWidgets('muestra recompensas first clear y objetivos match', (
      tester,
    ) async {
      final setup = await _setup();
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          child: const ClashStoryMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primera vez'), findsWidgets);
      expect(find.text('Gemas'), findsWidgets);
      expect(find.text('×2'), findsWidgets);
      expect(find.text('Ganar el partido'), findsOneWidget);
    });

    testWidgets('nivel completado muestra Repetir', (tester) async {
      final setup = await _setup();
      await setup.storyRepo.completeStoryLevel('prologue-lvl-01');
      await setup.controller.load();

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          child: const ClashStoryMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completado'), findsOneWidget);
      expect(find.text('Leer de nuevo'), findsOneWidget);
    });

    testWidgets('no overflow en viewport móvil', (tester) async {
      final setup = await _setup();
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          child: const ClashStoryMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ClashStoryLevelReaderScreen Fase 49', () {
    testWidgets('muestra narrativa y rewards', (tester) async {
      final setup = await _setup();

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          cards: setup.cardsController,
          child: const ClashStoryLevelReaderScreen(levelId: 'prologue-lvl-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nivel 1'), findsOneWidget);
      expect(find.text('Capítulo test'), findsOneWidget);
      expect(find.text('Escena 1'), findsOneWidget);
      expect(find.text('Recompensas de primera vez'), findsOneWidget);
      expect(find.text('Volver al mapa'), findsOneWidget);
    });

    testWidgets('nivel bloqueado muestra mensaje', (tester) async {
      final setup = await _setup();

      await tester.pumpWidget(
        _storyApp(
          controller: setup.controller,
          cards: setup.cardsController,
          child: const ClashStoryLevelReaderScreen(levelId: 'prologue-lvl-02'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completa el nivel anterior'), findsOneWidget);
    });
  });

  group('ClashMatchPrepareScreen Fase 49', () {
    testWidgets('muestra CTA según alineación activa', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final incompleteSetup = await _setup();
      await _completePrologue(incompleteSetup.storyRepo);
      await incompleteSetup.controller.load();

      await tester.pumpWidget(
        _storyApp(
          controller: incompleteSetup.controller,
          lineups: incompleteSetup.lineupsController,
          child: const ClashMatchPrepareScreen(levelId: 'chapter_01_level_04'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Nivel match'), findsOneWidget);
      expect(find.text('Partido'), findsOneWidget);
      expect(find.text('Alineación activa incompleta'), findsOneWidget);
      expect(find.text('Ganar el partido'), findsOneWidget);
      expect(find.text('Preparar equipo'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final completeSetup = await _setup();
      await _completePrologue(completeSetup.storyRepo);
      await completeSetup.collectionRepo.grantCardIds(const [
        'c-gk',
        'c-cb',
        'c-fb',
        'c-dm',
        'c-am',
        'c-wg',
        'c-st',
      ]);
      await completeSetup.lineupsController.load();
      await _fillLineup(completeSetup.lineupsController);
      expect(completeSetup.lineupsController.activeLineup?.isComplete, isTrue);
      await completeSetup.controller.load();

      await tester.pumpWidget(
        _storyApp(
          controller: completeSetup.controller,
          lineups: completeSetup.lineupsController,
          child: const ClashMatchPrepareScreen(levelId: 'chapter_01_level_04'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Alineación activa completa'), findsOneWidget);
      final startButton = find.widgetWithText(FilledButton, 'Empezar partido');
      expect(startButton, findsOneWidget);
      final button = tester.widget<FilledButton>(startButton);
      expect(button.onPressed, isNotNull);
    });
  });
}

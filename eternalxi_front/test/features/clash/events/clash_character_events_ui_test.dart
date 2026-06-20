import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_local_datasource.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_detail_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_story_stage_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_events_screen.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

const _eventId = 'event-arin-training';
const _mikaEventId = 'event-mika-speed';
const _storyStageId = 'event-arin-stage-01';
const _matchStageId = 'event-arin-stage-02';
const _mikaStoryStageId = 'event-mika-stage-01';
const _mikaMatchStage2Id = 'event-mika-stage-02';
const _mikaMatchStage3Id = 'event-mika-stage-03';

class _EmptyEventsDataSource extends ClashCharacterEventsLocalDataSource {
  @override
  Future<List<ClashCharacterEvent>> loadEvents() async => const [];
}

const _lineupCardsJson = '''
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

class _LineupCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async {
    return parseCardsJson(_lineupCardsJson);
  }
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

Widget _eventsApp({
  required ClashCharacterEventsRepository eventsRepo,
  ClashCardsRepository? cardsRepo,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      Provider<ClashCharacterEventsRepository>.value(value: eventsRepo),
      if (cardsRepo != null)
        Provider<ClashCardsRepository>.value(value: cardsRepo),
    ],
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

  group('ClashEventsScreen Fase 50', () {
    testWidgets('muestra cabecera y evento Arin', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: cardsRepo,
          child: const ClashEventsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Eventos'), findsWidgets);
      expect(find.text('2 eventos disponibles'), findsOneWidget);
      expect(find.text('Eventos locales de prueba'), findsOneWidget);
      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      expect(find.text('Carrera de Mika'), findsOneWidget);
      expect(find.text('Fases completadas 0/3'), findsWidgets);
      expect(find.text('Carta destacada'), findsWidgets);
      expect(find.text('Entrar'), findsNWidgets(2));
    });

    testWidgets('botón Entrar navega al detalle', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ClashEventsScreen(),
          ),
          GoRoute(
            path: '/clash/events/:id',
            builder: (context, state) =>
                ClashEventDetailScreen(eventId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: setup.events),
            Provider<ClashCardsRepository>.value(value: cardsRepo),
          ],
          child: MaterialApp.router(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(find.text('Entrar').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Fases'), findsOneWidget);
      expect(find.text('Primer ejercicio'), findsOneWidget);
    });

    testWidgets('estado vacío sin eventos', (tester) async {
      final setup = await createTestEventsSetup();
      final emptyRepo = ClashCharacterEventsRepository(
        dataSource: _EmptyEventsDataSource(),
        storage: InMemoryClashCharacterEventsBackend(),
        storyRepository: setup.story,
        rewardGranter: createTestRewardGranter(
          storyRepository: setup.story,
          collectionRepository: setup.collection,
          ticketRepository: createTestTicketRepository(),
        ),
        collectionRepository: setup.collection,
      );

      await tester.pumpWidget(
        _eventsApp(eventsRepo: emptyRepo, child: const ClashEventsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('0 eventos disponibles'), findsOneWidget);
      expect(find.text('No hay eventos disponibles'), findsOneWidget);
    });
  });

  group('ClashEventDetailScreen Fase 50', () {
    testWidgets('muestra detalle fases y rewards', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: ClashCardsRepository(GachaTestCardsDataSource()),
          child: const ClashEventDetailScreen(eventId: _eventId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      expect(find.text('Arin'), findsOneWidget);
      expect(find.text('Carta destacada'), findsWidgets);
      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Partido 7vs7'), findsWidgets);
      expect(find.text('Primera vez'), findsWidgets);
      expect(find.text('Repetición'), findsWidgets);
      expect(find.text('Leer'), findsOneWidget);
      expect(find.text('Bloqueada'), findsWidgets);
    });

    testWidgets('fase completada muestra estado repetible', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: _eventId,
        stageId: _storyStageId,
      );

      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: ClashCardsRepository(GachaTestCardsDataSource()),
          child: const ClashEventDetailScreen(eventId: _eventId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Completada'), findsOneWidget);
      expect(find.text('Leer de nuevo'), findsOneWidget);
      expect(find.text('Preparar partido'), findsOneWidget);
    });
  });

  group('ClashEventStoryStageScreen Fase 50', () {
    testWidgets('muestra narrativa y primera victoria rewards', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          child: ClashEventStoryStageScreen(
            eventId: _eventId,
            stageId: _storyStageId,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      expect(find.text('Primer ejercicio'), findsOneWidget);
      expect(find.text('Historia'), findsOneWidget);
      expect(find.textContaining('Texto de prueba'), findsOneWidget);
      expect(find.text('Primera victoria'), findsOneWidget);
      expect(find.text('Completar'), findsOneWidget);
    });
  });

  group('ClashEventMatchPrepareScreen Fase 50', () {
    testWidgets('muestra rival rewards y CTA según lineup', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: _eventId,
        stageId: _storyStageId,
      );

      final cardsRepo = ClashCardsRepository(_LineupCardsDataSource());
      final lineups = ClashLineupsController(
        lineupsRepository: ClashLineupsRepository(
          storage: InMemoryClashLineupsBackend(),
          cardsRepository: cardsRepo,
        ),
        collectionRepository: createTestCollectionRepository(
          cardsRepository: cardsRepo,
        ),
      );
      await lineups.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: setup.events),
            ChangeNotifierProvider<ClashLineupsController>.value(
              value: lineups,
            ),
            Provider<ClashRivalsRepository>(
              create: (_) => ClashRivalsRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashEventMatchPrepareScreen(
              eventId: _eventId,
              stageId: _matchStageId,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Pachanga de entrenamiento'), findsOneWidget);
      expect(find.text('Grupo de Arin'), findsOneWidget);
      expect(find.text('Primera victoria'), findsOneWidget);
      expect(find.text('Repeticiones'), findsOneWidget);
      expect(find.text('EXP por carta'), findsOneWidget);
      expect(find.text('Preparar equipo'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await setup.collection.grantCardIds(const [
        'c-gk',
        'c-cb',
        'c-fb',
        'c-dm',
        'c-am',
        'c-wg',
        'c-st',
      ]);
      await lineups.load();
      await _fillLineup(lineups);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: setup.events),
            ChangeNotifierProvider<ClashLineupsController>.value(
              value: lineups,
            ),
            Provider<ClashRivalsRepository>(
              create: (_) => ClashRivalsRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashEventMatchPrepareScreen(
              eventId: _eventId,
              stageId: _matchStageId,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Alineación activa completa'), findsOneWidget);
      final startButton = find.widgetWithText(FilledButton, 'Empezar partido');
      expect(startButton, findsOneWidget);
      expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);
    });

    testWidgets('no overflow en viewport móvil', (tester) async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: _eventId,
        stageId: _storyStageId,
      );
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: setup.events),
            ChangeNotifierProvider<ClashLineupsController>(
              create: (_) => ClashLineupsController(
                lineupsRepository: ClashLineupsRepository(
                  storage: InMemoryClashLineupsBackend(),
                  cardsRepository: ClashCardsRepository(
                    _LineupCardsDataSource(),
                  ),
                ),
                collectionRepository: createTestCollectionRepository(
                  cardsRepository: ClashCardsRepository(
                    _LineupCardsDataSource(),
                  ),
                ),
              ),
            ),
            Provider<ClashRivalsRepository>(
              create: (_) => ClashRivalsRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashEventMatchPrepareScreen(
              eventId: _eventId,
              stageId: _matchStageId,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
    });
  });

  group('ClashEvents Fase 57 — Mika', () {
    testWidgets('detalle Mika muestra fases y carta destacada', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: ClashCardsRepository(GachaTestCardsDataSource()),
          child: const ClashEventDetailScreen(eventId: _mikaEventId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Carrera de Mika'), findsOneWidget);
      expect(find.text('Mika'), findsOneWidget);
      expect(find.text('Carta destacada'), findsWidgets);
      expect(find.text('Arranque rápido'), findsOneWidget);
      expect(find.text('Pases a toda velocidad'), findsOneWidget);
      expect(find.text('Rayo final'), findsOneWidget);
    });

    testWidgets('stage 03 Mika muestra repeat rewards', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: _mikaEventId,
        stageId: _mikaStoryStageId,
      );
      await setup.events.completeMatchStage(
        eventId: _mikaEventId,
        stageId: _mikaMatchStage2Id,
        userWon: true,
      );
      await setup.events.completeMatchStage(
        eventId: _mikaEventId,
        stageId: _mikaMatchStage3Id,
        userWon: true,
      );

      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: ClashCardsRepository(GachaTestCardsDataSource()),
          child: const ClashEventDetailScreen(eventId: _mikaEventId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Repetición'), findsWidgets);
      expect(find.text('Completada'), findsWidgets);
    });

    testWidgets('listado con 2 eventos no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: ClashCardsRepository(GachaTestCardsDataSource()),
          child: const ClashEventsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Carrera de Mika'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Carrera de Mika'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

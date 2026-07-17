import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_local_datasource.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_detail_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_reward_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_story_stage_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_events_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const eventId = 'event-arin-training';
  const storyStageId = 'event-arin-stage-01';
  const matchStageId = 'event-arin-stage-02';
  const matchStage3Id = 'event-arin-stage-03';

  group('ClashCharacterEventsLocalDataSource', () {
    test('carga character_events.json', () {
      final events = ClashCharacterEventsLocalDataSource().parseEventsJson(
        clashTestCharacterEventsJson,
      );
      expect(events, hasLength(2));
      expect(
        events.map((e) => e.id),
        containsAll([eventId, 'event-mika-speed']),
      );
    });
  });

  group('ClashCharacterEventsRepository', () {
    test('evento inicial disponible', () async {
      final setup = await createTestEventsSetup();
      final summaries = await setup.events.fetchEventSummaries();
      expect(summaries, hasLength(2));
      expect(summaries.every((s) => s.isAvailable), isTrue);
      expect(
        summaries.map((s) => s.event.title),
        containsAll(['Entrenamiento de Arin', 'Carrera de Mika']),
      );
    });

    test('story stage firstClear concede recompensa una vez', () async {
      final setup = await createTestEventsSetup();
      final before = setup.expMaterials.quantityFor('basic-training-manual');
      final first = await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      expect(first?.firstClear, isTrue);
      expect(setup.story.walletCoins(), 300);
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        before + 1,
      );
    });

    test('story stage repetida no duplica firstClear', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final second = await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      expect(second?.rewardsGranted.isEmpty, isTrue);
      expect(setup.story.walletCoins(), 300);
    });

    test('match stage derrota no concede recompensa', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final result = await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: false,
      );
      expect(result, isNull);
      expect(setup.story.walletGems(), 0);
    });

    test('match stage victoria concede firstClear', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final result = await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      expect(result?.firstClear, isTrue);
      expect(setup.story.walletGems(), 1);
      expect(
        setup.collection.loadOwnedCardIds().contains('exi-n-st-001'),
        isTrue,
      );
    });

    test('match stage repetida concede repeatRewards', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      final before = setup.expMaterials.quantityFor('basic-training-manual');
      final repeat = await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      expect(repeat?.firstClear, isFalse);
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        before + 1,
      );
    });

    test('clearCount incrementa', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      final state = await setup.events.loadState();
      expect(state.clearCounts[matchStageId], 2);
    });

    test('featured card primera vez se añade', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      expect(setup.collection.loadOwnedCardIds(), contains('exi-n-st-001'));
    });

    test('featured card repetida suma duplicado', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStage3Id,
        userWon: true,
      );
      final progress = setup.collection.loadCardProgress()['exi-n-st-001'];
      expect(progress?.duplicateCopies, 1);
    });

    test('progreso persiste', () async {
      final storage = InMemoryClashCharacterEventsBackend();
      final setup = await createTestEventsSetup(storage: storage);
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final stored = storage.readState();
      expect(stored?.completedStageIds.contains(storyStageId), isTrue);
    });

    test('cardXpReward se aplica al ganar match de evento', () async {
      final setup = await createTestEventsSetup();
      const cardId = 'gacha-card-a';
      await setup.collection.grantMissingCardIds([cardId]);
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final result = await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
        lineupCardIds: const [cardId],
      );
      expect(result?.cardXpResults, isNotEmpty);
      expect(result?.cardXpResults.first.xpGained, 60);
    });
  });

  group('ClashCharacterEventsRepository Fase 57 — Mika', () {
    const mikaEventId = 'event-mika-speed';
    const mikaStoryStageId = 'event-mika-stage-01';
    const mikaMatchStage2Id = 'event-mika-stage-02';
    const mikaMatchStage3Id = 'event-mika-stage-03';

    test('completar stage de Mika no completa Arin', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: mikaEventId,
        stageId: mikaStoryStageId,
      );
      final arinProgress = await setup.events.fetchStageProgress(eventId);
      final mikaProgress = await setup.events.fetchStageProgress(mikaEventId);
      expect(
        mikaProgress
            .firstWhere((p) => p.stage.id == mikaStoryStageId)
            .status,
        ClashCharacterEventStageStatus.completed,
      );
      expect(
        arinProgress
            .firstWhere((p) => p.stage.id == storyStageId)
            .status,
        isNot(ClashCharacterEventStageStatus.completed),
      );
    });

    test('story firstClear Mika idempotente', () async {
      final setup = await createTestEventsSetup();
      final first = await setup.events.completeStoryStage(
        eventId: mikaEventId,
        stageId: mikaStoryStageId,
      );
      expect(first?.firstClear, isTrue);
      expect(setup.story.walletCoins(), 400);
      final second = await setup.events.completeStoryStage(
        eventId: mikaEventId,
        stageId: mikaStoryStageId,
      );
      expect(second?.rewardsGranted.isEmpty, isTrue);
      expect(setup.story.walletCoins(), 400);
    });

    test('match firstClear y repeat Mika funcionan', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: mikaEventId,
        stageId: mikaStoryStageId,
      );
      final first = await setup.events.completeMatchStage(
        eventId: mikaEventId,
        stageId: mikaMatchStage2Id,
        userWon: true,
      );
      expect(first?.firstClear, isTrue);
      expect(setup.story.walletGems(), 1);
      expect(setup.collection.loadOwnedCardIds(), contains('exi-n-wg-001'));
      final coinsBefore = setup.story.walletCoins();
      final repeat = await setup.events.completeMatchStage(
        eventId: mikaEventId,
        stageId: mikaMatchStage2Id,
        userWon: true,
      );
      expect(repeat?.firstClear, isFalse);
      expect(setup.story.walletCoins(), coinsBefore + 250);
    });

    test('match stages referencian rival-mika-speed', () async {
      final setup = await createTestEventsSetup();
      final stage2 = await setup.events.findStage(
        mikaEventId,
        mikaMatchStage2Id,
      );
      final stage3 = await setup.events.findStage(
        mikaEventId,
        mikaMatchStage3Id,
      );
      expect(stage2?.title, 'Pases a toda velocidad');
      expect(stage2?.rivalTeamId, 'rival-mika-speed');
      expect(stage3?.rivalTeamId, 'rival-mika-speed');
    });

    test('stage 03 repeat concede libro de técnica', () async {
      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: mikaEventId,
        stageId: mikaStoryStageId,
      );
      await setup.events.completeMatchStage(
        eventId: mikaEventId,
        stageId: mikaMatchStage2Id,
        userWon: true,
      );
      await setup.events.completeMatchStage(
        eventId: mikaEventId,
        stageId: mikaMatchStage3Id,
        userWon: true,
      );
      final before = setup.techniqueBooks.quantityFor('basic-technique-book');
      final repeat = await setup.events.completeMatchStage(
        eventId: mikaEventId,
        stageId: mikaMatchStage3Id,
        userWon: true,
      );
      expect(repeat?.firstClear, isFalse);
      expect(
        setup.techniqueBooks.quantityFor('basic-technique-book'),
        before + 1,
      );
    });
  });

  group('ClashCharacterEvents UI', () {
    Future<Widget> eventsListApp(ClashCharacterEventsRepository repo) async {
      final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            Provider<ClashCharacterEventsRepository>.value(value: repo),
            Provider<ClashCardsRepository>.value(value: cardsRepo),
          ],
          child: const ClashEventsScreen(),
        ),
      );
    }

    Future<Widget> homeApp(ClashCharacterEventsRepository repo) async {
      final setup = await createTestEventsSetup();
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashStoryController>(
              create: (_) => ClashStoryController(storyRepository: setup.story),
            ),
            Provider<ClashCharacterEventsRepository>.value(value: repo),
          ],
          child: const ClashHomeScreen(),
        ),
      );
    }

    testWidgets(
      'Home muestra tarjeta Eventos',
      (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(await homeApp(setup.events));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Eventos'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Eventos'), findsOneWidget);
    },
      skip: 'Inicio vacío temporalmente',
    );

    testWidgets('/clash/events muestra evento', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(await eventsListApp(setup.events));
      await tester.pumpAndSettle();
      expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      expect(find.text('Carrera de Mika'), findsOneWidget);
    });

    testWidgets('entrar al evento muestra fases', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Provider<ClashCharacterEventsRepository>.value(
            value: setup.events,
            child: ClashEventDetailScreen(eventId: eventId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Primer ejercicio'), findsOneWidget);
      expect(find.text('Pachanga de entrenamiento'), findsOneWidget);
    });

    testWidgets('story stage muestra texto y completar', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Provider<ClashCharacterEventsRepository>.value(
            value: setup.events,
            child: ClashEventStoryStageScreen(
              eventId: eventId,
              stageId: storyStageId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Texto de prueba'), findsOneWidget);
      expect(find.text('Completar'), findsOneWidget);
    });

    testWidgets('completar story muestra recompensa', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Provider<ClashCharacterEventsRepository>.value(
            value: setup.events,
            child: ClashEventStoryStageScreen(
              eventId: eventId,
              stageId: storyStageId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completar'));
      await tester.pumpAndSettle();
      expect(find.text('Recompensas'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('lineup incompleta avisa', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final cardsRepo = ClashCardsRepository(_EmptyCardsDataSource());
      final lineupsRepo = ClashLineupsRepository(
        storage: InMemoryClashLineupsBackend(),
        cardsRepository: cardsRepo,
      );
      final lineups = ClashLineupsController(
        lineupsRepository: lineupsRepo,
        collectionRepository: createTestCollectionRepository(
          cardsRepository: cardsRepo,
        ),
      );
      await lineups.load();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MultiProvider(
            providers: [
              Provider<ClashCharacterEventsRepository>.value(
                value: setup.events,
              ),
              ChangeNotifierProvider<ClashLineupsController>.value(
                value: lineups,
              ),
              Provider<ClashRivalsRepository>(
                create: (_) => ClashRivalsRepository(),
              ),
            ],
            child: ClashEventMatchPrepareScreen(
              eventId: eventId,
              stageId: matchStageId,
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Alineación activa incompleta').evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.text('Alineación activa incompleta'), findsOneWidget);
      expect(find.text('Preparar equipo'), findsOneWidget);
      final start = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Empezar partido'),
      );
      expect(start.onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('victoria de evento muestra recompensas', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MultiProvider(
            providers: [
              Provider<ClashCharacterEventsRepository>.value(
                value: setup.events,
              ),
              Provider<ClashCardsRepository>(
                create: (_) => ClashCardsRepository(GachaTestCardsDataSource()),
              ),
            ],
            child: const ClashEventRewardScreen(
              eventId: eventId,
              stageId: matchStageId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('¡Primera victoria!'), findsOneWidget);
    });

    testWidgets('repeat stage muestra recompensas repeat', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );
      await setup.events.completeMatchStage(
        eventId: eventId,
        stageId: matchStageId,
        userWon: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Provider<ClashCharacterEventsRepository>.value(
            value: setup.events,
            child: const ClashEventRewardScreen(
              eventId: eventId,
              stageId: matchStageId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recompensa de repetición'), findsOneWidget);
    });
  });
}

class _EmptyCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [];
}

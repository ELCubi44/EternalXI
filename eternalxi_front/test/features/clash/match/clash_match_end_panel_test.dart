import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_goal_details.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_requirements.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _objectives = [
  ClashMatchObjective(
    id: 'win_match',
    type: ClashMatchObjectiveType.winMatch,
    title: 'Ganar el partido',
    description: 'Gana el partido.',
    isMandatory: true,
  ),
  ClashMatchObjective(
    id: 'clean_sheet',
    type: ClashMatchObjectiveType.cleanSheet,
    title: 'Ganar sin recibir goles',
    description: 'Sin goles en contra.',
    rewards: ClashStoryReward(gems: 1),
  ),
  ClashMatchObjective(
    id: 'shot_technique_goal',
    type: ClashMatchObjectiveType.scoreWithShotTechnique,
    title: 'Marcar con supertécnica de Tiro',
    description: 'Gol con técnica de tiro.',
    rewards: ClashStoryReward(
      items: [
        ClashStoryItemReward(
          id: 'basic-book',
          name: 'Libro básico',
          quantity: 1,
        ),
      ],
    ),
  ),
];

const _matchLevel = ClashStoryLevel(
  id: 'chapter_01_level_04',
  chapterId: 'chapter-01',
  title: 'La primera pachanga',
  description: 'Tutorial match',
  order: 4,
  type: ClashStoryLevelType.match,
  energyCost: 8,
  recommendedPower: 120,
  rewards: ClashStoryReward(gems: 1, coins: 500),
  scenes: [],
  requirements: ClashStoryLevelRequirements(
    clashTeamUnlocked: true,
    completeActiveLineup: true,
  ),
  matchObjectives: _objectives,
);

MatchState _finishedState({
  required MatchScore score,
  List<MatchEvent> eventLog = const [],
}) {
  return MatchState.testing(
    score: score,
    status: MatchStatus.finished,
  ).copyWith(eventLog: eventLog);
}

MatchEvent _userGoalEvent({
  ClashTechniqueType? techniqueType,
  bool usedTechnique = false,
}) {
  return MatchEvent(
    type: MatchEventType.goal,
    message: 'Gol Eternal XI',
    goalDetails: MatchGoalDetails(
      scorer: MatchTeamSide.user,
      usedTechnique: usedTechnique,
      techniqueType: techniqueType,
    ),
  );
}

Widget _storyEndPanel({
  required MatchState state,
  List<ClashMatchObjectiveProgress> objectiveResults = const [],
  ClashStoryReward previewRewards = const ClashStoryReward(),
  List<ClashCardXpResult> previewCardXp = const [],
  VoidCallback? onViewRewards,
  VoidCallback? onRetry,
  VoidCallback? onBackToMap,
}) {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClashMatchEndPanel(
            state: state,
            level: _matchLevel,
            objectiveResults: objectiveResults,
            previewRewards: previewRewards,
            previewCardXp: previewCardXp,
            onViewRewards: onViewRewards ?? () {},
            onRetry: onRetry ?? () {},
            onBackToMap: onBackToMap ?? () {},
          ),
        ],
      ),
    ),
  );
}

Widget _eventEndPanel({
  required MatchState state,
  ClashCharacterEventReward previewReward = const ClashCharacterEventReward(),
  List<ClashCardXpResult> previewCardXp = const [],
}) {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClashEventMatchEndPanel(
            state: state,
            stageTitle: 'Fase 1',
            previewReward: previewReward,
            previewCardXp: previewCardXp,
            onViewRewards: () {},
            onRetry: () {},
            onBack: () {},
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('ClashMatchEndPanel story Fase 48', () {
    testWidgets('victoria muestra encabezado, marcador y objetivo principal', (
      tester,
    ) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          objectiveResults: results,
          previewRewards: const ClashStoryReward(gems: 1, coins: 500),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(find.text('Tú 3 - 1 Rival'), findsOneWidget);
      expect(find.text('Objetivo: primero a 3 goles'), findsOneWidget);
      expect(find.text('Partido completado'), findsOneWidget);
    });

    testWidgets('derrota muestra encabezado y sin recompensas', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 1, rival: 3));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: false,
      );

      await tester.pumpWidget(
        _storyEndPanel(state: state, objectiveResults: results),
      );
      await tester.pumpAndSettle();

      expect(find.text('Derrota'), findsOneWidget);
      expect(find.text('Tú 1 - 3 Rival'), findsOneWidget);
      expect(find.text('No se obtuvieron recompensas'), findsOneWidget);
      expect(find.text('Recompensas obtenidas'), findsNothing);
      expect(find.text('Continuar'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Volver al mapa'), findsOneWidget);
    });

    testWidgets('objetivos completados y no completados visibles', (
      tester,
    ) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          objectiveResults: results,
          previewRewards: const ClashStoryReward(gems: 1, coins: 500),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Objetivos'), findsOneWidget);
      expect(find.text('Completado'), findsWidgets);
      expect(find.text('No completado'), findsWidgets);
      expect(find.text('Encajaste un gol'), findsOneWidget);
    });

    testWidgets('victoria muestra recompensas obtenidas', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );
      final preview = ClashMatchObjectiveEvaluator.rewardsToGrant(
        levelId: _matchLevel.id,
        baseVictoryReward: _matchLevel.rewards,
        objectiveResults: results,
        grantBaseVictory: true,
        progress: const ClashStoryProgress(),
      );

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          objectiveResults: results,
          previewRewards: preview,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recompensas obtenidas'), findsOneWidget);
      expect(find.text('Gemas'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('Monedas'), findsOneWidget);
      expect(find.text('×500'), findsOneWidget);
    });

    testWidgets('objetivos fallidos muestran recompensas pendientes', (
      tester,
    ) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          objectiveResults: results,
          previewRewards: const ClashStoryReward(gems: 1, coins: 500),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recompensas pendientes'), findsOneWidget);
      expect(
        find.text('Completa el objetivo en otro intento para conseguirlas.'),
        findsOneWidget,
      );
      expect(find.text('Ganar sin recibir goles'), findsOneWidget);
    });

    testWidgets('muestra progreso de cartas con level up', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));
      const xpResults = [
        ClashCardXpResult(
          cardId: 'card-1',
          cardName: 'Delantero',
          previousLevel: 1,
          newLevel: 2,
          previousXp: 0,
          newXp: 40,
          xpGained: 80,
          didLevelUp: true,
          reachedMaxLevel: false,
        ),
      ];

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          previewRewards: const ClashStoryReward(gems: 1),
          previewCardXp: xpResults,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progreso de cartas'), findsOneWidget);
      expect(find.text('Delantero'), findsOneWidget);
      expect(find.text('+80 EXP'), findsOneWidget);
      expect(find.text('Nv. 1 → 2'), findsOneWidget);
    });

    testWidgets('victoria muestra Continuar, Reintentar y Volver', (
      tester,
    ) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));

      await tester.pumpWidget(_storyEndPanel(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Volver al mapa'), findsOneWidget);
    });

    testWidgets('panel scrollea sin overflow en viewport pequeño', (
      tester,
    ) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );
      const xpResults = [
        ClashCardXpResult(
          cardId: 'c1',
          cardName: 'A',
          previousLevel: 1,
          newLevel: 2,
          previousXp: 0,
          newXp: 30,
          xpGained: 80,
          didLevelUp: true,
          reachedMaxLevel: false,
        ),
        ClashCardXpResult(
          cardId: 'c2',
          cardName: 'B',
          previousLevel: 3,
          newLevel: 3,
          previousXp: 10,
          newXp: 50,
          xpGained: 40,
          didLevelUp: false,
          reachedMaxLevel: false,
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(360, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          objectiveResults: results,
          previewRewards: const ClashStoryReward(gems: 2, coins: 500),
          previewCardXp: xpResults,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Volver al mapa'), findsOneWidget);
    });
  });

  group('ClashEventMatchEndPanel Fase 48', () {
    testWidgets('first clear muestra recompensas', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));

      await tester.pumpWidget(
        _eventEndPanel(
          state: state,
          previewReward: const ClashCharacterEventReward(
            gems: 5,
            coins: 200,
            expMaterial: ClashAchievementItemReward(
              id: 'exp-small',
              quantity: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recompensas obtenidas'), findsOneWidget);
      expect(find.text('Gemas'), findsOneWidget);
      expect(find.text('×5'), findsOneWidget);
      expect(find.text('Monedas'), findsOneWidget);
      expect(find.text('×200'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('derrota no muestra recompensas', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 0, rival: 3));

      await tester.pumpWidget(
        _eventEndPanel(
          state: state,
          previewReward: const ClashCharacterEventReward(gems: 5),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Derrota'), findsOneWidget);
      expect(find.text('No se obtuvieron recompensas'), findsOneWidget);
      expect(find.text('Recompensas obtenidas'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('sin objetivos no muestra sección Objetivos', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));

      await tester.pumpWidget(
        _eventEndPanel(
          state: state,
          previewReward: const ClashCharacterEventReward(coins: 100),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Objetivos'), findsNothing);
    });

    testWidgets('victoria muestra XP de cartas', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));
      const xpResults = [
        ClashCardXpResult(
          cardId: 'ev-card',
          cardName: 'Evento',
          previousLevel: 2,
          newLevel: 2,
          previousXp: 20,
          newXp: 60,
          xpGained: 40,
          didLevelUp: false,
          reachedMaxLevel: false,
        ),
      ];

      await tester.pumpWidget(
        _eventEndPanel(
          state: state,
          previewReward: const ClashCharacterEventReward(coins: 50),
          previewCardXp: xpResults,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progreso de cartas'), findsOneWidget);
      expect(find.text('Evento'), findsOneWidget);
      expect(find.text('+40 EXP'), findsOneWidget);
    });

    testWidgets('objetivo supertécnica cumplido sin hint de fallo', (
      tester,
    ) async {
      final state = _finishedState(
        score: const MatchScore(user: 3, rival: 0),
        eventLog: [
          _userGoalEvent(
            techniqueType: ClashTechniqueType.shot,
            usedTechnique: true,
          ),
        ],
      );
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      await tester.pumpWidget(
        _storyEndPanel(
          state: state,
          objectiveResults: results,
          previewRewards: const ClashStoryReward(gems: 2, coins: 500),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marcar con supertécnica de Tiro'), findsOneWidget);
      expect(find.text('No marcaste con técnica de tiro'), findsNothing);
    });
  });
}

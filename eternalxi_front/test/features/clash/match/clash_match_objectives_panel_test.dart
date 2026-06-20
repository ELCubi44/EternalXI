import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_live_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_live_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_goal_details.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objectives_panel.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_requirements.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
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

const _advancedObjective = ClashMatchObjective(
  id: 'win_dribble',
  type: ClashMatchObjectiveType.winDribbleDuel,
  title: 'Ganar duelo de regate',
  description: 'Gana un duelo ofensivo.',
  rewards: ClashStoryReward(coins: 100),
);

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

MatchState _playingState({MatchScore score = const MatchScore()}) {
  return MatchState.testing(score: score, status: MatchStatus.playing);
}

MatchState _finishedState({
  required MatchScore score,
  List<MatchEvent> eventLog = const [],
}) {
  return MatchState.testing(
    score: score,
    status: MatchStatus.finished,
  ).copyWith(eventLog: eventLog);
}

MatchEvent _userShotTechniqueGoal() {
  return MatchEvent(
    type: MatchEventType.goal,
    message: 'Gol con técnica',
    goalDetails: MatchGoalDetails(
      scorer: MatchTeamSide.user,
      usedTechnique: true,
      techniqueType: ClashTechniqueType.shot,
    ),
  );
}

Widget _panel(List<ClashMatchObjective> objectives, MatchState state) {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(360, 740)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: ClashMatchObjectivesPanel(
            objectives: objectives,
            state: state,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ClashMatchObjectiveLiveResolver', () {
    test('cleanSheet en progreso con 0 goles rivales', () {
      final status = ClashMatchObjectiveLiveResolver.resolve(
        objective: _objectives[1],
        state: _playingState(),
      );
      expect(status, ClashMatchObjectiveLiveStatus.inProgress);
    });

    test('cleanSheet fallido si rival marcó', () {
      final status = ClashMatchObjectiveLiveResolver.resolve(
        objective: _objectives[1],
        state: _playingState(score: const MatchScore(user: 1, rival: 1)),
      );
      expect(status, ClashMatchObjectiveLiveStatus.failed);
    });

    test('scoreWithShotTechnique cumplido con gol técnico', () {
      final status = ClashMatchObjectiveLiveResolver.resolve(
        objective: _objectives[2],
        state: _playingState().copyWith(eventLog: [_userShotTechniqueGoal()]),
      );
      expect(status, ClashMatchObjectiveLiveStatus.completed);
    });

    test('tipo no live devuelve reviewedAtEnd', () {
      final status = ClashMatchObjectiveLiveResolver.resolve(
        objective: _advancedObjective,
        state: _playingState(),
      );
      expect(status, ClashMatchObjectiveLiveStatus.reviewedAtEnd);
    });
  });

  group('ClashMatchObjectivesPanel', () {
    testWidgets('no se muestra si no hay objetivos', (tester) async {
      await tester.pumpWidget(_panel(const [], _playingState()));
      await tester.pumpAndSettle();
      expect(find.text('Objetivos'), findsNothing);
      expect(find.byType(ClashMatchObjectivesPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('muestra objetivos del nivel story 4', (tester) async {
      await tester.pumpWidget(_panel(_objectives, _playingState()));
      await tester.pumpAndSettle();

      expect(find.text('Objetivos'), findsOneWidget);
      expect(find.text('Ganar sin recibir goles'), findsOneWidget);
      expect(find.text('Marcar con supertécnica de Tiro'), findsOneWidget);
      expect(find.textContaining('Gemas ×1'), findsOneWidget);
    });

    testWidgets('cleanSheet aparece En progreso', (tester) async {
      await tester.pumpWidget(_panel(_objectives, _playingState()));
      await tester.pumpAndSettle();
      expect(find.text('En progreso'), findsWidgets);
    });

    testWidgets('cleanSheet aparece Fallido si rival marcó', (tester) async {
      await tester.pumpWidget(
        _panel(
          _objectives,
          _playingState(score: const MatchScore(user: 2, rival: 1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fallido'), findsOneWidget);
    });

    testWidgets('scoreWithShotTechnique aparece Cumplido con técnica', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panel(
          _objectives,
          _playingState().copyWith(eventLog: [_userShotTechniqueGoal()]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cumplido'), findsOneWidget);
    });

    testWidgets('objetivo no evaluable muestra Se revisa al final', (
      tester,
    ) async {
      await tester.pumpWidget(_panel([_advancedObjective], _playingState()));
      await tester.pumpAndSettle();
      expect(find.text('Se revisa al final'), findsOneWidget);
    });

    testWidgets('event match sin objetivos no muestra panel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ClashMatchObjectivesPanel(
            objectives: const [],
            state: _playingState(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Objetivos'), findsNothing);
      expect(find.text('Sin objetivos secundarios'), findsNothing);
    });

    testWidgets('placeholder vacío opcional', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ClashMatchObjectivesPanel(
            objectives: const [],
            state: _playingState(),
            showEmptyPlaceholder: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin objetivos secundarios'), findsOneWidget);
    });

    testWidgets('no rompe viewport móvil', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_panel(_objectives, _playingState()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('end panel sigue mostrando objetivos', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: results,
              previewRewards: const ClashStoryReward(gems: 1, coins: 500),
              previewCardXp: const [],
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Objetivos'), findsOneWidget);
      expect(find.text('Completado'), findsWidgets);
      expect(find.text('No completado'), findsWidgets);
    });
  });
}

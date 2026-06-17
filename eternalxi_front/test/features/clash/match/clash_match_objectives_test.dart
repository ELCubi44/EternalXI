import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_goal_details.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objectives_card.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
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
  rewards: ClashStoryReward(
    gems: 1,
    coins: 500,
    items: [
      ClashStoryItemReward(
        id: 'practice-ball',
        name: 'Balón de práctica',
        quantity: 1,
      ),
    ],
  ),
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

void main() {
  group('ClashMatchObjectiveEvaluator', () {
    test('winMatch se cumple con victoria', () {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      expect(
        results.firstWhere((r) => r.objectiveId == 'win_match').completed,
        isTrue,
      );
    });

    test('winMatch no se cumple con derrota', () {
      final state = _finishedState(score: const MatchScore(user: 1, rival: 3));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: false,
      );

      expect(
        results.firstWhere((r) => r.objectiveId == 'win_match').completed,
        isFalse,
      );
    });

    test('cleanSheet se cumple con victoria 3-0', () {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      expect(
        results.firstWhere((r) => r.objectiveId == 'clean_sheet').completed,
        isTrue,
      );
    });

    test('cleanSheet no se cumple con 3-1', () {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      expect(
        results.firstWhere((r) => r.objectiveId == 'clean_sheet').completed,
        isFalse,
      );
    });

    test('scoreWithShotTechnique se cumple si gol usa técnica shot', () {
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

      expect(
        results
            .firstWhere((r) => r.objectiveId == 'shot_technique_goal')
            .completed,
        isTrue,
      );
    });

    test('scoreWithShotTechnique no se cumple con tiro normal', () {
      final state = _finishedState(
        score: const MatchScore(user: 3, rival: 0),
        eventLog: [_userGoalEvent()],
      );
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
      );

      expect(
        results
            .firstWhere((r) => r.objectiveId == 'shot_technique_goal')
            .completed,
        isFalse,
      );
    });

    test('derrota no entrega recompensas', () {
      const progress = ClashStoryProgress();
      final state = _finishedState(score: const MatchScore(user: 1, rival: 3));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: false,
        progress: progress,
      );

      final rewards = ClashMatchObjectiveEvaluator.rewardsToGrant(
        levelId: _matchLevel.id,
        baseVictoryReward: _matchLevel.rewards,
        objectiveResults: results,
        grantBaseVictory: false,
        progress: progress,
      );

      expect(rewards.isEmpty, isTrue);
    });

    test('victoria entrega recompensa base', () {
      const progress = ClashStoryProgress();
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
        progress: progress,
      );

      final rewards = ClashMatchObjectiveEvaluator.rewardsToGrant(
        levelId: _matchLevel.id,
        baseVictoryReward: _matchLevel.rewards,
        objectiveResults: results,
        grantBaseVictory: true,
        progress: progress,
      );

      expect(rewards.gems, 1);
      expect(rewards.coins, 500);
      expect(rewards.items.length, 1);
    });

    test('objetivo cumplido entrega recompensa extra', () {
      const progress = ClashStoryProgress();
      final state = _finishedState(score: const MatchScore(user: 3, rival: 0));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
        progress: progress,
      );

      final rewards = ClashMatchObjectiveEvaluator.rewardsToGrant(
        levelId: _matchLevel.id,
        baseVictoryReward: _matchLevel.rewards,
        objectiveResults: results,
        grantBaseVictory: true,
        progress: progress,
      );

      expect(rewards.gems, 2);
    });

    test('objetivo no cumplido no entrega recompensa', () {
      const progress = ClashStoryProgress();
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: true,
        progress: progress,
      );

      final rewards = ClashMatchObjectiveEvaluator.rewardsToGrant(
        levelId: _matchLevel.id,
        baseVictoryReward: _matchLevel.rewards,
        objectiveResults: results,
        grantBaseVictory: true,
        progress: progress,
      );

      expect(rewards.gems, 1);
    });
  });

  group('ClashStoryRepository objetivos', () {
    Future<ClashStoryRepository> repo(
      InMemoryClashStoryProgressBackend storage,
    ) async {
      final cardsRepo = ClashCardsRepository(_EmptyCardsDataSource());
      final collectionRepo = ClashPlayerCollectionRepository(
        storage: InMemoryClashPlayerCollectionBackend(),
        cardsRepository: cardsRepo,
      );
      return ClashStoryRepository(
        dataSource: ClashStoryLocalDataSource(),
        progressStorage: storage,
        collectionRepository: collectionRepo,
      );
    }

    Future<void> completePrologue(ClashStoryRepository storyRepo) async {
      await storyRepo.completeStoryLevel('prologue-lvl-01');
      await storyRepo.completeStoryLevel('prologue-lvl-02');
      await storyRepo.completeStoryLevel('prologue-lvl-03');
    }

    test('repetir nivel no duplica recompensa base', () async {
      final storage = InMemoryClashStoryProgressBackend();
      final storyRepo = await repo(storage);
      await completePrologue(storyRepo);

      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));

      final first = await storyRepo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: state,
      );
      final second = await storyRepo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: state,
      );

      expect(first.rewardsGranted.gems, 1);
      expect(second.rewardsGranted.gems, 0);
      expect(second.rewardsGranted.coins, 0);
    });

    test('repetir nivel puede reclamar objetivo pendiente nuevo', () async {
      final storage = InMemoryClashStoryProgressBackend();
      final storyRepo = await repo(storage);
      await completePrologue(storyRepo);

      final firstWin = _finishedState(
        score: const MatchScore(user: 3, rival: 1),
      );
      await storyRepo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: firstWin,
      );

      final cleanSheetWin = _finishedState(
        score: const MatchScore(user: 3, rival: 0),
      );
      final retry = await storyRepo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: cleanSheetWin,
      );

      expect(retry.rewardsGranted.gems, 1);
      expect(retry.firstCompletion, isFalse);
    });
  });

  group('UI objetivos match', () {
    testWidgets('prepare muestra objetivos del nivel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchObjectivesCard(objectives: _objectives),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Objetivos'), findsOneWidget);
      expect(find.text('Ganar sin recibir goles'), findsOneWidget);
      expect(find.text('Marcar con supertécnica de Tiro'), findsOneWidget);
    });

    testWidgets('victoria muestra objetivos cumplidos/no cumplidos', (
      tester,
    ) async {
      final state = _finishedState(score: const MatchScore(user: 3, rival: 1));
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
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: results,
              previewRewards: preview,
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

    testWidgets('derrota muestra mensaje de no recompensas', (tester) async {
      final state = _finishedState(score: const MatchScore(user: 1, rival: 3));
      final results = ClashMatchObjectiveEvaluator.evaluate(
        objectives: _objectives,
        state: state,
        userWon: false,
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
              previewRewards: const ClashStoryReward(),
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Debes ganar el partido para recibir recompensas de objetivos',
        ),
        findsOneWidget,
      );
      expect(find.text('Ver recompensas'), findsNothing);
    });

    testWidgets('objetivo cleanSheet aparece como fallido si rival marcó', (
      tester,
    ) async {
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
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ganar sin recibir goles'), findsOneWidget);
      expect(find.text('No completado'), findsWidgets);
    });

    testWidgets('objetivo supertécnica aparece cumplido si corresponde', (
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
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: results,
              previewRewards: const ClashStoryReward(gems: 2, coins: 500),
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marcar con supertécnica de Tiro'), findsOneWidget);
      expect(find.textContaining('Completado'), findsWidgets);
    });

    testWidgets('recompensas totales aparecen en resumen', (tester) async {
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
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: results,
              previewRewards: preview,
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total obtenido'), findsOneWidget);
      expect(find.text('Gemas: +2'), findsOneWidget);
      expect(find.text('Monedas: +500'), findsOneWidget);
    });
  });
}

class _EmptyCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [];
}

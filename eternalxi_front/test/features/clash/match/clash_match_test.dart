import 'dart:math';

import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_prepare_validation.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_completion_unlocks.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_requirements.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cards/clash_test_support.dart';

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
);

ClashLineup7v7 _completeLineup() {
  final slots = {
    for (final position in ClashPosition.values)
      position: 'card-${position.toJson()}',
  };
  return ClashLineup7v7(
    id: 'lineup-1',
    name: 'Titular',
    isActive: true,
    slots: slots,
    lastModifiedAt: DateTime(2026),
  );
}

ClashLineup7v7 _incompleteLineup() {
  final slots = {
    for (final position in ClashPosition.values) position: null as String?,
  };
  slots[ClashPosition.goalkeeper] = 'gk-1';
  return ClashLineup7v7(
    id: 'lineup-1',
    name: 'Titular',
    isActive: true,
    slots: slots,
    lastModifiedAt: DateTime(2026),
  );
}

MatchState _playingState({MatchScore score = const MatchScore()}) {
  return MatchState.testing(score: score);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashMatchPrepareValidation', () {
    const progressUnlocked = ClashStoryProgress(
      unlocks: ClashStoryCompletionUnlocks(clashTeamUnlocked: true),
    );

    test('detecta alineación incompleta', () {
      final validation = ClashMatchPrepareValidation.evaluate(
        level: _matchLevel,
        progress: progressUnlocked,
        activeLineup: _incompleteLineup(),
        lineupPower: 50,
      );

      expect(validation.hasCompleteActiveLineup, isFalse);
      expect(validation.canStart, isFalse);
    });

    test('permite comenzar con alineación completa', () {
      final validation = ClashMatchPrepareValidation.evaluate(
        level: _matchLevel,
        progress: progressUnlocked,
        activeLineup: _completeLineup(),
        lineupPower: 150,
      );

      expect(validation.hasCompleteActiveLineup, isTrue);
      expect(validation.canStart, isTrue);
    });

    test('avisa si potencia menor a recomendada sin bloquear', () {
      final validation = ClashMatchPrepareValidation.evaluate(
        level: _matchLevel,
        progress: progressUnlocked,
        activeLineup: _completeLineup(),
        lineupPower: 80,
      );

      expect(validation.powerBelowRecommended, isTrue);
      expect(validation.canStart, isTrue);
    });
  });

  group('ClashMatchController', () {
    test('coin toss asigna saque inicial', () {
      final controller = ClashMatchController(random: Random(1));
      controller.startMatch(levelId: 'chapter_01_level_04');
      controller.chooseCoinToss(CoinTossChoice.heads);

      final state = controller.state!;
      expect(state.status, MatchStatus.playing);
      expect(state.coinToss, isNotNull);
      expect(state.possession, state.coinToss!.kickoffSide);
    });

    test('después de gol saca el equipo que recibió gol', () {
      final controller = ClashMatchController(random: Random(1));
      controller.startMatch(levelId: 'chapter_01_level_04');
      controller.chooseCoinToss(CoinTossChoice.heads);

      final kickoff = controller.state!.possession;
      controller.simulateUserGoal();

      expect(controller.state!.possession, kickoff.opposite());
    });

    test('gana el primero que llega a 3', () {
      final controller = ClashMatchController(random: Random(1));
      controller.startMatch(levelId: 'chapter_01_level_04');
      controller.chooseCoinToss(CoinTossChoice.heads);

      controller.simulateUserGoal();
      controller.simulateUserGoal();
      expect(controller.state!.isFinished, isFalse);
      expect(controller.state!.isPausedForHalftime, isTrue);

      controller.continueFromHalftime();
      expect(controller.state!.status, MatchStatus.playing);

      controller.simulateUserGoal();
      expect(controller.state!.isFinished, isTrue);
      expect(controller.state!.winner, MatchTeamSide.user);
      expect(controller.state!.score.user, MatchScore.winTarget);
    });
  });

  group('MatchRules', () {
    test('applyGoal marca fin al llegar a 3', () {
      final state = _playingState(score: const MatchScore(user: 2, rival: 1));
      final next = MatchRules.applyGoal(state, MatchTeamSide.user);

      expect(next.isFinished, isTrue);
      expect(next.score.user, 3);
    });
  });

  group('ClashStoryRepository match completion', () {
    Future<ClashStoryRepository> repo() async {
      final cardsRepo = ClashCardsRepository(_EmptyCardsDataSource());
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
      );
      return ClashStoryRepository(
        dataSource: ClashStoryLocalDataSource(),
        progressStorage: InMemoryClashStoryProgressBackend(),
        collectionRepository: collectionRepo,
      );
    }

    Future<void> completePrologue(ClashStoryRepository repo) async {
      await repo.completeStoryLevel('prologue-lvl-01');
      await repo.completeStoryLevel('prologue-lvl-02');
      await repo.completeStoryLevel('prologue-lvl-03');
    }

    test('victoria completa nivel y entrega recompensas', () async {
      final storyRepo = await repo();
      await completePrologue(storyRepo);

      final result = await storyRepo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: MatchState.testing(
          score: const MatchScore(user: 3, rival: 1),
          status: MatchStatus.finished,
        ),
      );

      expect(result.firstCompletion, isTrue);
      expect(result.rewardsGranted.gems, 1);
      expect(
        storyRepo.loadProgress().isLevelCompleted('chapter_01_level_04'),
        isTrue,
      );
    });

    test('derrota no completa nivel', () async {
      final storyRepo = await repo();
      await completePrologue(storyRepo);

      final result = await storyRepo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: false,
        matchState: MatchState.testing(
          score: const MatchScore(user: 1, rival: 3),
          status: MatchStatus.finished,
        ),
      );

      expect(result.firstCompletion, isFalse);
      expect(
        storyRepo.loadProgress().isLevelCompleted('chapter_01_level_04'),
        isFalse,
      );
    });
  });

  group('ClashMiniPitch', () {
    testWidgets('renderiza jugadores y balón', (tester) async {
      final state = _playingState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClashMiniPitch(state: state)),
        ),
      );

      expect(find.text('U1'), findsOneWidget);
      expect(find.text('R1'), findsOneWidget);
    });
  });
}

class _EmptyCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [];
}

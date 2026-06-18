import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_level_scaling.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_service.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_requirements.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'clash_test_support.dart';

const _card = ClashCard(
  id: 'xp-test-card',
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
  superTechniques: [],
  basicPortraitPath: 'placeholder',
);

const _entry = ClashCardCatalogEntry(
  card: _card,
  name: 'Tester',
  team: 'Eternal XI',
);

const _matchLevel = ClashStoryLevel(
  id: 'chapter_01_level_04',
  chapterId: 'chapter-01',
  title: 'La primera pachanga',
  description: 'Tutorial',
  order: 4,
  type: ClashStoryLevelType.match,
  energyCost: 8,
  cardXpReward: 80,
  rewards: ClashStoryReward(gems: 1, coins: 500),
  scenes: [],
  requirements: ClashStoryLevelRequirements(
    clashTeamUnlocked: true,
    completeActiveLineup: true,
  ),
);

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [_entry];
}

Future<Widget> _detailTestApp(
  ClashPlayerCollectionRepository collectionRepo,
  ClashExpMaterialsRepository materialsRepo,
) async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
  final controller = ClashCardsController(cardsRepo, collectionRepo);
  await controller.load();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ClashCardsController>.value(value: controller),
      Provider<ClashPlayerCollectionRepository>.value(value: collectionRepo),
      Provider<ClashExpMaterialsRepository>.value(value: materialsRepo),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: ClashCardDetailScreen(cardId: 'xp-test-card')),
    ),
  );
}

Future<ClashStoryRepository> _storyRepo(
  InMemoryClashPlayerCollectionBackend storage,
) async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    storage: storage,
  );
  await collectionRepo.grantMissingCardIds([_card.id]);
  return ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: InMemoryClashStoryProgressBackend(),
    collectionRepository: collectionRepo,
  );
}

Future<void> _completePrologue(ClashStoryRepository repo) async {
  await repo.completeStoryLevel('prologue-lvl-01');
  await repo.completeStoryLevel('prologue-lvl-02');
  await repo.completeStoryLevel('prologue-lvl-03');
}

void main() {
  group('ClashCardXpTable', () {
    test('xpToNextLevel aumenta con nivel', () {
      final low = ClashCardXpTable.xpToNextLevel(1, ClashRarity.n);
      final high = ClashCardXpTable.xpToNextLevel(10, ClashRarity.n);
      expect(high, greaterThan(low));
    });
  });

  group('ClashCardXpService', () {
    test('carta gana XP', () {
      final progress = ClashCardXpService.initialProgress(_card.id);
      final result = ClashCardXpService.applyXp(
        progress: progress,
        rarity: ClashRarity.n,
        cardName: 'Tester',
        xpAmount: 30,
      );
      expect(result.xpGained, 30);
      expect(result.newXp, 30);
    });

    test('carta sube un nivel', () {
      final progress = ClashCardProgress(
        cardId: _card.id,
        currentLevel: 1,
        currentExperience: 30,
        unlockedDuplicateNodes: 0,
        techniqueLevels: const {},
      );
      final result = ClashCardXpService.applyXp(
        progress: progress,
        rarity: ClashRarity.n,
        cardName: 'Tester',
        xpAmount: 20,
      );
      expect(result.didLevelUp, isTrue);
      expect(result.newLevel, 2);
    });

    test('carta puede subir varios niveles', () {
      final progress = ClashCardXpService.initialProgress(_card.id);
      final result = ClashCardXpService.applyXp(
        progress: progress,
        rarity: ClashRarity.n,
        cardName: 'Tester',
        xpAmount: 500,
      );
      expect(result.levelsGained, greaterThan(1));
    });

    test('carta no supera nivel máximo', () {
      final progress = ClashCardProgress(
        cardId: _card.id,
        currentLevel: ClashRarity.n.maxLevel,
        currentExperience: 0,
        unlockedDuplicateNodes: 0,
        techniqueLevels: const {},
      );
      final result = ClashCardXpService.applyXp(
        progress: progress,
        rarity: ClashRarity.n,
        cardName: 'Tester',
        xpAmount: 999,
      );
      expect(result.newLevel, ClashRarity.n.maxLevel);
      expect(result.xpGained, 0);
    });

    test('carta maxeada no sube más', () {
      final progress = ClashCardProgress(
        cardId: _card.id,
        currentLevel: 60,
        currentExperience: 0,
        unlockedDuplicateNodes: 0,
        techniqueLevels: const {},
      );
      final updated = ClashCardXpService.progressAfterResult(
        progress,
        ClashCardXpService.applyXp(
          progress: progress,
          rarity: ClashRarity.n,
          cardName: 'Tester',
          xpAmount: 100,
        ),
      );
      expect(updated.currentLevel, 60);
      expect(updated.currentExperience, 0);
    });
  });

  group('ClashCardLevelScaling', () {
    test('potencia usa nivel si se implementa escalado', () {
      final basePower = _card.power;
      final progress = ClashCardProgress(
        cardId: _card.id,
        currentLevel: 30,
        currentExperience: 0,
        unlockedDuplicateNodes: 0,
        techniqueLevels: const {},
      );
      final scaled = ClashCardLevelScaling.effectivePower(_card, progress);
      expect(scaled, greaterThan(basePower));
    });
  });

  group('ClashStoryLevel cardXpReward', () {
    test('cardXpReward se parsea desde JSON', () {
      final level = ClashStoryLevel.fromJson({
        'id': 'lvl',
        'chapterId': 'chapter-01',
        'title': 'T',
        'description': 'D',
        'order': 1,
        'type': 'match',
        'energyCost': 1,
        'rewards': {},
        'cardXpReward': 80,
        'scenes': [],
      });
      expect(level.cardXpReward, 80);
    });
  });

  group('ClashPlayerCollectionRepository XP', () {
    test('progreso persiste nivel y XP', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
      final repo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
      );
      await repo.grantMissingCardIds([_card.id]);

      await repo.grantMatchXp(cardIds: [_card.id], xpPerCard: 80);
      final progress = repo.progressFor(_card.id);
      expect(progress, isNotNull);
      expect(progress!.currentExperience, greaterThanOrEqualTo(0));
    });

    test('colección devuelve nivel persistido', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
      final repo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
      );
      await repo.grantMissingCardIds([_card.id]);
      await repo.grantMatchXp(cardIds: [_card.id], xpPerCard: 200);

      final owned = await repo.fetchOwnedCards();
      expect(owned.first.displayLevel, greaterThan(1));
    });
  });

  group('ClashStoryRepository match XP', () {
    test('perder no da XP', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final repo = await _storyRepo(storage);
      await _completePrologue(repo);

      final result = await repo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: false,
        matchState: MatchState.testing(
          score: const MatchScore(user: 1, rival: 3),
          status: MatchStatus.finished,
        ),
        lineupCardIds: [_card.id],
      );

      expect(result.cardXpResults, isEmpty);
    });

    test('repetir nivel sí da XP aunque no duplique recompensa base', () async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final repo = await _storyRepo(storage);
      await _completePrologue(repo);
      final state = MatchState.testing(
        score: const MatchScore(user: 3, rival: 1),
        status: MatchStatus.finished,
      );

      await repo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: state,
        lineupCardIds: [_card.id],
      );
      final second = await repo.completeMatchLevel(
        'chapter_01_level_04',
        userWon: true,
        matchState: state,
        lineupCardIds: [_card.id],
      );

      expect(second.rewardsGranted.gems, 0);
      expect(second.cardXpResults, isNotEmpty);
      expect(second.cardXpResults.first.xpGained, 80);
    });
  });

  group('UI card XP', () {
    testWidgets('detalle muestra barra XP', (tester) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
      final materialsRepo = createTestExpMaterialsRepository();
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        expMaterialsRepository: materialsRepo,
      );
      await collectionRepo.grantMissingCardIds([_card.id]);

      await tester.pumpWidget(
        await _detailTestApp(collectionRepo, materialsRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Experiencia'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('detalle muestra nivel máximo si aplica', (tester) async {
      final storage = InMemoryClashPlayerCollectionBackend();
      final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
      final materialsRepo = createTestExpMaterialsRepository();
      final collectionRepo = createTestCollectionRepository(
        cardsRepository: cardsRepo,
        storage: storage,
        expMaterialsRepository: materialsRepo,
      );
      await collectionRepo.grantMissingCardIds([_card.id]);
      await collectionRepo.grantMatchXp(cardIds: [_card.id], xpPerCard: 50000);

      await tester.pumpWidget(
        await _detailTestApp(collectionRepo, materialsRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nivel máximo'), findsOneWidget);
    });

    testWidgets('victoria muestra experiencia de cartas', (tester) async {
      final state = MatchState.testing(
        score: const MatchScore(user: 3, rival: 0),
        status: MatchStatus.finished,
      );
      const xpResults = [
        ClashCardXpResult(
          cardId: 'xp-test-card',
          cardName: 'Tester',
          previousLevel: 1,
          newLevel: 2,
          previousXp: 0,
          newXp: 10,
          xpGained: 80,
          didLevelUp: true,
          reachedMaxLevel: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: const [],
              previewRewards: const ClashStoryReward(gems: 1),
              previewCardXp: xpResults,
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Experiencia de cartas'), findsOneWidget);
      expect(find.text('Tester'), findsOneWidget);
      expect(find.text('+80 EXP'), findsOneWidget);
    });

    testWidgets('fin de partido muestra level up', (tester) async {
      const xpResults = [
        ClashCardXpResult(
          cardId: 'xp-test-card',
          cardName: 'Tester',
          previousLevel: 1,
          newLevel: 2,
          previousXp: 0,
          newXp: 0,
          xpGained: 80,
          didLevelUp: true,
          reachedMaxLevel: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: MatchState.testing(
                score: const MatchScore(user: 3, rival: 0),
                status: MatchStatus.finished,
              ),
              level: _matchLevel,
              objectiveResults: const [],
              previewRewards: const ClashStoryReward(),
              previewCardXp: xpResults,
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sube de nivel'), findsOneWidget);
    });

    testWidgets('derrota no muestra XP ganada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: MatchState.testing(
                score: const MatchScore(user: 1, rival: 3),
                status: MatchStatus.finished,
              ),
              level: _matchLevel,
              objectiveResults: const [],
              previewRewards: const ClashStoryReward(),
              previewCardXp: const [],
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin EXP por derrota'), findsOneWidget);
      expect(find.text('Experiencia de cartas'), findsNothing);
    });
  });
}

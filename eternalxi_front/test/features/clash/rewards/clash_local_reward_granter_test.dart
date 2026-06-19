import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_type.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cards/clash_test_support.dart';

Future<
  ({
    ClashLocalRewardGranter granter,
    ClashStoryRepository story,
    ClashPlayerCollectionRepository collection,
    ClashExpMaterialsRepository expMaterials,
    ClashTechniqueBooksRepository techniqueBooks,
    ClashEvolutionMaterialsRepository evolutionMaterials,
    ClashGachaTicketRepository tickets,
  })
>
_createGranterSetup({int initialCoins = 0, int initialGems = 0}) async {
  final expMaterials = createTestExpMaterialsRepository();
  final techniqueBooks = createTestTechniqueBooksRepository();
  final evolutionMaterials = createTestEvolutionMaterialsRepository();
  final tickets = createTestTicketRepository();
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collection = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    expMaterialsRepository: expMaterials,
    techniqueBooksRepository: techniqueBooks,
    evolutionMaterialsRepository: evolutionMaterials,
  );
  final storyProgress = InMemoryClashStoryProgressBackend();
  await storyProgress.writeProgress(
    ClashStoryProgress(walletCoins: initialCoins, walletGems: initialGems),
  );
  final story = ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: storyProgress,
    collectionRepository: collection,
    ticketRepository: tickets,
  );
  final granter = createTestRewardGranter(
    storyRepository: story,
    collectionRepository: collection,
    ticketRepository: tickets,
  );
  return (
    granter: granter,
    story: story,
    collection: collection,
    expMaterials: expMaterials,
    techniqueBooks: techniqueBooks,
    evolutionMaterials: evolutionMaterials,
    tickets: tickets,
  );
}

void main() {
  group('ClashLocalRewardGranter', () {
    test('concede monedas', () async {
      final setup = await _createGranterSetup();
      final result = await setup.granter.grantAll([ClashReward.coins(250)]);
      expect(result.isFullyGranted, isTrue);
      expect(result.coinsAdded, 250);
      expect(setup.story.walletCoins(), 250);
    });

    test('concede gemas', () async {
      final setup = await _createGranterSetup();
      final result = await setup.granter.grantAll([ClashReward.gems(3)]);
      expect(result.isFullyGranted, isTrue);
      expect(result.gemsAdded, 3);
      expect(setup.story.walletGems(), 3);
    });

    test('concede material EXP', () async {
      final setup = await _createGranterSetup();
      final before = setup.expMaterials.quantityFor('basic-training-manual');
      final result = await setup.granter.grantAll([
        ClashReward.expMaterial('basic-training-manual', 2),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        before + 2,
      );
    });

    test('concede libro técnica', () async {
      final setup = await _createGranterSetup();
      final before = setup.techniqueBooks.quantityFor('basic-technique-book');
      final result = await setup.granter.grantAll([
        ClashReward.techniqueBook('basic-technique-book', 1),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(
        setup.techniqueBooks.quantityFor('basic-technique-book'),
        before + 1,
      );
    });

    test('concede insignia', () async {
      final setup = await _createGranterSetup();
      final before = setup.evolutionMaterials.quantityFor('insignia-r');
      final result = await setup.granter.grantAll([
        ClashReward.evolutionMaterial('insignia-r', 1),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(setup.evolutionMaterials.quantityFor('insignia-r'), before + 1);
    });

    test('concede ticket', () async {
      final setup = await _createGranterSetup();
      final before = setup.tickets.quantityFor('starter-single-ticket');
      final result = await setup.granter.grantAll([
        ClashReward.ticket('starter-single-ticket', 1),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(setup.tickets.quantityFor('starter-single-ticket'), before + 1);
    });

    test('concede carta nueva', () async {
      final setup = await _createGranterSetup();
      final result = await setup.granter.grantAll([
        ClashReward.cardMissing('gacha-card-a'),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(result.newlyGrantedCardIds, contains('gacha-card-a'));
      expect(setup.collection.loadOwnedCardIds(), contains('gacha-card-a'));
    });

    test('concede duplicado si la carta ya existe', () async {
      final setup = await _createGranterSetup();
      await setup.collection.grantMissingCardIds(['gacha-card-a']);
      final result = await setup.granter.grantAll([
        ClashReward.cardDuplicate('gacha-card-a'),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(result.duplicateCardIds, ['gacha-card-a']);
    });

    test('devuelve failedReward si item desconocido', () async {
      final setup = await _createGranterSetup();
      final result = await setup.granter.grantAll([
        ClashReward.expMaterial('unknown-material', 1),
      ]);
      expect(result.isFullyGranted, isFalse);
      expect(result.failedRewards, hasLength(1));
      expect(result.failedRewards.first.error, 'unknown_exp_material');
    });

    test('grantAll mezcla varios tipos', () async {
      final setup = await _createGranterSetup();
      final expBefore = setup.expMaterials.quantityFor('basic-training-manual');
      final ticketBefore = setup.tickets.quantityFor('starter-single-ticket');
      final result = await setup.granter.grantAll([
        ClashReward.coins(100),
        ClashReward.gems(1),
        ClashReward.expMaterial('basic-training-manual', 1),
        ClashReward.ticket('starter-single-ticket', 1),
        ClashReward.cardMissing('gacha-card-b'),
      ]);
      expect(result.isFullyGranted, isTrue);
      expect(result.coinsAdded, 100);
      expect(result.gemsAdded, 1);
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        expBefore + 1,
      );
      expect(
        setup.tickets.quantityFor('starter-single-ticket'),
        ticketBefore + 1,
      );
      expect(result.newlyGrantedCardIds, contains('gacha-card-b'));
    });
  });

  group('Flujos migrados al granter', () {
    test('gift claim mantiene idempotencia', () async {
      final setup = await createTestGiftsSetup();
      await setup.gifts.claimGift('gift-thanks-beta');
      final coinsAfterFirst = setup.story.walletCoins();
      final second = await setup.gifts.claimGift('gift-thanks-beta');
      expect(second.error, ClashGiftClaimError.alreadyClaimed);
      expect(setup.story.walletCoins(), coinsAfterFirst);
    });

    test('achievement claim usa granter', () async {
      final setup = await createTestAchievementsSetup(initialCoins: 100);
      await setup.achievements.recordAchievementEvent(
        ClashAchievementType.playMatch,
      );
      final result = await setup.achievements.claimAchievement(
        'achievement-first-match',
      );
      expect(result.success, isTrue);
      expect(setup.story.walletCoins(), 600);
    });

    test('daily mission claim usa granter', () async {
      final setup = await createTestMissionsSetup(initialCoins: 100);
      await setup.missions.recordDailyMissionEvent(
        ClashDailyMissionType.playMatch,
      );
      final result = await setup.missions.claimMission('daily-play-match');
      expect(result.success, isTrue);
      expect(setup.story.walletCoins(), 400);
    });

    test('weekly mission claim usa granter', () async {
      final setup = await createTestWeeklyMissionsSetup(initialCoins: 100);
      await setup.weekly.recordWeeklyMissionEvent(
        ClashWeeklyMissionType.playMatch,
        amount: 5,
      );
      final result = await setup.weekly.claimMission('weekly-play-matches');
      expect(result.success, isTrue);
      expect(setup.story.walletCoins(), 2100);
    });

    test('event firstClear usa granter', () async {
      final setup = await createTestEventsSetup();
      const eventId = 'event-arin-training';
      const storyStageId = 'event-arin-stage-01';
      final expBefore = setup.expMaterials.quantityFor('basic-training-manual');
      final result = await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      expect(result?.firstClear, isTrue);
      expect(setup.story.walletCoins(), 300);
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        expBefore + 1,
      );
    });

    test('event repeat no duplica firstClear', () async {
      final setup = await createTestEventsSetup();
      const eventId = 'event-arin-training';
      const storyStageId = 'event-arin-stage-01';
      await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      final coinsAfterFirst = setup.story.walletCoins();
      final repeat = await setup.events.completeStoryStage(
        eventId: eventId,
        stageId: storyStageId,
      );
      expect(repeat?.firstClear, isFalse);
      expect(setup.story.walletCoins(), coinsAfterFirst);
    });

    test('shop compra usa granter y mantiene descuento', () async {
      final repo = await createTestShopRepository(initialCoins: 1500);
      final result = await repo.purchase('shop-basic-training-pack');
      expect(result.success, isTrue);
      expect(result.spentCoins, 300);
      expect(repo.walletCoins(), 1200);
    });

    test('story grantWallet false no altera wallet', () async {
      final setup = await _createGranterSetup(initialCoins: 50, initialGems: 2);
      final expBefore = setup.expMaterials.quantityFor('basic-training-manual');
      final result = await setup.granter.grantAll([
        ClashReward.expMaterial('basic-training-manual', 1),
      ], grantWallet: false);
      expect(result.isFullyGranted, isTrue);
      expect(setup.story.walletCoins(), 50);
      expect(setup.story.walletGems(), 2);
      expect(
        setup.expMaterials.quantityFor('basic-training-manual'),
        expBefore + 1,
      );
    });
  });
}

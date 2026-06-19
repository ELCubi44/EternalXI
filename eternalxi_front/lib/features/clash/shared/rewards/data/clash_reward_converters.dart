import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_reward_adapter.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_reward_adapter.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket_reward_adapter.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Adaptadores mínimos hacia [ClashReward] (Fase 53).
class ClashRewardConverters {
  const ClashRewardConverters._();

  static List<ClashReward> fromAchievementReward(
    ClashAchievementReward reward,
  ) {
    final rewards = <ClashReward>[];
    if (reward.coins > 0) {
      rewards.add(ClashReward.coins(reward.coins));
    }
    if (reward.gems > 0) {
      rewards.add(ClashReward.gems(reward.gems));
    }
    rewards.addAll(fromProductGrants(reward.toProductGrants()));
    return rewards;
  }

  static List<ClashReward> fromDailyMissionReward(
    ClashDailyMissionReward reward,
  ) {
    final rewards = <ClashReward>[];
    if (reward.coins > 0) {
      rewards.add(ClashReward.coins(reward.coins));
    }
    if (reward.gems > 0) {
      rewards.add(ClashReward.gems(reward.gems));
    }
    rewards.addAll(fromProductGrants(reward.toProductGrants()));
    return rewards;
  }

  static List<ClashReward> fromWeeklyMissionReward(
    ClashWeeklyMissionReward reward,
  ) {
    final rewards = <ClashReward>[];
    if (reward.coins > 0) {
      rewards.add(ClashReward.coins(reward.coins));
    }
    if (reward.gems > 0) {
      rewards.add(ClashReward.gems(reward.gems));
    }
    rewards.addAll(fromProductGrants(reward.toProductGrants()));
    return rewards;
  }

  static List<ClashReward> fromCharacterEventReward(
    ClashCharacterEventReward reward,
  ) {
    final rewards = fromAchievementReward(reward.toAchievementReward());
    if (reward.featuredCardId != null) {
      rewards.add(
        ClashReward.featuredCard(
          reward.featuredCardId!,
          asDuplicateOnly: reward.featuredCardAsDuplicate,
        ),
      );
    }
    return rewards;
  }

  /// Ítems y cartas de historia (sin monedas/gemas; wallet en progress).
  static List<ClashReward> fromStoryRewardItems(ClashStoryReward reward) {
    final rewards = <ClashReward>[];

    if (reward.starterRosterKey == ClashStoryReward.eternalXiStarterRosterKey) {
      rewards.add(ClashReward.starterRoster(reward.starterRosterKey!));
    }

    for (final cardId in reward.cardIds) {
      rewards.add(ClashReward.cardMissing(cardId));
    }

    for (final entry in ClashExpMaterialRewardAdapter.quantitiesFromStoryReward(
      reward,
    ).entries) {
      rewards.add(ClashReward.expMaterial(entry.key, entry.value));
    }

    for (final entry
        in ClashTechniqueBookRewardAdapter.quantitiesFromStoryReward(
          reward,
        ).entries) {
      rewards.add(ClashReward.techniqueBook(entry.key, entry.value));
    }

    for (final entry in ClashGachaTicketRewardAdapter.quantitiesFromStoryReward(
      reward,
    ).entries) {
      rewards.add(ClashReward.ticket(entry.key, entry.value));
    }

    return rewards;
  }

  static List<ClashReward> fromProductGrants(
    List<ClashShopProductGrant> grants,
  ) {
    final rewards = <ClashReward>[];
    for (final grant in grants) {
      if (grant.quantity <= 0) {
        continue;
      }
      switch (grant.type) {
        case ClashShopProductType.expMaterial:
          rewards.add(ClashReward.expMaterial(grant.id, grant.quantity));
        case ClashShopProductType.techniqueBook:
          rewards.add(ClashReward.techniqueBook(grant.id, grant.quantity));
        case ClashShopProductType.evolutionMaterial:
          rewards.add(ClashReward.evolutionMaterial(grant.id, grant.quantity));
        case ClashShopProductType.ticket:
          rewards.add(ClashReward.ticket(grant.id, grant.quantity));
      }
    }
    return rewards;
  }
}

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_status.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_icon.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_label.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Construye items de presentación desde recompensas de dominio (Fase 58).
abstract final class ClashRewardDisplayBuilder {
  static List<ClashRewardDisplayItem> fromClashRewards(
    List<ClashReward> rewards,
    AppLocalizations l10n, {
    ClashRewardDisplayStatus status = ClashRewardDisplayStatus.none,
  }) {
    return rewards
        .map((reward) => _fromClashReward(reward, l10n, status: status))
        .toList(growable: false);
  }

  static List<ClashRewardDisplayItem> fromAchievementReward(
    ClashAchievementReward reward,
    AppLocalizations l10n,
  ) {
    return fromClashRewards(
      ClashRewardConverters.fromAchievementReward(reward),
      l10n,
    );
  }

  static List<ClashRewardDisplayItem> fromDailyMissionReward(
    ClashDailyMissionReward reward,
    AppLocalizations l10n,
  ) {
    return fromClashRewards(
      ClashRewardConverters.fromDailyMissionReward(reward),
      l10n,
    );
  }

  static List<ClashRewardDisplayItem> fromWeeklyMissionReward(
    ClashWeeklyMissionReward reward,
    AppLocalizations l10n,
  ) {
    return fromClashRewards(
      ClashRewardConverters.fromWeeklyMissionReward(reward),
      l10n,
    );
  }

  static List<ClashRewardDisplayItem> fromCharacterEventReward(
    ClashCharacterEventReward reward,
    AppLocalizations l10n, {
    ClashRewardDisplayStatus status = ClashRewardDisplayStatus.none,
  }) {
    return fromClashRewards(
      ClashRewardConverters.fromCharacterEventReward(reward),
      l10n,
      status: status,
    );
  }

  static List<ClashRewardDisplayItem> fromShopGrant(
    ClashShopProductGrant grant,
    AppLocalizations l10n,
  ) {
    return [
      ClashRewardDisplayItem(
        icon: ClashRewardIcon.forShopType(grant.type),
        label: ClashRewardLabel.shopGrantOrItemLabel(
          l10n,
          id: grant.id,
          grantLabel: grant.label,
        ),
        quantity: grant.quantity,
      ),
    ];
  }

  static List<ClashRewardDisplayItem> fromShopProduct(
    ClashShopProduct product,
    AppLocalizations l10n,
  ) {
    return product.grants
        .expand((grant) => fromShopGrant(grant, l10n))
        .toList(growable: false);
  }

  /// Texto compacto para vistas inline (objetivos match, etc.).
  static String compactPreview(
    List<ClashRewardDisplayItem> items,
    AppLocalizations l10n, {
    String separator = ' · ',
  }) {
    if (items.isEmpty) {
      return '';
    }
    return items.map((item) => lineText(item, l10n)).join(separator);
  }

  static String lineText(ClashRewardDisplayItem item, AppLocalizations l10n) {
    if (item.showQuantity) {
      return l10n.clashShopGrantLine(item.label, item.quantity!);
    }
    final detail = item.detail?.trim();
    if (detail != null && detail.isNotEmpty) {
      return '${item.label} ($detail)';
    }
    return item.label;
  }

  static List<ClashRewardDisplayItem> fromGrantResult(
    ClashRewardGrantResult result,
    AppLocalizations l10n,
  ) {
    final items = [...fromClashRewards(result.grantedRewards, l10n)];
    final cardDetails = items
        .map((item) => item.detail)
        .whereType<String>()
        .toSet();

    for (final cardId in result.newlyGrantedCardIds) {
      if (cardDetails.contains(cardId)) {
        continue;
      }
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.cardMissing),
          label: l10n.clashRewardLabelCardNew,
          detail: cardId,
        ),
      );
      cardDetails.add(cardId);
    }

    for (final cardId in result.duplicateCardIds) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.cardDuplicate),
          label: l10n.clashRewardLabelCardDuplicate,
          detail: cardId,
        ),
      );
    }

    return items;
  }

  static List<ClashRewardDisplayItem> fromStoryReward(
    ClashStoryReward reward,
    AppLocalizations l10n, {
    ClashRewardDisplayStatus status = ClashRewardDisplayStatus.none,
  }) {
    final items = <ClashRewardDisplayItem>[];

    if (reward.gems > 0) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.gems),
          label: l10n.clashRewardLabelGems,
          quantity: reward.gems,
          status: status,
        ),
      );
    }
    if (reward.coins > 0) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.coins),
          label: l10n.clashRewardLabelCoins,
          quantity: reward.coins,
          status: status,
        ),
      );
    }

    if (reward.starterRosterKey != null &&
        reward.starterRosterKey!.isNotEmpty &&
        items.isEmpty &&
        reward.cardIds.isEmpty) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.starterRoster),
          label: l10n.clashStoryCardsReceived,
          status: status,
        ),
      );
    }

    if (reward.cardIds.isNotEmpty) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.cardMissing),
          label: l10n.clashRewardLabelCardNew,
          quantity: reward.cardIds.length,
          status: status,
        ),
      );
    }

    for (final item in reward.items) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forStoryItem(),
          label: item.name,
          quantity: item.quantity,
          status: status,
        ),
      );
    }

    for (final material in reward.materials) {
      items.add(
        ClashRewardDisplayItem(
          icon: ClashRewardIcon.forKind(ClashRewardKind.expMaterial),
          label: material.name,
          quantity: material.quantity,
          status: status,
        ),
      );
    }

    return items;
  }

  static ClashRewardDisplayItem _fromClashReward(
    ClashReward reward,
    AppLocalizations l10n, {
    ClashRewardDisplayStatus status = ClashRewardDisplayStatus.none,
  }) {
    return switch (reward.kind) {
      ClashRewardKind.coins => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: l10n.clashRewardLabelCoins,
        quantity: reward.amount,
        status: status,
      ),
      ClashRewardKind.gems => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: l10n.clashRewardLabelGems,
        quantity: reward.amount,
        status: status,
      ),
      ClashRewardKind.expMaterial ||
      ClashRewardKind.techniqueBook ||
      ClashRewardKind.evolutionMaterial ||
      ClashRewardKind.ticket => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: ClashRewardLabel.itemIdLabel(l10n, reward.itemId ?? ''),
        quantity: reward.amount,
        status: status,
      ),
      ClashRewardKind.cardMissing => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: l10n.clashRewardLabelCardNew,
        detail: reward.itemId,
        status: status,
      ),
      ClashRewardKind.cardDuplicate => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: l10n.clashRewardLabelCardDuplicate,
        detail: reward.itemId,
        status: status,
      ),
      ClashRewardKind.featuredCard => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: reward.featuredCardAsDuplicate
            ? l10n.clashRewardLabelCardDuplicate
            : l10n.clashRewardLabelFeaturedCard,
        detail: reward.itemId,
        status: status,
      ),
      ClashRewardKind.starterRoster => ClashRewardDisplayItem(
        icon: ClashRewardIcon.forKind(reward.kind),
        label: l10n.clashRewardLabelStarterRoster,
        status: status,
      ),
    };
  }
}

import 'dart:async';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_claim_result.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback_message.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback_sheet.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_error.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_result.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Feedback unificado al recibir recompensas Clash (Fase 59).
abstract final class ClashRewardFeedback {
  static const compactItemLimit = 2;

  static ClashRewardFeedbackMessage buildMessage(
    AppLocalizations l10n,
    ClashRewardGrantResult result, {
    String? successTitle,
    String? partialTitle,
    String? failureTitle,
  }) {
    final items = ClashRewardDisplayBuilder.fromGrantResult(result, l10n);
    final compactSummary = items.isEmpty
        ? null
        : ClashRewardDisplayBuilder.compactPreview(items, l10n);

    if (result.failedRewards.isNotEmpty && result.grantedRewards.isEmpty) {
      return ClashRewardFeedbackMessage(
        kind: ClashRewardFeedbackKind.failure,
        title: failureTitle ?? l10n.clashRewardFeedbackFailureTitle,
        subtitle: l10n.clashRewardFeedbackFailureBody,
      );
    }

    if (result.failedRewards.isNotEmpty) {
      return ClashRewardFeedbackMessage(
        kind: ClashRewardFeedbackKind.partial,
        title: partialTitle ?? l10n.clashRewardFeedbackPartialTitle,
        subtitle: l10n.clashRewardFeedbackPartialBody,
        items: items,
        compactSummary: compactSummary,
      );
    }

    if (items.length <= 1) {
      return ClashRewardFeedbackMessage(
        kind: ClashRewardFeedbackKind.success,
        title: successTitle ?? l10n.clashRewardFeedbackSingleTitle,
        subtitle: compactSummary,
        items: items,
        compactSummary: compactSummary,
      );
    }

    return ClashRewardFeedbackMessage(
      kind: ClashRewardFeedbackKind.success,
      title: successTitle ?? l10n.clashRewardFeedbackSuccessTitle,
      subtitle: compactSummary,
      items: items,
      compactSummary: compactSummary,
    );
  }

  static ClashRewardGrantResult syntheticFromClashRewards(
    List<ClashReward> rewards, {
    List<String> newlyGrantedCardIds = const [],
    List<String> duplicateCardIds = const [],
  }) {
    return ClashRewardGrantResult(
      grantedRewards: rewards,
      newlyGrantedCardIds: newlyGrantedCardIds,
      duplicateCardIds: duplicateCardIds,
    );
  }

  static ClashRewardGrantResult fromAchievementReward(
    ClashAchievementReward reward,
  ) {
    return syntheticFromClashRewards(
      ClashRewardConverters.fromAchievementReward(reward),
    );
  }

  static ClashRewardGrantResult fromDailyMissionReward(
    ClashDailyMissionReward reward,
  ) {
    return syntheticFromClashRewards(
      ClashRewardConverters.fromDailyMissionReward(reward),
    );
  }

  static ClashRewardGrantResult fromWeeklyMissionReward(
    ClashWeeklyMissionReward reward,
  ) {
    return syntheticFromClashRewards(
      ClashRewardConverters.fromWeeklyMissionReward(reward),
    );
  }

  static ClashRewardGrantResult fromCharacterEventReward(
    ClashCharacterEventReward reward, {
    List<String> newlyGrantedCardIds = const [],
    List<String> duplicateCardIds = const [],
  }) {
    return syntheticFromClashRewards(
      ClashRewardConverters.fromCharacterEventReward(reward),
      newlyGrantedCardIds: newlyGrantedCardIds,
      duplicateCardIds: duplicateCardIds,
    );
  }

  static ClashRewardGrantResult fromStoryReward(
    ClashStoryReward reward, {
    List<String> newlyGrantedCardIds = const [],
  }) {
    final rewards = <ClashReward>[];
    if (reward.coins > 0) {
      rewards.add(ClashReward.coins(reward.coins));
    }
    if (reward.gems > 0) {
      rewards.add(ClashReward.gems(reward.gems));
    }
    rewards.addAll(ClashRewardConverters.fromStoryRewardItems(reward));
    return syntheticFromClashRewards(
      rewards,
      newlyGrantedCardIds: newlyGrantedCardIds,
    );
  }

  static ClashRewardGrantResult fromShopGrants(
    List<ClashShopProductGrant> grants,
  ) {
    return syntheticFromClashRewards(
      ClashRewardConverters.fromProductGrants(grants),
    );
  }

  static ClashRewardGrantResult merge(
    Iterable<ClashRewardGrantResult> results,
  ) {
    final granted = <ClashReward>[];
    final failed = <ClashFailedReward>[];
    final itemCounts = <String, int>{};
    final newlyGranted = <String>[];
    final duplicates = <String>[];
    var coins = 0;
    var gems = 0;

    for (final result in results) {
      granted.addAll(result.grantedRewards);
      failed.addAll(result.failedRewards);
      coins += result.coinsAdded;
      gems += result.gemsAdded;
      newlyGranted.addAll(result.newlyGrantedCardIds);
      duplicates.addAll(result.duplicateCardIds);
      for (final entry in result.itemCounts.entries) {
        itemCounts[entry.key] = (itemCounts[entry.key] ?? 0) + entry.value;
      }
    }

    return ClashRewardGrantResult(
      grantedRewards: granted,
      failedRewards: failed,
      coinsAdded: coins,
      gemsAdded: gems,
      itemCounts: itemCounts,
      newlyGrantedCardIds: newlyGranted,
      duplicateCardIds: duplicates,
    );
  }

  static void showGrantedFeedback(
    BuildContext context,
    ClashRewardGrantResult result, {
    String? successTitle,
    String? partialTitle,
    String? failureTitle,
    ClashRewardHistorySourceType? historySourceType,
    String? historySourceId,
    String? historyTitle,
  }) {
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    final message = buildMessage(
      l10n,
      result,
      successTitle: successTitle,
      partialTitle: partialTitle,
      failureTitle: failureTitle,
    );
    if (historySourceType != null) {
      _recordGrant(
        context,
        sourceType: historySourceType,
        sourceId: historySourceId,
        title: historyTitle ?? message.title,
        result: result,
      );
    }
    _presentMessage(context, message);
  }

  /// Registra historial desde pantallas de recompensa dedicadas (Fase 60).
  static void recordCompletionScreenHistory(
    BuildContext context, {
    required ClashRewardHistorySourceType sourceType,
    required String title,
    required ClashRewardGrantResult result,
    String? sourceId,
  }) {
    _recordGrant(
      context,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      result: result,
    );
  }

  static void showGiftClaimFeedback(
    BuildContext context,
    ClashGiftClaimResult result,
  ) {
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    if (!result.success) {
      _recordFailure(
        context,
        sourceType: ClashRewardHistorySourceType.gift,
        sourceId: result.giftId,
        title: l10n.clashRewardFeedbackFailureTitle,
      );
      _showClaimFailureSnackBar(context);
      return;
    }
    final rewards = result.rewards;
    if (rewards == null || rewards.isEmpty) {
      _recordGrant(
        context,
        sourceType: ClashRewardHistorySourceType.gift,
        sourceId: result.giftId,
        title: l10n.clashGiftsClaimSuccess,
        result: syntheticFromClashRewards(const []),
      );
      _showSimpleSuccessSnackBar(context, l10n.clashGiftsClaimSuccess);
      return;
    }
    showGrantedFeedback(
      context,
      fromAchievementReward(rewards),
      historySourceType: ClashRewardHistorySourceType.gift,
      historySourceId: result.giftId,
    );
  }

  static void showGiftBatchClaimFeedback(
    BuildContext context,
    List<ClashGiftClaimResult> results,
  ) {
    _showBatchClaimFeedback(
      context,
      results,
      ClashRewardHistorySourceType.gift,
      (result) =>
          result.success && result.rewards != null && !result.rewards!.isEmpty
          ? fromAchievementReward(result.rewards!)
          : null,
    );
  }

  static void showAchievementClaimFeedback(
    BuildContext context,
    ClashAchievementClaimResult result,
  ) {
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    if (!result.success) {
      _recordFailure(
        context,
        sourceType: ClashRewardHistorySourceType.achievement,
        sourceId: result.achievementId,
        title: l10n.clashRewardFeedbackFailureTitle,
      );
      _showClaimFailureSnackBar(context);
      return;
    }
    final reward = result.reward;
    if (reward == null || reward.isEmpty) {
      _recordGrant(
        context,
        sourceType: ClashRewardHistorySourceType.achievement,
        sourceId: result.achievementId,
        title: l10n.clashAchievementsClaimSuccess,
        result: syntheticFromClashRewards(const []),
      );
      _showSimpleSuccessSnackBar(context, l10n.clashAchievementsClaimSuccess);
      return;
    }
    showGrantedFeedback(
      context,
      fromAchievementReward(reward),
      historySourceType: ClashRewardHistorySourceType.achievement,
      historySourceId: result.achievementId,
    );
  }

  static void showAchievementBatchClaimFeedback(
    BuildContext context,
    List<ClashAchievementClaimResult> results,
  ) {
    _showBatchClaimFeedback(
      context,
      results,
      ClashRewardHistorySourceType.achievement,
      (result) =>
          result.success && result.reward != null && !result.reward!.isEmpty
          ? fromAchievementReward(result.reward!)
          : null,
    );
  }

  static void showDailyMissionClaimFeedback(
    BuildContext context,
    ClashDailyMissionClaimResult result,
  ) {
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    if (!result.success) {
      _recordFailure(
        context,
        sourceType: ClashRewardHistorySourceType.dailyMission,
        sourceId: result.missionId,
        title: l10n.clashRewardFeedbackFailureTitle,
      );
      _showClaimFailureSnackBar(context);
      return;
    }
    final reward = result.reward;
    if (reward == null || reward.isEmpty) {
      _recordGrant(
        context,
        sourceType: ClashRewardHistorySourceType.dailyMission,
        sourceId: result.missionId,
        title: l10n.clashDailyMissionsClaimSuccess,
        result: syntheticFromClashRewards(const []),
      );
      _showSimpleSuccessSnackBar(context, l10n.clashDailyMissionsClaimSuccess);
      return;
    }
    showGrantedFeedback(
      context,
      fromDailyMissionReward(reward),
      historySourceType: ClashRewardHistorySourceType.dailyMission,
      historySourceId: result.missionId,
    );
  }

  static void showDailyMissionBatchClaimFeedback(
    BuildContext context,
    List<ClashDailyMissionClaimResult> results,
  ) {
    _showBatchClaimFeedback(
      context,
      results,
      ClashRewardHistorySourceType.dailyMission,
      (result) =>
          result.success && result.reward != null && !result.reward!.isEmpty
          ? fromDailyMissionReward(result.reward!)
          : null,
    );
  }

  static void showWeeklyMissionClaimFeedback(
    BuildContext context,
    ClashWeeklyMissionClaimResult result,
  ) {
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    if (!result.success) {
      _recordFailure(
        context,
        sourceType: ClashRewardHistorySourceType.weeklyMission,
        sourceId: result.missionId,
        title: l10n.clashRewardFeedbackFailureTitle,
      );
      _showClaimFailureSnackBar(context);
      return;
    }
    final reward = result.reward;
    if (reward == null || reward.isEmpty) {
      _recordGrant(
        context,
        sourceType: ClashRewardHistorySourceType.weeklyMission,
        sourceId: result.missionId,
        title: l10n.clashWeeklyMissionsClaimSuccess,
        result: syntheticFromClashRewards(const []),
      );
      _showSimpleSuccessSnackBar(context, l10n.clashWeeklyMissionsClaimSuccess);
      return;
    }
    showGrantedFeedback(
      context,
      fromWeeklyMissionReward(reward),
      historySourceType: ClashRewardHistorySourceType.weeklyMission,
      historySourceId: result.missionId,
    );
  }

  static void showWeeklyMissionBatchClaimFeedback(
    BuildContext context,
    List<ClashWeeklyMissionClaimResult> results,
  ) {
    _showBatchClaimFeedback(
      context,
      results,
      ClashRewardHistorySourceType.weeklyMission,
      (result) =>
          result.success && result.reward != null && !result.reward!.isEmpty
          ? fromWeeklyMissionReward(result.reward!)
          : null,
    );
  }

  static void showShopPurchaseFeedback(
    BuildContext context,
    ClashShopPurchaseResult result,
  ) {
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    if (result.success) {
      if (result.grants.isEmpty) {
        _recordGrant(
          context,
          sourceType: ClashRewardHistorySourceType.shop,
          sourceId: result.productId,
          title: l10n.clashShopPurchaseSuccess,
          result: syntheticFromClashRewards(const []),
        );
        _showSimpleSuccessSnackBar(context, l10n.clashShopPurchaseSuccess);
        return;
      }
      showGrantedFeedback(
        context,
        fromShopGrants(result.grants),
        successTitle: l10n.clashShopPurchaseSuccess,
        historySourceType: ClashRewardHistorySourceType.shop,
        historySourceId: result.productId,
        historyTitle: l10n.clashShopPurchaseSuccess,
      );
      return;
    }

    if (result.error == ClashShopPurchaseError.grantFailed) {
      _recordFailure(
        context,
        sourceType: ClashRewardHistorySourceType.shop,
        sourceId: result.productId,
        title: l10n.clashRewardFeedbackFailureTitle,
      );
    }

    final message = switch (result.error) {
      ClashShopPurchaseError.insufficientCoins =>
        l10n.clashShopInsufficientCoins,
      ClashShopPurchaseError.productNotFound => l10n.clashStoryLoadError,
      ClashShopPurchaseError.grantFailed =>
        l10n.clashRewardFeedbackFailureTitle,
      null => l10n.clashStoryLoadError,
    };
    _showSimpleSnackBar(context, message, isError: true);
  }

  static void showEventCompletionFeedback(
    BuildContext context,
    ClashCharacterEventReward reward, {
    required bool firstClear,
    List<String> newlyGrantedCardIds = const [],
    List<String> duplicateCardIds = const [],
  }) {
    if (!context.mounted || reward.isEmpty) {
      return;
    }
    final l10n = context.l10n;
    showGrantedFeedback(
      context,
      fromCharacterEventReward(
        reward,
        newlyGrantedCardIds: newlyGrantedCardIds,
        duplicateCardIds: duplicateCardIds,
      ),
      successTitle: firstClear
          ? l10n.clashEventsRewardFirstClear
          : l10n.clashEventsRewardRepeat,
      historySourceType: ClashRewardHistorySourceType.event,
      historyTitle: firstClear
          ? l10n.clashEventsRewardFirstClear
          : l10n.clashEventsRewardRepeat,
    );
  }

  static void _showBatchClaimFeedback<T>(
    BuildContext context,
    List<T> results,
    ClashRewardHistorySourceType historySourceType,
    ClashRewardGrantResult? Function(T result) toGrantResult,
  ) {
    if (!context.mounted) {
      return;
    }
    final grants = <ClashRewardGrantResult>[];
    var failures = 0;
    for (final result in results) {
      final grant = toGrantResult(result);
      if (grant != null) {
        grants.add(grant);
      } else {
        failures += 1;
      }
    }

    if (grants.isEmpty) {
      if (failures > 0) {
        _recordFailure(
          context,
          sourceType: historySourceType,
          title: context.l10n.clashRewardFeedbackFailureTitle,
        );
        _showClaimFailureSnackBar(context);
      }
      return;
    }

    final merged = merge(grants);
    if (failures > 0) {
      final l10n = context.l10n;
      final message = buildMessage(l10n, merged);
      _recordGrant(
        context,
        sourceType: historySourceType,
        title: l10n.clashRewardFeedbackPartialTitle,
        result: merged,
      );
      _presentMessage(
        context,
        ClashRewardFeedbackMessage(
          kind: ClashRewardFeedbackKind.partial,
          title: l10n.clashRewardFeedbackPartialTitle,
          subtitle: l10n.clashRewardFeedbackBatchPartialBody(failures),
          items: message.items,
          compactSummary: message.compactSummary,
        ),
      );
      return;
    }

    showGrantedFeedback(context, merged, historySourceType: historySourceType);
  }

  static ClashRewardHistoryRepository? _historyRepository(
    BuildContext context,
  ) {
    try {
      return context.read<ClashRewardHistoryRepository>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  static void _recordGrant(
    BuildContext context, {
    required ClashRewardHistorySourceType sourceType,
    required String title,
    required ClashRewardGrantResult result,
    String? sourceId,
  }) {
    final repository = _historyRepository(context);
    if (repository == null) {
      return;
    }
    unawaited(
      repository.recordGrant(
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
        result: result,
      ),
    );
  }

  static void _recordFailure(
    BuildContext context, {
    required ClashRewardHistorySourceType sourceType,
    required String title,
    String? sourceId,
  }) {
    final repository = _historyRepository(context);
    if (repository == null) {
      return;
    }
    unawaited(
      repository.recordFailure(
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
      ),
    );
  }

  static void _presentMessage(
    BuildContext context,
    ClashRewardFeedbackMessage message,
  ) {
    if (message.kind == ClashRewardFeedbackKind.failure && !message.hasItems) {
      _showSimpleSnackBar(context, message.title, isError: true);
      return;
    }

    if (message.kind == ClashRewardFeedbackKind.partial && message.hasItems) {
      showClashRewardFeedbackSheet(context, message);
      return;
    }

    if (message.useCompactPresentation && message.hasItems) {
      _showCompactSnackBar(context, message);
      return;
    }

    if (message.hasItems) {
      showClashRewardFeedbackSheet(context, message);
      return;
    }

    _showSimpleSuccessSnackBar(context, message.title);
  }

  static void _showCompactSnackBar(
    BuildContext context,
    ClashRewardFeedbackMessage message,
  ) {
    final summary = message.compactSummary ?? message.title;
    _showSimpleSnackBar(context, summary);
  }

  static void _showSimpleSuccessSnackBar(BuildContext context, String text) {
    _showSimpleSnackBar(context, text);
  }

  static void _showClaimFailureSnackBar(BuildContext context) {
    _showSimpleSnackBar(
      context,
      context.l10n.clashRewardFeedbackFailureTitle,
      isError: true,
    );
  }

  static void _showSimpleSnackBar(
    BuildContext context,
    String text, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        content: Text(text),
      ),
    );
  }
}

/// Alias público solicitado en Fase 59.
void showClashRewardGrantedFeedback(
  BuildContext context,
  ClashRewardGrantResult result, {
  String? successTitle,
  String? partialTitle,
  String? failureTitle,
}) {
  ClashRewardFeedback.showGrantedFeedback(
    context,
    result,
    successTitle: successTitle,
    partialTitle: partialTitle,
    failureTitle: failureTitle,
  );
}

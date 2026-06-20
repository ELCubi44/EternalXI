import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Texto compacto de recompensa de un objetivo match (Fase 58).
String clashMatchObjectiveRewardPreview(
  BuildContext context,
  ClashStoryReward rewards,
) {
  if (rewards.isEmpty) {
    return '';
  }

  final l10n = context.l10n;
  final items = ClashRewardDisplayBuilder.fromStoryReward(rewards, l10n);
  return ClashRewardDisplayBuilder.compactPreview(items, l10n);
}

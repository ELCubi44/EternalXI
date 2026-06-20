import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Vista resumida de recompensas first clear (Fase 49 / 58).
class ClashStoryRewardPreview extends StatelessWidget {
  const ClashStoryRewardPreview({
    required this.rewards,
    this.title,
    this.muted = false,
    super.key,
  });

  final ClashStoryReward rewards;
  final String? title;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty && rewards.starterRosterKey == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final items = ClashRewardDisplayBuilder.fromStoryReward(rewards, l10n);

    return ClashRewardList(
      items: items,
      title: title,
      muted: muted,
      layout: ClashRewardListLayout.column,
    );
  }
}

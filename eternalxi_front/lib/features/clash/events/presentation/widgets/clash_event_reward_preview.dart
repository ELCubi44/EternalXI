import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';

/// Vista resumida de recompensas de fase de evento (Fase 50 / 58).
class ClashEventRewardPreview extends StatelessWidget {
  const ClashEventRewardPreview({
    required this.rewards,
    this.title,
    this.muted = false,
    super.key,
  });

  final ClashCharacterEventReward rewards;
  final String? title;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final items = ClashRewardDisplayBuilder.fromCharacterEventReward(
      rewards,
      l10n,
    );

    return ClashRewardList(
      items: items,
      title: title,
      muted: muted,
      layout: ClashRewardListLayout.column,
    );
  }
}

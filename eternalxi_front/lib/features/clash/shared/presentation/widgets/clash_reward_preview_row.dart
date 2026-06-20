import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';

/// Fila compacta de recompensas en chips (Fase 40 / 58).
class ClashRewardPreviewRow extends StatelessWidget {
  const ClashRewardPreviewRow({required this.items, this.title, super.key});

  final List<ClashRewardDisplayItem> items;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClashRewardList(
      items: items,
      title: title ?? context.l10n.clashEngagementRewardsLabel,
      layout: ClashRewardListLayout.wrap,
    );
  }
}

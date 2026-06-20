import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_chip.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:flutter/material.dart';

enum ClashRewardListLayout { wrap, column }

/// Lista compartida de recompensas en chips o filas (Fase 58).
class ClashRewardList extends StatelessWidget {
  const ClashRewardList({
    required this.items,
    this.title,
    this.muted = false,
    this.layout = ClashRewardListLayout.wrap,
    super.key,
  });

  final List<ClashRewardDisplayItem> items;
  final String? title;
  final bool muted;
  final ClashRewardListLayout layout;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final children = items
        .map((item) => ClashRewardChip(item: item, muted: muted))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: muted ? context.xiTextSecondary : null,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (layout == ClashRewardListLayout.wrap)
          Wrap(spacing: 6, runSpacing: 6, children: children)
        else
          ...children.map(
            (chip) =>
                Padding(padding: const EdgeInsets.only(bottom: 6), child: chip),
          ),
      ],
    );
  }
}

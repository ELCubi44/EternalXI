import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_labels.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_reward_preview.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Cabecera compartida de detalle de nivel story/match (Fase 49).
class ClashStoryLevelDetailHeader extends StatelessWidget {
  const ClashStoryLevelDetailHeader({
    required this.title,
    required this.chapterTitle,
    required this.type,
    required this.status,
    required this.rewards,
    required this.rewardsClaimed,
    super.key,
  });

  final String title;
  final String chapterTitle;
  final ClashStoryLevelType type;
  final ClashStoryLevelStatus status;
  final ClashStoryReward rewards;
  final bool rewardsClaimed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          chapterTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.xiTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ClashStoryLevelStatusChip(
              label: clashStoryLevelTypeLabel(type, l10n),
              kind: ClashStoryLevelChipKind.type,
            ),
            ClashStoryLevelStatusChip(
              label: clashStoryLevelStatusLabel(status, l10n),
              kind: ClashStoryLevelChipKind.status,
            ),
            if (!rewards.isEmpty || rewards.starterRosterKey != null)
              ClashStoryLevelStatusChip(
                label: rewardsClaimed
                    ? l10n.clashStoryFirstClearClaimed
                    : l10n.clashStoryFirstClear,
                kind: rewardsClaimed
                    ? ClashStoryLevelChipKind.firstClearClaimed
                    : ClashStoryLevelChipKind.firstClear,
              ),
          ],
        ),
        if (!rewards.isEmpty || rewards.starterRosterKey != null) ...[
          const SizedBox(height: 14),
          ClashStoryRewardPreview(
            title: l10n.clashStoryFirstClearRewardsTitle,
            rewards: rewards,
            muted: rewardsClaimed,
          ),
        ],
      ],
    );
  }
}

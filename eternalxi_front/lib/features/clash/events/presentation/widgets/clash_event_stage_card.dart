import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';
import 'package:flutter/material.dart';

class ClashEventStageCard extends StatelessWidget {
  const ClashEventStageCard({
    super.key,
    required this.progress,
    required this.onPrimaryAction,
  });

  final ClashCharacterEventStageProgress progress;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stage = progress.stage;

    final statusLabel = switch (progress.status) {
      ClashCharacterEventStageStatus.locked => l10n.clashEventsStageLocked,
      ClashCharacterEventStageStatus.available =>
        l10n.clashEventsStageAvailable,
      ClashCharacterEventStageStatus.completed =>
        l10n.clashEventsStageCompleted,
    };

    final actionLabel = switch (stage.type) {
      ClashCharacterEventStageType.story =>
        progress.status == ClashCharacterEventStageStatus.completed
            ? l10n.clashEventsStageReadAgain
            : l10n.clashEventsStageRead,
      ClashCharacterEventStageType.match =>
        progress.clearCount > 0
            ? l10n.clashEventsStageRepeat
            : l10n.clashEventsStagePrepare,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stage.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.xiTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stage.type == ClashCharacterEventStageType.story
                  ? l10n.clashEventsStageTypeStory
                  : l10n.clashEventsStageTypeMatch,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (progress.clearCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.clashEventsStageClearCount(progress.clearCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _rewardSummary(
                context,
                stage.firstClearRewards,
                l10n.clashEventsFirstClear,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            if (!stage.repeatRewards.isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _rewardSummary(
                  context,
                  stage.repeatRewards,
                  l10n.clashEventsRepeatRewards,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
            if (onPrimaryAction != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onPrimaryAction,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rewardSummary(
    BuildContext context,
    ClashCharacterEventReward reward,
    String prefix,
  ) {
    final l10n = context.l10n;
    if (reward.isEmpty) {
      return '$prefix: —';
    }
    final parts = <String>[];
    if (reward.coins > 0) {
      parts.add(l10n.clashAchievementsRewardCoins(reward.coins));
    }
    if (reward.gems > 0) {
      parts.add(l10n.clashAchievementsRewardGems(reward.gems));
    }
    if (reward.expMaterial != null) {
      parts.add(
        l10n.clashShopGrantLine(
          reward.expMaterial!.id,
          reward.expMaterial!.quantity,
        ),
      );
    }
    if (reward.techniqueBook != null) {
      parts.add(
        l10n.clashShopGrantLine(
          reward.techniqueBook!.id,
          reward.techniqueBook!.quantity,
        ),
      );
    }
    if (reward.featuredCardId != null) {
      parts.add(reward.featuredCardId!);
    }
    return '$prefix: ${parts.join(' · ')}';
  }
}

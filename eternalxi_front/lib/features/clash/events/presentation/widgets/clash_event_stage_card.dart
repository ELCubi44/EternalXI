import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_labels.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_reward_preview.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:flutter/material.dart';

class ClashEventStageCard extends StatelessWidget {
  const ClashEventStageCard({
    super.key,
    required this.progress,
    required this.stageNumber,
    required this.onPrimaryAction,
  });

  final ClashCharacterEventStageProgress progress;
  final int stageNumber;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stage = progress.stage;
    final isLocked = progress.status == ClashCharacterEventStageStatus.locked;
    final isCompleted =
        progress.status == ClashCharacterEventStageStatus.completed;
    final firstClearClaimed = progress.clearCount > 0;

    final borderColor = isCompleted
        ? Colors.green.withValues(alpha: 0.5)
        : isLocked
        ? context.xiDivider
        : theme.colorScheme.primary.withValues(alpha: 0.5);

    final actionLabel = clashEventStageActionLabel(
      stage: stage,
      progress: progress,
      l10n: l10n,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isLocked ? 1 : 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isCompleted
                      ? Colors.green.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    '$stageNumber',
                    style: theme.textTheme.titleSmall?.copyWith(
                      ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ClashStoryLevelStatusChip(
                            label: clashEventStageTypeLabel(stage.type, l10n),
                            kind: ClashStoryLevelChipKind.type,
                          ),
                          ClashStoryLevelStatusChip(
                            label: clashEventStageStatusLabel(
                              progress.status,
                              l10n,
                            ),
                            kind: ClashStoryLevelChipKind.status,
                          ),
                          if (progress.clearCount > 0)
                            ClashStoryLevelStatusChip(
                              label: l10n.clashEventsCompletedTimes(
                                progress.clearCount,
                              ),
                              kind: ClashStoryLevelChipKind.firstClearClaimed,
                            )
                          else if (stage.type ==
                              ClashCharacterEventStageType.match)
                            ClashStoryLevelStatusChip(
                              label: l10n.clashEventsRepeatable,
                              kind: ClashStoryLevelChipKind.firstClear,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!stage.firstClearRewards.isEmpty) ...[
              const SizedBox(height: 12),
              ClashEventRewardPreview(
                title: l10n.clashEventsFirstClear,
                rewards: stage.firstClearRewards,
                muted: firstClearClaimed,
              ),
            ],
            if (!stage.repeatRewards.isEmpty) ...[
              const SizedBox(height: 8),
              ClashEventRewardPreview(
                title: l10n.clashEventsRepeatRewards,
                rewards: stage.repeatRewards,
              ),
            ],
            if (isLocked) ...[
              const SizedBox(height: 12),
              Text(
                l10n.clashStoryCompletePreviousLevel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: onPrimaryAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

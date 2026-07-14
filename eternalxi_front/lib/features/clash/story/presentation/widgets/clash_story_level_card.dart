import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_labels.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_reward_preview.dart';
import 'package:flutter/material.dart';

/// Tarjeta visual de un nivel en el mapa de historia (Fase 49).
class ClashStoryLevelCard extends StatelessWidget {
  const ClashStoryLevelCard({
    required this.level,
    required this.status,
    required this.progress,
    required this.onAction,
    super.key,
  });

  final ClashStoryLevel level;
  final ClashStoryLevelStatus status;
  final ClashStoryProgress progress;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLocked = status == ClashStoryLevelStatus.locked;
    final isCompleted = status == ClashStoryLevelStatus.completed;
    final rewardsClaimed = progress.areRewardsClaimed(level.id);

    final borderColor = isCompleted
        ? Colors.green.withValues(alpha: 0.5)
        : isLocked
        ? context.xiDivider
        : theme.colorScheme.primary.withValues(alpha: 0.5);

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
                    '${level.order}',
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
                        level.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.xiTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock_rounded,
                    color: context.xiTextSecondary.withValues(alpha: 0.7),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ClashStoryLevelStatusChip(
                  label: clashStoryLevelTypeLabel(level.type, l10n),
                  kind: ClashStoryLevelChipKind.type,
                ),
                ClashStoryLevelStatusChip(
                  label: clashStoryLevelStatusLabel(status, l10n),
                  kind: ClashStoryLevelChipKind.status,
                ),
                if (!level.rewards.isEmpty ||
                    level.rewards.starterRosterKey != null)
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
            if (!level.rewards.isEmpty ||
                level.rewards.starterRosterKey != null) ...[
              const SizedBox(height: 12),
              ClashStoryRewardPreview(
                rewards: level.rewards,
                muted: rewardsClaimed,
              ),
            ],
            if (level.matchObjectives.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ObjectivesPreview(objectives: level.matchObjectives),
            ],
            if (isLocked) ...[
              const SizedBox(height: 12),
              Text(
                l10n.clashStoryCompletePreviousLevel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAction,
              child: Text(
                clashStoryLevelActionLabel(
                  type: level.type,
                  status: status,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectivesPreview extends StatelessWidget {
  const _ObjectivesPreview({required this.objectives});

  final List<ClashMatchObjective> objectives;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.clashMatchObjectivesTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            ),
        ),
        const SizedBox(height: 6),
        for (final objective in objectives)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    objective.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

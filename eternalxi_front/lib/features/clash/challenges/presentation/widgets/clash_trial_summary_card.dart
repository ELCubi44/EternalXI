import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial_line.dart';
import 'package:flutter/material.dart';

class ClashTrialSummaryCard extends StatelessWidget {
  const ClashTrialSummaryCard({
    required this.summary,
    this.onTap,
    super.key,
  });

  final ClashTrialSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trial = summary.trial;
    final line = trial.line;
    final progress = summary.totalFloors == 0
        ? 0.0
        : summary.completedFloors / summary.totalFloors;

    return Material(
      color: context.xiCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.xiDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(line.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trial.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${summary.completedFloors}/${summary.totalFloors}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                trial.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: context.xiDivider,
                ),
              ),
              if (summary.bestClearCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'R�cord �${summary.bestClearCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ClashTrialFloorTile extends StatelessWidget {
  const ClashTrialFloorTile({
    required this.progress,
    required this.line,
    this.onTap,
    super.key,
  });

  final ClashTrialFloorProgress progress;
  final ClashTrialLine line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final floor = progress.floor;
    final locked = progress.status == ClashTrialFloorStatus.locked;
    final completed = progress.status == ClashTrialFloorStatus.completed;

    return Material(
      color: context.xiCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.xiDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked || onTap == null ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: locked
                    ? context.xiDivider
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  locked
                      ? Icons.lock_rounded
                      : completed
                      ? Icons.check_rounded
                      : line.icon,
                  size: 18,
                  color: locked
                      ? context.xiTextSecondary
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(floor.title, style: theme.textTheme.titleSmall),
                    Text(
                      'Poder ${progress.scaledPower} � ST bonus ${floor.techniqueBonusTarget}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                    if (progress.clearCount > 0)
                      Text(
                        'Completado �${progress.clearCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.xiTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!locked)
                Icon(Icons.chevron_right_rounded, color: context.xiTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

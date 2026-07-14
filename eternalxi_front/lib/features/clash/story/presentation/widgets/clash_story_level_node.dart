import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_labels.dart';
import 'package:flutter/material.dart';

class ClashStoryLevelNode extends StatelessWidget {
  const ClashStoryLevelNode({
    required this.level,
    required this.status,
    this.onTap,
    super.key,
  });

  final ClashStoryLevel level;
  final ClashStoryLevelStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLocked = status == ClashStoryLevelStatus.locked;
    final isCompleted = status == ClashStoryLevelStatus.completed;

    final borderColor = isCompleted
        ? Colors.green.withValues(alpha: 0.55)
        : isLocked
        ? context.xiDivider
        : theme.colorScheme.primary.withValues(alpha: 0.55);

    return Material(
      color: context.xiCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: isLocked ? 1 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: isLocked ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isCompleted
                          ? Colors.green.withValues(alpha: 0.15)
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
                          Text(
                            clashStoryLevelStatusLabel(status, l10n),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isCompleted
                                  ? Colors.green
                                  : context.xiTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLocked)
                      Icon(
                        Icons.lock_rounded,
                        color: context.xiTextSecondary.withValues(alpha: 0.6),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  level.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(clashStoryLevelTypeLabel(level.type, l10n)),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      avatar: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text('${level.energyCost}'),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (level.rewards.gems > 0)
                      Chip(
                        avatar: const Icon(Icons.diamond_rounded, size: 16),
                        label: Text('${level.rewards.gems}'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:eternal_xi/features/clash/help/presentation/widgets/clash_help_labels.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:flutter/material.dart';

class ClashHelpTopicCard extends StatelessWidget {
  const ClashHelpTopicCard({
    required this.topic,
    required this.onRead,
    super.key,
  });

  final ClashHelpTopic topic;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
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
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(
                    clashHelpIconForName(topic.icon),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          ),
                      ),
                      const SizedBox(height: 6),
                      ClashStoryLevelStatusChip(
                        label: clashHelpCategoryLabel(topic.category, l10n),
                        kind: ClashStoryLevelChipKind.status,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              topic.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onRead,
                child: Text(l10n.clashHelpRead),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

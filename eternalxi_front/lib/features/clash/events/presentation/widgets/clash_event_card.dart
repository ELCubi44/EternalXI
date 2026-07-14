import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_status.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_featured_card_section.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_reward_preview.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:flutter/material.dart';

class ClashEventCard extends StatelessWidget {
  const ClashEventCard({
    super.key,
    required this.summary,
    required this.onEnter,
    this.featuredCardName,
  });

  final ClashCharacterEventSummary summary;
  final VoidCallback onEnter;
  final String? featuredCardName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final event = summary.event;
    final total = summary.totalStages;
    final completed = summary.completedStages;
    final progress = total <= 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: summary.isAvailable
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : context.xiDivider,
          width: summary.isAvailable ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.characterName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.isAvailable)
                  ClashStoryLevelStatusChip(
                    label: l10n.clashEventsStageAvailable,
                    kind: ClashStoryLevelChipKind.status,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.clashEventsProgress(completed, total),
              style: theme.textTheme.labelLarge?.copyWith(
                ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                color: theme.colorScheme.primary,
              ),
            ),
            if (event.featuredCardId != null) ...[
              const SizedBox(height: 12),
              ClashEventFeaturedCardSection(
                cardId: event.featuredCardId!,
                cardName: featuredCardName,
                compact: true,
              ),
            ],
            if (event.stages.isNotEmpty &&
                !event.stages.first.firstClearRewards.isEmpty) ...[
              const SizedBox(height: 12),
              ClashEventRewardPreview(
                title: l10n.clashEventsFirstClear,
                rewards: event.stages.first.firstClearRewards,
                muted: true,
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed:
                    summary.isAvailable &&
                        event.status ==
                            ClashCharacterEventAvailability.available
                    ? onEnter
                    : null,
                child: Text(l10n.clashEventsEnter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

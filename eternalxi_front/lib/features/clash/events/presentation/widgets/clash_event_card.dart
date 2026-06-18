import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:flutter/material.dart';

class ClashEventCard extends StatelessWidget {
  const ClashEventCard({
    super.key,
    required this.summary,
    required this.onEnter,
  });

  final ClashCharacterEventSummary summary;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final event = summary.event;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.characterName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.clashEventsProgress(
                summary.completedStages,
                summary.totalStages,
              ),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: summary.isAvailable ? onEnter : null,
                child: Text(l10n.clashEventsEnter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

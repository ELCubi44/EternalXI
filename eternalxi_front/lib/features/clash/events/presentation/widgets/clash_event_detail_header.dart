import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_featured_card_section.dart';
import 'package:flutter/material.dart';

/// Cabecera del detalle de evento de personaje (Fase 50).
class ClashEventDetailHeader extends StatelessWidget {
  const ClashEventDetailHeader({
    required this.event,
    required this.completedStages,
    this.featuredCardName,
    this.featuredCardRarity,
    super.key,
  });

  final ClashCharacterEvent event;
  final int completedStages;
  final String? featuredCardName;
  final String? featuredCardRarity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = event.stages.length;
    final progress = total <= 0 ? 0.0 : completedStages / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          event.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            ),
        ),
        const SizedBox(height: 6),
        Text(
          event.characterName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          event.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.xiTextSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.clashEventsProgress(completedStages, total),
          style: theme.textTheme.titleSmall?.copyWith(
            ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.35,
            ),
            color: theme.colorScheme.primary,
          ),
        ),
        if (event.featuredCardId != null) ...[
          const SizedBox(height: 16),
          ClashEventFeaturedCardSection(
            cardId: event.featuredCardId!,
            cardName: featuredCardName,
            rarityLabel: featuredCardRarity,
          ),
        ],
      ],
    );
  }
}

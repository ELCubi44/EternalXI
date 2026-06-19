import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Sección de carta destacada en evento (Fase 50).
class ClashEventFeaturedCardSection extends StatelessWidget {
  const ClashEventFeaturedCardSection({
    required this.cardId,
    this.cardName,
    this.rarityLabel,
    this.compact = false,
    super.key,
  });

  final String cardId;
  final String? cardName;
  final String? rarityLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final displayName = cardName ?? cardId;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashEventsFeaturedCardTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.xiTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: compact ? 18 : 22,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                child: Icon(
                  Icons.style_outlined,
                  color: theme.colorScheme.primary,
                  size: compact ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (rarityLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        rarityLabel!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashEventsFirstTimeCard,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.clashEventsRepeatDuplicates,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

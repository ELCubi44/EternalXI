import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/shared/widgets/reward_cards_icon.dart';
import 'package:flutter/material.dart';

class RewardsSummaryHeader extends StatelessWidget {
  const RewardsSummaryHeader({
    super.key,
    required this.summary,
    required this.leagueName,
  });

  final RewardSummaryModel summary;
  final String leagueName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rl10n = context.rewardsL10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leagueName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _ChipStat(
            leading: const RewardCardsIcon(size: 22),
            label: rl10n.cardsAvailable,
            value: '${summary.cartasDisponibles}',
          ),
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({
    this.icon,
    this.leading,
    required this.label,
    required this.value,
  }) : assert(icon != null || leading != null);

  final IconData? icon;
  final Widget? leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          leading ??
              Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

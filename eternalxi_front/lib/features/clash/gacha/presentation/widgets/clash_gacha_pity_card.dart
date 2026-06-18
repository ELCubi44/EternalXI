import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:flutter/material.dart';

class ClashGachaPityCard extends StatelessWidget {
  const ClashGachaPityCard({required this.pityState, super.key});

  final ClashGachaPityState pityState;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final nearPity = pityState.isNearPity;
    final borderColor = nearPity
        ? theme.colorScheme.primary
        : context.xiDivider;
    final background = nearPity
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
        : context.xiCardSurface;
    final ratio = pityState.threshold <= 0
        ? 0.0
        : (pityState.pullsSinceLastPity / pityState.threshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: nearPity ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 18,
                color: nearPity
                    ? theme.colorScheme.primary
                    : context.xiTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashGachaPityProgress(
                    pityState.pullsSinceLastPity,
                    pityState.threshold,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: nearPity ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              Text(
                '${pityState.pullsSinceLastPity}/${pityState.threshold}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: nearPity ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: context.xiChipBackground,
              color: nearPity
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashGachaPityRemaining(pityState.pullsRemaining),
            style: theme.textTheme.bodySmall?.copyWith(
              color: nearPity
                  ? theme.colorScheme.primary
                  : context.xiTextSecondary,
              fontWeight: nearPity ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class ClashGachaResultChip extends StatelessWidget {
  const ClashGachaResultChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

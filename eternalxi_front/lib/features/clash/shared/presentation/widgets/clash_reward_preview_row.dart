import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Fila compacta de recompensas en chips (Fase 40).
class ClashRewardPreviewRow extends StatelessWidget {
  const ClashRewardPreviewRow({required this.rewards, super.key});

  final List<String> rewards;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.clashEngagementRewardsLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final reward in rewards)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.xiChipBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.xiDivider),
                ),
                child: Text(
                  reward,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

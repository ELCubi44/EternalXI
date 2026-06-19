import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Bloque de rival/dificultad en preparación de partido (Fase 42).
class ClashMatchRivalPrepareSection extends StatelessWidget {
  const ClashMatchRivalPrepareSection({
    required this.rivalName,
    this.difficulty,
    this.recommendedPower,
    super.key,
  });

  final String? rivalName;
  final int? difficulty;
  final int? recommendedPower;

  @override
  Widget build(BuildContext context) {
    if (rivalName == null && difficulty == null && recommendedPower == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rivalName != null)
          _InfoTile(label: l10n.clashMatchPrepareRival, value: rivalName!),
        if (recommendedPower != null)
          _InfoTile(
            label: l10n.clashMatchPrepareRecommendedPower,
            value: '$recommendedPower',
          ),
        if (difficulty != null) ...[
          const SizedBox(height: 4),
          Chip(
            label: Text(l10n.clashMatchPrepareDifficulty(difficulty!)),
            backgroundColor: context.xiCardSurface,
            side: BorderSide(color: context.xiDivider),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

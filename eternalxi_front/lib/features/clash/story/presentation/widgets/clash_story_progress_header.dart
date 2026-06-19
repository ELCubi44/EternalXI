import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Cabecera de progreso general en el mapa de historia (Fase 49).
class ClashStoryProgressHeader extends StatelessWidget {
  const ClashStoryProgressHeader({
    required this.completedLevels,
    required this.totalLevels,
    required this.chapterTitle,
    super.key,
  });

  final int completedLevels;
  final int totalLevels;
  final String chapterTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = totalLevels <= 0 ? 0.0 : completedLevels / totalLevels;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashStoryProgressTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.xiTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.clashStoryLevelsProgress(completedLevels, totalLevels),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 12),
          Text(
            l10n.clashStoryCurrentChapter,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.xiTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            chapterTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

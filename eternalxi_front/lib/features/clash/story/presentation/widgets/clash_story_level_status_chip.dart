import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

enum ClashStoryLevelChipKind { type, status, firstClear, firstClearClaimed }

/// Chip consistente para tipo/estado de nivel story (Fase 49).
class ClashStoryLevelStatusChip extends StatelessWidget {
  const ClashStoryLevelStatusChip({
    required this.label,
    required this.kind,
    super.key,
  });

  final String label;
  final ClashStoryLevelChipKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg, Color border) = switch (kind) {
      ClashStoryLevelChipKind.type => (
        theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: 0.25),
      ),
      ClashStoryLevelChipKind.status => (
        context.xiCardSurface,
        context.xiTextSecondary,
        context.xiDivider,
      ),
      ClashStoryLevelChipKind.firstClear => (
        Colors.amber.withValues(alpha: 0.12),
        Colors.amber.shade800,
        Colors.amber.withValues(alpha: 0.35),
      ),
      ClashStoryLevelChipKind.firstClearClaimed => (
        Colors.green.withValues(alpha: 0.1),
        Colors.green.shade700,
        Colors.green.withValues(alpha: 0.3),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

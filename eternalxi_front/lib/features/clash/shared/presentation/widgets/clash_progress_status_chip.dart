import 'package:flutter/material.dart';

enum ClashProgressStatus { inProgress, claimable, claimed }

/// Chip de estado para misiones, logros y regalos (Fase 40).
class ClashProgressStatusChip extends StatelessWidget {
  const ClashProgressStatusChip({
    required this.label,
    required this.status,
    super.key,
  });

  final String label;
  final ClashProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg) = switch (status) {
      ClashProgressStatus.inProgress => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
      ClashProgressStatus.claimable => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      ClashProgressStatus.claimed => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Cabecera de progreso para misiones, logros y regalos (Fase 40).
class ClashProgressSummaryCard extends StatelessWidget {
  const ClashProgressSummaryCard({
    this.hint,
    this.secondaryHint,
    required this.lines,
    this.progress,
    this.action,
    super.key,
  });

  final String? hint;
  final String? secondaryHint;
  final List<String> lines;
  final double? progress;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: context.xiTextSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (secondaryHint != null) ...[
            Text(
              secondaryHint!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.xiTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final line in lines) ...[
            Text(
              line,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (line != lines.last) const SizedBox(height: 4),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

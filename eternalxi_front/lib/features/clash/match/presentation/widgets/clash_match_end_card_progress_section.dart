import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:flutter/material.dart';

/// Progreso de cartas tras el partido (Fase 48).
class ClashMatchEndCardProgressSection extends StatelessWidget {
  const ClashMatchEndCardProgressSection({required this.results, super.key});

  final List<ClashCardXpResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final totalXp = results.fold<int>(0, (sum, r) => sum + r.xpGained);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashMatchCardProgressTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            ),
        ),
        if (results.length > 1 && totalXp > 0) ...[
          const SizedBox(height: 4),
          Text(
            l10n.clashMatchLineupXpTotal(totalXp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        ...results.map((result) => _CardProgressRow(result: result)),
      ],
    );
  }
}

class _CardProgressRow extends StatelessWidget {
  const _CardProgressRow({required this.result});

  final ClashCardXpResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final levelText = result.didLevelUp
        ? l10n.clashMatchCardLevelFromTo(result.previousLevel, result.newLevel)
        : l10n.clashMatchCardLevelSame(result.newLevel);
    final progress = _progressValue(result);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: result.didLevelUp
            ? Colors.amber.withValues(alpha: 0.08)
            : context.xiCardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: result.didLevelUp
              ? Colors.amber.withValues(alpha: 0.35)
              : context.xiDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.didLevelUp
                    ? Icons.arrow_circle_up_rounded
                    : Icons.person_rounded,
                size: 20,
                color: result.didLevelUp
                    ? Colors.amber.shade700
                    : context.xiTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.cardName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    ),
                ),
              ),
              Text(
                l10n.clashMatchCardXpGained(result.xpGained),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            levelText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: result.didLevelUp
                  ? Colors.amber.shade800
                  : context.xiTextSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (result.reachedMaxLevel && result.xpGained == 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.clashCardMaxLevel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  double? _progressValue(ClashCardXpResult result) {
    if (result.reachedMaxLevel && result.xpGained == 0) {
      return 1;
    }
    if (result.newXp <= result.previousXp) {
      return null;
    }
    final delta = result.newXp - result.previousXp;
    final span = result.newXp + delta;
    if (span <= 0) {
      return null;
    }
    return (result.newXp / span).clamp(0.05, 1.0);
  }
}

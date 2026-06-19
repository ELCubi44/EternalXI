import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objective_failure_hint.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objective_reward_preview.dart';
import 'package:flutter/material.dart';

/// Objetivos finales del partido (Fase 48).
class ClashMatchEndObjectivesSection extends StatelessWidget {
  const ClashMatchEndObjectivesSection({
    required this.objectiveResults,
    required this.state,
    required this.userWon,
    super.key,
  });

  final List<ClashMatchObjectiveProgress> objectiveResults;
  final MatchState state;
  final bool userWon;

  @override
  Widget build(BuildContext context) {
    if (objectiveResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashMatchObjectivesTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...objectiveResults.map(
          (result) =>
              _ObjectiveEndRow(result: result, state: state, userWon: userWon),
        ),
      ],
    );
  }
}

class _ObjectiveEndRow extends StatelessWidget {
  const _ObjectiveEndRow({
    required this.result,
    required this.state,
    required this.userWon,
  });

  final ClashMatchObjectiveProgress result;
  final MatchState state;
  final bool userWon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final completed = userWon && result.completed;
    final color = completed ? Colors.green : Colors.red.shade300;
    final icon = completed ? Icons.check_circle_rounded : Icons.cancel_outlined;
    final rewardText = clashMatchObjectiveRewardPreview(
      context,
      result.objective.rewards,
    );
    final failureHint = ClashMatchObjectiveFailureHint.resolve(
      l10n: l10n,
      objective: result.objective,
      state: state,
      userWon: userWon,
      completed: completed,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: completed
            ? Colors.green.withValues(alpha: 0.08)
            : context.xiCardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: completed
              ? Colors.green.withValues(alpha: 0.35)
              : context.xiDivider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.objective.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  completed
                      ? l10n.clashMatchObjectiveCompleted
                      : l10n.clashMatchObjectiveIncomplete,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (rewardText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rewardText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (failureHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    failureHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

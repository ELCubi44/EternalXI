import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_live_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_live_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objective_reward_preview.dart';
import 'package:flutter/material.dart';

/// Objetivos secundarios visibles durante el partido 7v7 (Fase 47).
class ClashMatchObjectivesPanel extends StatelessWidget {
  const ClashMatchObjectivesPanel({
    required this.objectives,
    required this.state,
    this.showEmptyPlaceholder = false,
    super.key,
  });

  final List<ClashMatchObjective> objectives;
  final MatchState state;
  final bool showEmptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) {
      if (!showEmptyPlaceholder) {
        return const SizedBox.shrink();
      }
      return _EmptyPanel();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashMatchObjectivesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              ),
          ),
          const SizedBox(height: 8),
          ...objectives.map(
            (objective) => _ObjectiveLiveRow(
              objective: objective,
              status: ClashMatchObjectiveLiveResolver.resolve(
                objective: objective,
                state: state,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Text(
        l10n.clashMatchObjectivesNone,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.xiTextSecondary,
        ),
      ),
    );
  }
}

class _ObjectiveLiveRow extends StatelessWidget {
  const _ObjectiveLiveRow({required this.objective, required this.status});

  final ClashMatchObjective objective;
  final ClashMatchObjectiveLiveStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final statusLabel = _statusLabel(l10n, status);
    final statusColor = _statusColor(context, status);
    final rewardText = clashMatchObjectiveRewardPreview(
      context,
      objective.rewards,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(status), size: 20, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    ),
                ),
                if (objective.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    objective.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ],
                if (rewardText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rewardText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, ClashMatchObjectiveLiveStatus s) {
    return switch (s) {
      ClashMatchObjectiveLiveStatus.pending =>
        l10n.clashMatchObjectiveStatusPending,
      ClashMatchObjectiveLiveStatus.inProgress =>
        l10n.clashMatchObjectiveStatusInProgress,
      ClashMatchObjectiveLiveStatus.completed =>
        l10n.clashMatchObjectiveStatusCompleted,
      ClashMatchObjectiveLiveStatus.failed =>
        l10n.clashMatchObjectiveStatusFailed,
      ClashMatchObjectiveLiveStatus.reviewedAtEnd =>
        l10n.clashMatchObjectiveStatusReviewedAtEnd,
    };
  }

  Color _statusColor(BuildContext context, ClashMatchObjectiveLiveStatus s) {
    return switch (s) {
      ClashMatchObjectiveLiveStatus.completed => Colors.green,
      ClashMatchObjectiveLiveStatus.failed => Colors.redAccent,
      ClashMatchObjectiveLiveStatus.inProgress => Theme.of(
        context,
      ).colorScheme.primary,
      ClashMatchObjectiveLiveStatus.reviewedAtEnd => context.xiTextSecondary,
      ClashMatchObjectiveLiveStatus.pending => context.xiTextSecondary,
    };
  }

  IconData _statusIcon(ClashMatchObjectiveLiveStatus s) {
    return switch (s) {
      ClashMatchObjectiveLiveStatus.completed => Icons.check_circle_rounded,
      ClashMatchObjectiveLiveStatus.failed => Icons.cancel_rounded,
      ClashMatchObjectiveLiveStatus.inProgress => Icons.timelapse_rounded,
      ClashMatchObjectiveLiveStatus.reviewedAtEnd =>
        Icons.hourglass_empty_rounded,
      ClashMatchObjectiveLiveStatus.pending => Icons.radio_button_unchecked,
    };
  }
}

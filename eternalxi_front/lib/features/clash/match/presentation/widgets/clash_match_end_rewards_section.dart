import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Recompensas obtenidas y pendientes al final del partido (Fase 48 / 58).
class ClashMatchEndRewardsObtainedSection extends StatelessWidget {
  const ClashMatchEndRewardsObtainedSection.story({
    required this.rewards,
    super.key,
  }) : eventReward = null;

  const ClashMatchEndRewardsObtainedSection.event({
    required ClashCharacterEventReward reward,
    super.key,
  }) : rewards = null,
       eventReward = reward;

  final ClashStoryReward? rewards;
  final ClashCharacterEventReward? eventReward;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = rewards != null
        ? ClashRewardDisplayBuilder.fromStoryReward(rewards!, l10n)
        : ClashRewardDisplayBuilder.fromCharacterEventReward(
            eventReward!,
            l10n,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashMatchRewardsEarnedTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            l10n.clashMatchRewardsEmptyState,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          )
        else
          ClashRewardList(items: items, layout: ClashRewardListLayout.column),
      ],
    );
  }
}

class ClashMatchEndPendingRewardsSection extends StatelessWidget {
  const ClashMatchEndPendingRewardsSection({
    required this.objectiveResults,
    required this.userWon,
    super.key,
  });

  final List<ClashMatchObjectiveProgress> objectiveResults;
  final bool userWon;

  @override
  Widget build(BuildContext context) {
    if (!userWon) {
      return const SizedBox.shrink();
    }

    final pendingObjectives = objectiveResults
        .where((r) => !r.completed && !r.objective.rewards.isEmpty)
        .toList();
    if (pendingObjectives.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final merged = ClashMatchObjectiveEvaluator.mergeRewards(
      pendingObjectives.map((r) => r.objective.rewards),
    );
    final items = ClashRewardDisplayBuilder.fromStoryReward(merged, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          l10n.clashMatchRewardsPendingTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.clashMatchObjectiveRetryHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (final objective in pendingObjectives)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${objective.objective.title}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          ClashRewardList(
            items: items,
            muted: true,
            layout: ClashRewardListLayout.column,
          ),
        ],
      ],
    );
  }
}

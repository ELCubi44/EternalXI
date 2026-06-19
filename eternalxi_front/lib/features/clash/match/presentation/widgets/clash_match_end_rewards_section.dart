import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Recompensas obtenidas y pendientes al final del partido (Fase 48).
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
    final lines = rewards != null
        ? _storyLines(context, rewards!)
        : _eventLines(context, eventReward!);

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
        if (lines.isEmpty)
          Text(
            l10n.clashMatchRewardsEmptyState,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          )
        else
          ...lines.map((line) => _RewardLineTile(line: line)),
      ],
    );
  }

  static List<_RewardLine> _storyLines(
    BuildContext context,
    ClashStoryReward rewards,
  ) {
    final l10n = context.l10n;
    final lines = <_RewardLine>[];
    if (rewards.gems > 0) {
      lines.add(
        _RewardLine(
          Icons.diamond_outlined,
          l10n.clashMatchRewardGems(rewards.gems),
        ),
      );
    }
    if (rewards.coins > 0) {
      lines.add(
        _RewardLine(
          Icons.monetization_on_outlined,
          l10n.clashMatchRewardCoins(rewards.coins),
        ),
      );
    }
    for (final item in rewards.items) {
      lines.add(
        _RewardLine(
          Icons.inventory_2_outlined,
          '${item.name} x${item.quantity}',
        ),
      );
    }
    for (final material in rewards.materials) {
      lines.add(
        _RewardLine(
          Icons.science_outlined,
          '${material.name} x${material.quantity}',
        ),
      );
    }
    if (rewards.cardIds.isNotEmpty) {
      lines.add(
        _RewardLine(
          Icons.style_outlined,
          l10n.clashMatchRewardCards(rewards.cardIds.length),
        ),
      );
    }
    return lines;
  }

  static List<_RewardLine> _eventLines(
    BuildContext context,
    ClashCharacterEventReward reward,
  ) {
    final l10n = context.l10n;
    final lines = <_RewardLine>[];
    if (reward.gems > 0) {
      lines.add(
        _RewardLine(
          Icons.diamond_outlined,
          l10n.clashMatchRewardGems(reward.gems),
        ),
      );
    }
    if (reward.coins > 0) {
      lines.add(
        _RewardLine(
          Icons.monetization_on_outlined,
          l10n.clashMatchRewardCoins(reward.coins),
        ),
      );
    }
    if (reward.expMaterial != null) {
      lines.add(
        _RewardLine(
          Icons.science_outlined,
          l10n.clashShopGrantLine(
            reward.expMaterial!.id,
            reward.expMaterial!.quantity,
          ),
        ),
      );
    }
    if (reward.techniqueBook != null) {
      lines.add(
        _RewardLine(
          Icons.menu_book_outlined,
          l10n.clashShopGrantLine(
            reward.techniqueBook!.id,
            reward.techniqueBook!.quantity,
          ),
        ),
      );
    }
    if (reward.ticket != null) {
      lines.add(
        _RewardLine(
          Icons.confirmation_number_outlined,
          l10n.clashShopGrantLine(reward.ticket!.id, reward.ticket!.quantity),
        ),
      );
    }
    if (reward.featuredCardId != null) {
      lines.add(_RewardLine(Icons.person_outline, reward.featuredCardId!));
    }
    return lines;
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
    final lines = ClashMatchEndRewardsObtainedSection._storyLines(
      context,
      merged,
    );

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
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...lines.map((line) => _RewardLineTile(line: line, muted: true)),
        ],
      ],
    );
  }
}

class _RewardLine {
  const _RewardLine(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _RewardLineTile extends StatelessWidget {
  const _RewardLineTile({required this.line, this.muted = false});

  final _RewardLine line;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            line.icon,
            size: 18,
            color: muted
                ? context.xiTextSecondary
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: muted ? context.xiTextSecondary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

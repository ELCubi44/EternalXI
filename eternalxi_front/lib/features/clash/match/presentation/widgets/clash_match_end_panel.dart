import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Resumen de fin de partido 7vs7 (Fase 15).
class ClashMatchEndPanel extends StatelessWidget {
  const ClashMatchEndPanel({
    required this.state,
    required this.level,
    required this.onViewRewards,
    required this.onRetry,
    required this.onBackToMap,
    super.key,
  });

  final MatchState state;
  final ClashStoryLevel level;
  final VoidCallback onViewRewards;
  final VoidCallback onRetry;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userWon = state.winner == MatchTeamSide.user;
    final rewards = level.rewards;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: userWon
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.redAccent.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            userWon ? l10n.clashMatchVictory : l10n.clashMatchDefeat,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: userWon ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashMatchFinalScore(state.score.user, state.score.rival),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (userWon) ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashMatchLevelCompleted(level.title),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _RewardsSummary(rewards: rewards),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onViewRewards,
              child: Text(l10n.clashMatchViewRewards),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashMatchNoRewards,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: Text(l10n.clashMatchRetry)),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onBackToMap,
            child: Text(l10n.clashStoryBackToMap),
          ),
        ],
      ),
    );
  }
}

class _RewardsSummary extends StatelessWidget {
  const _RewardsSummary({required this.rewards});

  final ClashStoryReward rewards;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (rewards.isEmpty) {
      return Text(
        l10n.clashMatchRewardsBasic,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.xiTextSecondary,
        ),
      );
    }

    final lines = <String>[];
    if (rewards.gems > 0) {
      lines.add(l10n.clashMatchRewardGems(rewards.gems));
    }
    if (rewards.coins > 0) {
      lines.add(l10n.clashMatchRewardCoins(rewards.coins));
    }
    if (rewards.cardIds.isNotEmpty) {
      lines.add(l10n.clashMatchRewardCards(rewards.cardIds.length));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashMatchRewardsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

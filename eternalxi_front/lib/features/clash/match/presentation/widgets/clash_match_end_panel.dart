import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Resumen de fin de partido 7vs7 con objetivos (Fase 15–16) y EXP (Fase 17).
class ClashMatchEndPanel extends StatelessWidget {
  const ClashMatchEndPanel({
    required this.state,
    required this.level,
    required this.objectiveResults,
    required this.previewRewards,
    required this.previewCardXp,
    required this.onViewRewards,
    required this.onRetry,
    required this.onBackToMap,
    super.key,
  });

  final MatchState state;
  final ClashStoryLevel level;
  final List<ClashMatchObjectiveProgress> objectiveResults;
  final ClashStoryReward previewRewards;
  final List<ClashCardXpResult> previewCardXp;
  final VoidCallback onViewRewards;
  final VoidCallback onRetry;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userWon = state.winner == MatchTeamSide.user;

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
          if (objectiveResults.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l10n.clashMatchObjectivesTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...objectiveResults.map(
              (result) => _ObjectiveRow(result: result, userWon: userWon),
            ),
          ],
          if (userWon) ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashMatchLevelCompleted(level.title),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (previewCardXp.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CardXpSummary(results: previewCardXp),
            ],
            const SizedBox(height: 12),
            _RewardsSummary(rewards: previewRewards),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onViewRewards,
              child: Text(l10n.clashMatchViewRewards),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashMatchObjectivesDefeatHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.clashMatchNoCardXpOnDefeat,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
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

class _CardXpSummary extends StatelessWidget {
  const _CardXpSummary({required this.results});

  final List<ClashCardXpResult> results;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashMatchCardXpTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...results.map((result) {
          final levelText = result.didLevelUp
              ? l10n.clashMatchCardLevelUp(
                  result.previousLevel,
                  result.newLevel,
                )
              : l10n.clashMatchCardLevelSame(result.newLevel);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.didLevelUp
                      ? Icons.arrow_circle_up_rounded
                      : Icons.person_rounded,
                  size: 18,
                  color: result.didLevelUp
                      ? Colors.amber
                      : context.xiTextSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.cardName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.clashMatchCardXpGained(result.xpGained),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        levelText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: result.didLevelUp
                              ? Colors.amber.shade700
                              : context.xiTextSecondary,
                          fontWeight: result.didLevelUp
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (result.reachedMaxLevel && result.xpGained == 0)
                        Text(
                          l10n.clashCardMaxLevel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.xiTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({required this.result, required this.userWon});

  final ClashMatchObjectiveProgress result;
  final bool userWon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final completed = userWon && result.completed;
    final icon = completed ? Icons.check_circle : Icons.radio_button_unchecked;
    final color = completed ? Colors.green : context.xiTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.objective.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  completed
                      ? l10n.clashMatchObjectiveCompleted
                      : l10n.clashMatchObjectiveIncomplete,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
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
    for (final item in rewards.items) {
      lines.add('${item.name} x${item.quantity}');
    }
    for (final material in rewards.materials) {
      lines.add('${material.name} x${material.quantity}');
    }
    if (rewards.cardIds.isNotEmpty) {
      lines.add(l10n.clashMatchRewardCards(rewards.cardIds.length));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashMatchRewardsTotalTitle,
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

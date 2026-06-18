import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/material.dart';

class ClashEventMatchEndPanel extends StatelessWidget {
  const ClashEventMatchEndPanel({
    required this.state,
    required this.stageTitle,
    required this.previewReward,
    required this.previewCardXp,
    required this.onViewRewards,
    required this.onRetry,
    required this.onBack,
    super.key,
  });

  final MatchState state;
  final String stageTitle;
  final ClashCharacterEventReward previewReward;
  final List<ClashCardXpResult> previewCardXp;
  final VoidCallback onViewRewards;
  final VoidCallback onRetry;
  final VoidCallback onBack;

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
          if (userWon) ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashEventsStageCompletedTitle(stageTitle),
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
            _RewardsSummary(reward: previewReward),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onViewRewards,
              child: Text(l10n.clashMatchViewRewards),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashEventsMatchDefeatHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: Text(l10n.clashMatchRetry)),
          ],
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onBack, child: Text(l10n.clashEventsBack)),
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
        for (final result in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${result.cardName}: ${l10n.clashMatchCardXpGained(result.xpGained)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _RewardsSummary extends StatelessWidget {
  const _RewardsSummary({required this.reward});

  final ClashCharacterEventReward reward;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (reward.isEmpty) {
      return Text(
        l10n.clashMatchRewardsBasic,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.xiTextSecondary,
        ),
      );
    }

    final lines = <String>[];
    if (reward.gems > 0) {
      lines.add(l10n.clashMatchRewardGems(reward.gems));
    }
    if (reward.coins > 0) {
      lines.add(l10n.clashMatchRewardCoins(reward.coins));
    }
    if (reward.expMaterial != null) {
      lines.add(
        l10n.clashShopGrantLine(
          reward.expMaterial!.id,
          reward.expMaterial!.quantity,
        ),
      );
    }
    if (reward.techniqueBook != null) {
      lines.add(
        l10n.clashShopGrantLine(
          reward.techniqueBook!.id,
          reward.techniqueBook!.quantity,
        ),
      );
    }
    if (reward.featuredCardId != null) {
      lines.add(reward.featuredCardId!);
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
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

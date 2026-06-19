import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_card_progress_section.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_header.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_objectives_section.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_rewards_section.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Resumen de fin de partido 7vs7 (Fase 15–16, pulido Fase 48).
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
    final userWon = state.winner == MatchTeamSide.user;
    final subtitle = userWon
        ? l10n.clashMatchEndCompletedSubtitle
        : l10n.clashMatchEndNoRewards;

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          ClashMatchEndHeader(state: state, subtitle: subtitle),
          if (objectiveResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClashMatchEndObjectivesSection(
              objectiveResults: objectiveResults,
              state: state,
              userWon: userWon,
            ),
          ],
          if (userWon) ...[
            const SizedBox(height: 12),
            Text(
              l10n.clashMatchLevelCompleted(level.title),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ClashMatchEndRewardsObtainedSection.story(rewards: previewRewards),
            ClashMatchEndPendingRewardsSection(
              objectiveResults: objectiveResults,
              userWon: userWon,
            ),
            if (previewCardXp.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClashMatchEndCardProgressSection(results: previewCardXp),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onViewRewards,
              child: Text(l10n.clashMatchContinue),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.clashMatchRetry),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              l10n.clashMatchObjectivesDefeatHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.clashMatchNoCardXpOnDefeat,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.clashMatchRetry)),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onBackToMap,
            child: Text(l10n.clashStoryBackToMap),
          ),
        ],
        ),
      ),
    );
  }
}

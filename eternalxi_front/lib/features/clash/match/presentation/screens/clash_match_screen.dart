import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_halftime_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_turn_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_pass_sheet.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_status_banner.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_reward_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashMatchScreen extends StatefulWidget {
  const ClashMatchScreen({required this.levelId, super.key});

  final String levelId;

  @override
  State<ClashMatchScreen> createState() => _ClashMatchScreenState();
}

class _ClashMatchScreenState extends State<ClashMatchScreen> {
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final story = context.read<ClashStoryController>();
    final lineups = context.read<ClashLineupsController>();
    final match = context.read<ClashMatchController>();

    if (story.state == ClashStoryLoadState.idle) {
      await story.load();
    }
    if (lineups.state == ClashLineupsLoadState.idle) {
      await lineups.load();
    }

    final ok = await story.prepareLevel(widget.levelId);
    if (!mounted) {
      return;
    }
    if (!ok) {
      context.go(AppRoutes.clashStory);
      return;
    }

    final kit = await ClashMatchController.loadDefaultMatchKit();
    if (!mounted) {
      return;
    }

    match.startMatch(
      levelId: widget.levelId,
      lineup: lineups.activeLineup,
      catalogById: lineups.catalogById,
      matchInventory: kit,
    );
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  Future<void> _onViewRewards() async {
    final story = context.read<ClashStoryController>();
    final match = context.read<ClashMatchController>();
    final state = match.state;
    if (state == null || !state.isFinished) {
      return;
    }

    final userWon = state.winner == MatchTeamSide.user;
    final result = await story.finishMatchLevel(
      levelId: widget.levelId,
      userWon: userWon,
      matchState: state,
    );
    if (!mounted) {
      return;
    }

    if (userWon && result != null && result.firstCompletion) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ClashStoryController>.value(
            value: story,
            child: ClashStoryRewardScreen(levelId: widget.levelId),
          ),
        ),
      );
    }

    match.reset();
    if (mounted) {
      context.go(AppRoutes.clashStory);
    }
  }

  Future<void> _onRetry() async {
    final lineups = context.read<ClashLineupsController>();
    final match = context.read<ClashMatchController>();
    final kit = await ClashMatchController.loadDefaultMatchKit();
    if (!mounted) {
      return;
    }
    match.restartMatch(
      lineup: lineups.activeLineup,
      catalogById: lineups.catalogById,
      matchInventory: kit,
    );
  }

  void _onBackToMap() {
    context.read<ClashMatchController>().reset();
    context.go(AppRoutes.clashStory);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final story = context.watch<ClashStoryController>();
    final match = context.watch<ClashMatchController>();
    final level = story.activeLevel;
    final state = match.state;

    if (!_initialized || level == null || state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final holder = state.ballHolderPlayer();
    final isFinished = state.isFinished;
    final userWon = isFinished && state.winner == MatchTeamSide.user;
    final objectiveResults = isFinished
        ? ClashMatchObjectiveEvaluator.evaluate(
            objectives: level.matchObjectives,
            state: state,
            userWon: userWon,
            progress: story.progress,
          )
        : const <ClashMatchObjectiveProgress>[];
    final previewRewards = userWon
        ? ClashMatchObjectiveEvaluator.rewardsToGrant(
            levelId: widget.levelId,
            baseVictoryReward: level.rewards,
            objectiveResults: objectiveResults,
            grantBaseVictory:
                !story.progress.isLevelCompleted(widget.levelId) &&
                !story.progress.areRewardsClaimed(widget.levelId),
            progress: story.progress,
          )
        : const ClashStoryReward();
    final isHalftime = state.isPausedForHalftime;
    final hasDuelUi =
        !isHalftime &&
        !isFinished &&
        (state.hasPendingDuel || state.lastDuelResolution != null);
    final isUserPossession =
        state.status == MatchStatus.playing &&
        !isFinished &&
        !isHalftime &&
        state.possession == MatchTeamSide.user &&
        !hasDuelUi;
    final isRivalPossession =
        state.status == MatchStatus.playing &&
        !isFinished &&
        !isHalftime &&
        state.possession == MatchTeamSide.rival &&
        !hasDuelUi;
    final canPass = match.canUserPass;

    return Scaffold(
      appBar: AppBar(title: Text(level.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            l10n.clashMatchScoreLabel(state.score.user, state.score.rival),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(l10n.clashMatchWinTarget, textAlign: TextAlign.center),
          if (!isFinished) ...[
            const SizedBox(height: 12),
            ClashMatchStatusBanner(state: state),
          ],
          if (!isFinished) ...[
            const SizedBox(height: 12),
            ClashMiniPitch(state: state),
          ],
          if (state.status == MatchStatus.awaitingCoinToss) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => match.chooseCoinToss(CoinTossChoice.heads),
                    child: Text(l10n.clashMatchCoinHeads),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => match.chooseCoinToss(CoinTossChoice.tails),
                    child: Text(l10n.clashMatchCoinTails),
                  ),
                ),
              ],
            ),
          ] else if (!isFinished &&
              state.coinToss != null &&
              (state.status == MatchStatus.playing ||
                  state.status == MatchStatus.halftime)) ...[
            const SizedBox(height: 12),
            _InfoCard(
              children: [
                Text(
                  state.possession == MatchTeamSide.user
                      ? l10n.clashMatchPossessionUser
                      : l10n.clashMatchPossessionRival,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (holder != null) ...[
                  const SizedBox(height: 6),
                  Text(l10n.clashMatchBallHolder(holder.label)),
                  Text(
                    '${l10n.clashMatchZoneLabel}: ${state.ballZone.labelEs()}',
                  ),
                  Text(
                    l10n.clashMatchPtStaminaLabel(
                      holder.currentPt,
                      holder.maxPt,
                      holder.currentStamina,
                      holder.maxStamina,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (isHalftime) ...[
            const SizedBox(height: 14),
            const ClashMatchHalftimePanel(),
          ],
          if (isRivalPossession) ...[
            const SizedBox(height: 14),
            const ClashMatchRivalTurnPanel(),
          ],
          if (hasDuelUi) ...[
            const SizedBox(height: 14),
            const ClashMatchDuelPanel(),
          ],
          if (isUserPossession) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canPass
                        ? () => showClashMatchPassSheet(context)
                        : null,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(l10n.clashMatchActionPass),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: match.advance,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: Text(l10n.clashMatchActionAdvance),
                  ),
                ),
              ],
            ),
            if (!canPass) ...[
              const SizedBox(height: 8),
              Text(
                l10n.clashMatchPassUnavailable,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
              ),
            ],
            if (match.advanceChancePercent != null &&
                state.ballZone != MatchBallZone.rivalArea) ...[
              const SizedBox(height: 8),
              Text(
                l10n.clashMatchAdvanceChance(match.advanceChancePercent!),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
              ),
            ],
            const SizedBox(height: 8),
            if (match.canUserShoot)
              FilledButton.icon(
                onPressed: match.shoot,
                icon: const Icon(Icons.sports_soccer),
                label: Text(l10n.clashMatchActionShoot),
              )
            else
              Text(
                l10n.clashMatchStatusShootNeedArea,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.xiTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
          if (state.eventLog.isNotEmpty && !isFinished) ...[
            const SizedBox(height: 16),
            Text(
              l10n.clashMatchEventLogTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...state.eventLog.reversed
                .take(6)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _iconForEvent(event.type),
                          size: 16,
                          color: context.xiTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(event.message)),
                      ],
                    ),
                  ),
                ),
          ],
          if (isFinished) ...[
            const SizedBox(height: 16),
            ClashMatchEndPanel(
              state: state,
              level: level,
              objectiveResults: objectiveResults,
              previewRewards: previewRewards,
              onViewRewards: _onViewRewards,
              onRetry: _onRetry,
              onBackToMap: _onBackToMap,
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForEvent(MatchEventType type) {
    return switch (type) {
      MatchEventType.passSuccess => Icons.check_circle_outline,
      MatchEventType.passFail ||
      MatchEventType.advanceFail => Icons.cancel_outlined,
      MatchEventType.advanceSuccess => Icons.trending_up_rounded,
      MatchEventType.duelStarted => Icons.sports_martial_arts_outlined,
      MatchEventType.duelSuccess => Icons.check_circle_outline,
      MatchEventType.duelFail => Icons.block_outlined,
      MatchEventType.duelTechniqueUsed => Icons.bolt_rounded,
      MatchEventType.shotDuelStarted => Icons.sports_soccer_outlined,
      MatchEventType.saveMade => Icons.back_hand_outlined,
      MatchEventType.goal => Icons.sports_soccer,
      MatchEventType.kickoff => Icons.flag_outlined,
      MatchEventType.rivalAction => Icons.smart_toy_outlined,
      MatchEventType.possessionLost => Icons.swap_horiz_rounded,
      MatchEventType.halftimeStarted => Icons.free_breakfast_outlined,
      MatchEventType.halftimeEnded => Icons.play_arrow_rounded,
      MatchEventType.halftimeItemUsed => Icons.medical_services_outlined,
    };
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

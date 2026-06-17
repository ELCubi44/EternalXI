import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_pass_sheet.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
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
  var _devToolsExpanded = false;

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

    match.startMatch(
      levelId: widget.levelId,
      lineup: lineups.activeLineup,
      catalogById: lineups.catalogById,
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
    final phaseLabel = switch (state.status) {
      MatchStatus.awaitingCoinToss => l10n.clashMatchPhaseCoinToss,
      MatchStatus.playing => l10n.clashMatchPhasePlaying,
      MatchStatus.finished => l10n.clashMatchPhaseFinished,
    };
    final advanceChance = match.advanceChancePercent;
    final hasDuelUi = state.hasPendingDuel || state.lastDuelResolution != null;
    final isUserPossession =
        state.status == MatchStatus.playing &&
        !state.isFinished &&
        state.possession == MatchTeamSide.user &&
        !hasDuelUi;
    final isRivalPossession =
        state.status == MatchStatus.playing &&
        !state.isFinished &&
        state.possession == MatchTeamSide.rival;

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
          const SizedBox(height: 6),
          Text(
            '${l10n.clashMatchPhaseLabel}: $phaseLabel',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ClashMiniPitch(state: state),
          const SizedBox(height: 14),
          if (state.status == MatchStatus.awaitingCoinToss) ...[
            Text(l10n.clashMatchCoinTossPrompt, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
          ] else if (state.coinToss != null &&
              state.status == MatchStatus.playing) ...[
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
                    '${l10n.clashMatchStaminaLabel}: ${holder.currentStamina}',
                  ),
                  Text('${l10n.clashMatchPressureLabel}: ${state.pressure}'),
                  Text('${l10n.clashMatchRiskLabel}: ${state.possessionRisk}'),
                ],
              ],
            ),
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
                    onPressed: () => showClashMatchPassSheet(context),
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
            if (advanceChance != null &&
                state.ballZone != MatchBallZone.rivalArea) ...[
              const SizedBox(height: 8),
              Text(
                l10n.clashMatchAdvanceChance(advanceChance),
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
              OutlinedButton(
                onPressed: null,
                child: Text(l10n.clashMatchActionShootNeedArea),
              ),
          ],
          if (isRivalPossession) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: match.simulateRivalAction,
              icon: const Icon(Icons.smart_toy_outlined),
              label: Text(l10n.clashMatchActionRivalSim),
            ),
          ],
          if (state.eventLog.isNotEmpty) ...[
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
          if (state.isFinished) ...[
            const SizedBox(height: 16),
            Text(
              state.winner == MatchTeamSide.user
                  ? l10n.clashMatchVictory
                  : l10n.clashMatchDefeat,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: state.winner == MatchTeamSide.user
                    ? Colors.green
                    : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            if (state.winner == MatchTeamSide.user)
              FilledButton(
                onPressed: _onViewRewards,
                child: Text(l10n.clashMatchViewRewards),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                match.reset();
                context.go(AppRoutes.clashStory);
              },
              child: Text(l10n.clashStoryBackToMap),
            ),
          ] else if (state.status == MatchStatus.playing) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              initiallyExpanded: _devToolsExpanded,
              onExpansionChanged: (value) =>
                  setState(() => _devToolsExpanded = value),
              title: Text(
                l10n.clashMatchDevSectionTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                Text(
                  l10n.clashMatchDevGoalsHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: match.simulateUserGoal,
                  child: Text(l10n.clashMatchDevGoalUser),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: match.simulateRivalGoal,
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: Text(l10n.clashMatchDevGoalRival),
                ),
              ],
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
      MatchEventType.shotDuelStarted => Icons.sports_soccer_outlined,
      MatchEventType.saveMade => Icons.back_hand_outlined,
      MatchEventType.goal => Icons.sports_soccer,
      MatchEventType.kickoff => Icons.flag_outlined,
      MatchEventType.rivalAction => Icons.smart_toy_outlined,
      MatchEventType.possessionLost => Icons.swap_horiz_rounded,
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

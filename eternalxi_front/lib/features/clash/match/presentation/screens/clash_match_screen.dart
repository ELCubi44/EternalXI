import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
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

    final active = lineups.activeLineup;
    final names = <String>[];
    if (active != null) {
      for (final cardId in active.slots.values) {
        if (cardId == null || cardId.isEmpty) {
          continue;
        }
        final entry = lineups.entryForCardId(cardId);
        names.add(entry?.name ?? cardId);
      }
    }

    match.startMatch(levelId: widget.levelId, userPlayerNames: names);
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

    final holder = state.ballHolder();
    final phaseLabel = switch (state.status) {
      MatchStatus.awaitingCoinToss => l10n.clashMatchPhaseCoinToss,
      MatchStatus.playing => l10n.clashMatchPhasePlaying,
      MatchStatus.finished => l10n.clashMatchPhaseFinished,
    };

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
          Text(
            l10n.clashMatchWinTarget,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.clashMatchPhaseLabel}: $phaseLabel',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ClashMiniPitch(state: state),
          const SizedBox(height: 16),
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
            Text(
              l10n.clashMatchCoinResult(
                state.coinToss!.outcome == CoinTossOutcome.heads
                    ? l10n.clashMatchCoinHeads
                    : l10n.clashMatchCoinTails,
                state.coinToss!.userWonToss
                    ? l10n.clashMatchKickoffUser
                    : l10n.clashMatchKickoffRival,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            state.possession == MatchTeamSide.user
                ? l10n.clashMatchPossessionUser
                : l10n.clashMatchPossessionRival,
          ),
          if (holder != null) Text(l10n.clashMatchBallHolder(holder.label)),
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
            Text(
              l10n.clashMatchDevGoalsHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.orange),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: match.simulateUserGoal,
              child: Text(l10n.clashMatchDevGoalUser),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: match.simulateRivalGoal,
              style: FilledButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text(l10n.clashMatchDevGoalRival),
            ),
          ],
        ],
      ),
    );
  }
}

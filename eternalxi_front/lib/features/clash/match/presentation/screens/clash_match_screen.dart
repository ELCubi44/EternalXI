import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_mission_progress_event_hub.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_evaluator.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_action_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_active_player_card.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_halftime_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_header.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_history_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_turn_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_status_banner.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rival_match_setup_resolver.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
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

    final level = story.activeLevel;
    if (level == null) {
      context.go(AppRoutes.clashStory);
      return;
    }

    final kit = await ClashMatchController.loadDefaultMatchKit();
    if (!mounted) {
      return;
    }

    final rivalSetup = await ClashRivalMatchSetupResolver.resolve(
      repository: context.read<ClashRivalsRepository>(),
      rivalTeamId: level.rivalTeamId,
      fallbackPower: level.recommendedPower,
    );

    match.startMatch(
      levelId: widget.levelId,
      lineup: lineups.activeLineup,
      catalogById: lineups.catalogById,
      matchInventory: kit,
      rivalPower: rivalSetup.rivalPower,
      rivalSquad: rivalSetup.squad,
      rivalTeamName: rivalSetup.rivalTeamName,
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
    final lineups = context.read<ClashLineupsController>();
    final progressHub = context.read<ClashMissionProgressEventHub>();
    final lineupCardIds = lineups.activeLineup?.assignedCardIds ?? const [];
    final result = await story.finishMatchLevel(
      levelId: widget.levelId,
      userWon: userWon,
      matchState: state,
      lineupCardIds: lineupCardIds,
    );

    await progressHub.recordPlayMatch();
    if (userWon) {
      await progressHub.recordWinMatch();
    }

    if (!mounted) {
      return;
    }

    if (userWon) {
      await lineups.load();
      if (!mounted) {
        return;
      }
      final cards = context.read<ClashCardsController>();
      if (cards.state != ClashCardsLoadState.idle) {
        await cards.reloadOwnedCards();
      }
    }

    if (userWon && result != null && result.firstCompletion) {
      if (!mounted) {
        return;
      }
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
    final lineups = context.watch<ClashLineupsController>();
    final collection = context.read<ClashPlayerCollectionRepository>();
    final level = story.activeLevel;
    final state = match.state;

    if (!_initialized || level == null || state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
    final lineupCardIds = lineups.activeLineup?.assignedCardIds ?? const [];
    final previewCardXp = userWon && level.cardXpReward > 0
        ? collection.previewMatchXpSync(
            cardIds: lineupCardIds,
            xpPerCard: level.cardXpReward,
            catalogById: lineups.catalogById,
          )
        : const <ClashCardXpResult>[];
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
    final showActivePlayer =
        !isFinished &&
        !isHalftime &&
        state.coinToss != null &&
        (state.status == MatchStatus.playing ||
            state.status == MatchStatus.halftime);

    return Scaffold(
      appBar: AppBar(title: Text(level.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClashMatchHeader(
            matchTitle: level.title,
            state: state,
            rivalName: match.rivalTeamName,
          ),
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
          ],
          if (showActivePlayer) ...[
            const SizedBox(height: 12),
            ClashMatchActivePlayerCard(state: state),
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
            const ClashMatchActionPanel(),
          ],
          if (!isFinished && state.eventLog.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClashMatchHistoryPanel(state: state),
          ],
          if (isFinished) ...[
            const SizedBox(height: 16),
            ClashMatchEndPanel(
              state: state,
              level: level,
              objectiveResults: objectiveResults,
              previewRewards: previewRewards,
              previewCardXp: previewCardXp,
              onViewRewards: _onViewRewards,
              onRetry: _onRetry,
              onBackToMap: _onBackToMap,
            ),
          ],
        ],
      ),
    );
  }
}

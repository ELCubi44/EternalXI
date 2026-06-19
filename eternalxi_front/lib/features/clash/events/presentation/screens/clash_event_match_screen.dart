import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_action_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_active_player_card.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_halftime_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_header.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_history_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_turn_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_status_banner.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_match_end_panel.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rival_match_setup_resolver.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_reward_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventMatchScreen extends StatefulWidget {
  const ClashEventMatchScreen({
    required this.eventId,
    required this.stageId,
    super.key,
  });

  final String eventId;
  final String stageId;

  @override
  State<ClashEventMatchScreen> createState() => _ClashEventMatchScreenState();
}

class _ClashEventMatchScreenState extends State<ClashEventMatchScreen> {
  var _initialized = false;
  ClashCharacterEventStage? _stage;
  int _clearCountBefore = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final lineups = context.read<ClashLineupsController>();
    final match = context.read<ClashMatchController>();
    final eventsRepo = context.read<ClashCharacterEventsRepository>();

    if (lineups.state == ClashLineupsLoadState.idle) {
      await lineups.load();
    }

    final stage = await eventsRepo.findStage(widget.eventId, widget.stageId);
    if (!mounted) {
      return;
    }
    if (stage == null || !(lineups.activeLineup?.isComplete ?? false)) {
      context.pop();
      return;
    }

    final state = await eventsRepo.loadState();
    _clearCountBefore = state.clearCounts[widget.stageId] ?? 0;
    _stage = stage;

    final kit = await ClashMatchController.loadDefaultMatchKit();
    if (!mounted) {
      return;
    }

    final rivalSetup = await ClashRivalMatchSetupResolver.resolve(
      repository: context.read<ClashRivalsRepository>(),
      rivalTeamId: stage.rivalTeamId,
      fallbackPower: stage.recommendedPower,
    );

    match.startMatch(
      levelId: widget.stageId,
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
    final eventsRepo = context.read<ClashCharacterEventsRepository>();
    final match = context.read<ClashMatchController>();
    final state = match.state;
    if (state == null || !state.isFinished) {
      return;
    }

    final userWon = state.winner == MatchTeamSide.user;
    final lineups = context.read<ClashLineupsController>();
    final lineupCardIds = lineups.activeLineup?.assignedCardIds ?? const [];

    final result = await eventsRepo.completeMatchStage(
      eventId: widget.eventId,
      stageId: widget.stageId,
      userWon: userWon,
      lineupCardIds: lineupCardIds,
    );

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

    if (userWon && result != null && !result.rewardsGranted.isEmpty) {
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Provider<ClashCharacterEventsRepository>.value(
            value: eventsRepo,
            child: ClashEventRewardScreen(
              eventId: widget.eventId,
              stageId: widget.stageId,
            ),
          ),
        ),
      );
    }

    match.reset();
    if (mounted) {
      context.pop();
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
      rivalPower: _stage?.recommendedPower,
    );
  }

  void _onBack() {
    context.read<ClashMatchController>().reset();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final match = context.watch<ClashMatchController>();
    final lineups = context.watch<ClashLineupsController>();
    final collection = context.read<ClashPlayerCollectionRepository>();
    final stage = _stage;
    final state = match.state;

    if (!_initialized || stage == null || state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFinished = state.isFinished;
    final userWon = isFinished && state.winner == MatchTeamSide.user;
    final previewReward = userWon
        ? (_clearCountBefore == 0
              ? stage.firstClearRewards
              : stage.repeatRewards)
        : const ClashCharacterEventReward();
    final lineupCardIds = lineups.activeLineup?.assignedCardIds ?? const [];
    final previewCardXp = userWon && stage.cardXpReward > 0
        ? collection.previewMatchXpSync(
            cardIds: lineupCardIds,
            xpPerCard: stage.cardXpReward,
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
      appBar: AppBar(title: Text(stage.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClashMatchHeader(
            matchTitle: stage.title,
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
            ClashEventMatchEndPanel(
              state: state,
              stageTitle: stage.title,
              previewReward: previewReward,
              previewCardXp: previewCardXp,
              onViewRewards: _onViewRewards,
              onRetry: _onRetry,
              onBack: _onBack,
            ),
          ],
        ],
      ),
    );
  }
}

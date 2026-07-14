import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/controllers/clash_chain_trial_controller.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/screens/clash_trial_reward_screen.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moment.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moments_phase.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_mission_progress_event_hub.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rival_match_setup_resolver.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashChainMatchScreen extends StatefulWidget {
  const ClashChainMatchScreen({
    required this.trialId,
    required this.floorId,
    super.key,
  });

  final String trialId;
  final String floorId;

  @override
  State<ClashChainMatchScreen> createState() => _ClashChainMatchScreenState();
}

class _ClashChainMatchScreenState extends State<ClashChainMatchScreen> {
  var _initialized = false;
  ClashTrial? _trial;
  ClashTrialFloor? _floor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final lineups = context.read<ClashLineupsController>();
    final chain = context.read<ClashChainTrialController>();
    final repo = context.read<ClashTrialsRepository>();

    if (lineups.state == ClashLineupsLoadState.idle) {
      await lineups.load();
    }

    final trial = await repo.findTrialById(widget.trialId);
    final floor = await repo.findFloor(widget.trialId, widget.floorId);
    if (!mounted || trial == null || floor == null) {
      context.pop();
      return;
    }

    final progress = await repo.fetchFloorProgress(widget.trialId);
    var clearCount = 0;
    for (final item in progress) {
      if (item.floor.id == widget.floorId) {
        clearCount = item.clearCount;
        break;
      }
    }

    final rivalSetup = await ClashRivalMatchSetupResolver.resolve(
      repository: context.read<ClashRivalsRepository>(),
      rivalTeamId: floor.rivalTeamId,
      fallbackPower: floor.scaledRecommendedPower(clearCount),
    );

    if (!mounted) {
      return;
    }

    chain.startFloor(
      trialId: widget.trialId,
      floor: floor,
      trialLine: trial.line,
      lineup: lineups.activeLineup,
      catalogById: lineups.catalogById,
      rivalSquad: rivalSetup.squad,
      rivalTeamName: rivalSetup.rivalTeamName,
      rivalPower: rivalSetup.rivalPower,
    );

    setState(() {
      _trial = trial;
      _floor = floor;
      _initialized = true;
    });
  }

  Future<void> _onFinish() async {
    final chain = context.read<ClashChainTrialController>();
    final repo = context.read<ClashTrialsRepository>();
    final hub = context.read<ClashMissionProgressEventHub>();
    final lineups = context.read<ClashLineupsController>();

    await hub.recordPlayMatch();
    if (chain.userWon) {
      await hub.recordWinMatch();
      await hub.recordPlayChainTrial();
    }

    final lineupCardIds = lineups.activeLineup?.assignedCardIds ?? const [];
    final result = await repo.completeFloor(
      trialId: widget.trialId,
      floorId: widget.floorId,
      userWon: chain.userWon,
      techniqueUses: chain.techniqueUses,
      lineupCardIds: lineupCardIds,
    );

    if (!mounted) {
      return;
    }

    if (chain.userWon && result != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ClashTrialRewardScreen(
            trialId: widget.trialId,
            floorId: widget.floorId,
          ),
        ),
      );
    }

    chain.reset();
    if (mounted) {
      context.go(AppRoutes.clashTrialDetail(widget.trialId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _floor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chain = context.watch<ClashChainTrialController>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(_floor!.title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScoreBar(
              userScore: chain.score.user,
              rivalScore: chain.score.rival,
              rivalName: chain.rivalTeamName ?? 'Rival',
              progress: chain.progress,
              techniqueUses: chain.techniqueUses,
              techniqueTarget: chain.techniqueBonusTarget,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildPhase(context, chain, l10n)),
            if (chain.chronicle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  chain.chronicle.last,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase(
    BuildContext context,
    ClashChainTrialController chain,
    dynamic l10n,
  ) {
    final moment = chain.currentMoment;
    return switch (chain.phase) {
      ClashDecisiveMomentsPhase.intro when moment != null => _IntroCard(
        moment: moment,
        onContinue: chain.continueFromIntro,
      ),
      ClashDecisiveMomentsPhase.pickCard => _DrawPanel(
        candidates: chain.drawCandidates,
        catalogById: chain.catalogById,
        lineName: _trial!.line.displayNameEs,
        hasStyleAdvantage: chain.hasStyleAdvantageAgainstRival,
        onPick: chain.selectDrawnPlayer,
      ),
      ClashDecisiveMomentsPhase.duel when moment != null &&
          chain.selectedPlayer != null &&
          chain.rivalPlayer != null =>
        _DuelPanel(
          moment: moment,
          userPlayer: chain.selectedPlayer!,
          rivalPlayer: chain.rivalPlayer!,
          userCatalog: chain.catalogFor(chain.selectedPlayer!),
          onResolveNormal: () => chain.resolveDuel(),
          onResolveTechnique: (id) => chain.resolveDuel(techniqueId: id),
        ),
      ClashDecisiveMomentsPhase.result when chain.lastResolution != null =>
        _ResultCard(
          resolution: chain.lastResolution!,
          onContinue: chain.continueFromResult,
        ),
      ClashDecisiveMomentsPhase.finished => _EndCard(
        userWon: chain.userWon,
        userScore: chain.score.user,
        rivalScore: chain.score.rival,
        techniqueBonus: chain.techniqueBonusAchieved,
        onExit: _onFinish,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.userScore,
    required this.rivalScore,
    required this.rivalName,
    required this.progress,
    required this.techniqueUses,
    required this.techniqueTarget,
  });

  final int userScore;
  final int rivalScore;
  final String rivalName;
  final double progress;
  final int techniqueUses;
  final int techniqueTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Eternal XI $userScore'),
              const Spacer(),
              Text('$rivalScore $rivalName'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 5),
          if (techniqueTarget > 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.clashTrialsTechniqueProgress(techniqueUses, techniqueTarget),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.moment, required this.onContinue});

  final ClashDecisiveMoment moment;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${moment.minute}' � ${moment.title}",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(moment.context, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onContinue, child: const Text('Robar cartas')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawPanel extends StatelessWidget {
  const _DrawPanel({
    required this.candidates,
    required this.catalogById,
    required this.lineName,
    required this.hasStyleAdvantage,
    required this.onPick,
  });

  final List<MatchSquadPlayer> candidates;
  final Map<String, ClashCardCatalogEntry> catalogById;
  final String lineName;
  final bool Function(MatchSquadPlayer player) hasStyleAdvantage;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.clashTrialsDrawTitle(lineName),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: candidates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = candidates[index];
              final entry = catalogById[player.cardId];
              final styleBonus = hasStyleAdvantage(player);
              return OutlinedButton(
                onPressed: () => onPick(index),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 64,
                      child: ClashCardPortrait(
                        name: entry?.name ?? player.cardId,
                        imagePath: entry?.card.basicPortraitPath ?? 'placeholder',
                        playerId: entry?.card.playerId,
                        height: 64,
                        rarity: entry?.effectiveRarity,
                        position: player.position,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry?.name ?? player.cardId),
                          Text(player.position.displayNameEs),
                          if (styleBonus)
                            Text(
                              l10n.clashTrialsStyleAdvantage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DuelPanel extends StatelessWidget {
  const _DuelPanel({
    required this.moment,
    required this.userPlayer,
    required this.rivalPlayer,
    required this.userCatalog,
    required this.onResolveNormal,
    required this.onResolveTechnique,
  });

  final ClashDecisiveMoment moment;
  final MatchSquadPlayer userPlayer;
  final MatchSquadPlayer rivalPlayer;
  final ClashCardCatalogEntry? userCatalog;
  final VoidCallback onResolveNormal;
  final ValueChanged<String> onResolveTechnique;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final techniques = moment.isUserAttacking
        ? ClashDuelTechniqueRules.compatibleForAttacker(
            userPlayer,
            moment.duelType,
          )
        : ClashDuelTechniqueRules.compatibleForDefender(
            userPlayer,
            moment.duelType,
          );
    final normalLabel = moment.duelType == ClashDuelType.shotVsSave
        ? l10n.clashMatchDuelNormalShot
        : l10n.clashMatchDuelNormalDribble;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(userCatalog?.name ?? userPlayer.cardId,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton(onPressed: onResolveNormal, child: Text(normalLabel)),
          const SizedBox(height: 8),
          ...techniques.map((ClashSuperTechnique technique) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton(
                onPressed: userPlayer.currentPt >= technique.ptCost
                    ? () => onResolveTechnique(technique.id)
                    : null,
                child: Text('${technique.name} (${technique.ptCost} PT)'),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.resolution, required this.onContinue});

  final ClashDuelResolution resolution;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resolution.isGoal ? 'GOL' : 'Duelo resuelto',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(resolution.eventText, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onContinue, child: const Text('Continuar')),
        ],
      ),
    );
  }
}

class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.userWon,
    required this.userScore,
    required this.rivalScore,
    required this.techniqueBonus,
    required this.onExit,
  });

  final bool userWon;
  final int userScore;
  final int rivalScore;
  final bool techniqueBonus;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            userWon ? l10n.clashMatchVictory : l10n.clashMatchDefeat,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: userWon ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
          Text('$userScore - $rivalScore'),
          if (techniqueBonus)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.clashTrialsRewardTechniqueBonus),
            ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onExit, child: Text(l10n.close)),
        ],
      ),
    );
  }
}

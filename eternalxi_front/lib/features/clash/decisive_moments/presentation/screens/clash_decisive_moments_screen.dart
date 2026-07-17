import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moment.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moments_phase.dart';
import 'package:eternal_xi/features/clash/decisive_moments/presentation/controllers/clash_decisive_moments_controller.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rival_match_setup_resolver.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_reward_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Partido resumido en momentos clave � sin minicampo.
class ClashDecisiveMomentsScreen extends StatefulWidget {
  const ClashDecisiveMomentsScreen({required this.levelId, super.key});

  final String levelId;

  @override
  State<ClashDecisiveMomentsScreen> createState() =>
      _ClashDecisiveMomentsScreenState();
}

class _ClashDecisiveMomentsScreenState extends State<ClashDecisiveMomentsScreen>
    with SingleTickerProviderStateMixin {
  var _initialized = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final story = context.read<ClashStoryController>();
    final lineups = context.read<ClashLineupsController>();
    final decisive = context.read<ClashDecisiveMomentsController>();

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

    final rivalSetup = await ClashRivalMatchSetupResolver.resolve(
      repository: context.read<ClashRivalsRepository>(),
      rivalTeamId: level.rivalTeamId,
      fallbackPower: level.recommendedPower,
    );

    if (!mounted) {
      return;
    }

    decisive.startMatch(
      levelId: widget.levelId,
      lineup: lineups.activeLineup,
      catalogById: lineups.catalogById,
      rivalSquad: rivalSetup.squad,
      rivalTeamName: rivalSetup.rivalTeamName,
      rivalPower: rivalSetup.rivalPower,
    );

    setState(() => _initialized = true);
  }

  Future<void> _onFinish() async {
    final story = context.read<ClashStoryController>();
    final decisive = context.read<ClashDecisiveMomentsController>();
    final lineups = context.read<ClashLineupsController>();

    final userWon = decisive.userWon;
    final lineupCardIds = lineups.activeLineup?.assignedCardIds ?? const [];
    final result = await story.finishMatchLevel(
      levelId: widget.levelId,
      userWon: userWon,
      matchState: decisive.buildFinalMatchState(),
      lineupCardIds: lineupCardIds,
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

    decisive.reset();
    if (mounted) {
      context.go(AppRoutes.clashStory);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final decisive = context.watch<ClashDecisiveMomentsController>();
    final story = context.watch<ClashStoryController>();
    final levelTitle = story.activeLevel?.title ?? 'Momentos decisivos';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(levelTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              XiColors.royalBlue.withValues(alpha: 0.22),
              context.xiBackground,
              Colors.black.withValues(alpha: 0.35),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScoreAndProgressBar(
                  userScore: decisive.score.user,
                  rivalScore: decisive.score.rival,
                  rivalName: decisive.rivalTeamName ?? 'Rival',
                  momentIndex: decisive.momentIndex,
                  totalMoments: decisive.moments.length,
                  progress: decisive.progress,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _buildPhase(context, decisive),
                  ),
                ),
                if (decisive.chronicle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ChronicleStrip(lines: decisive.chronicle),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(
    BuildContext context,
    ClashDecisiveMomentsController decisive,
  ) {
    final moment = decisive.currentMoment;

    return switch (decisive.phase) {
      ClashDecisiveMomentsPhase.intro when moment != null => _MomentIntroCard(
        key: ValueKey('intro-${decisive.momentIndex}'),
        moment: moment,
        pulse: _pulseController,
        onContinue: decisive.continueFromIntro,
      ),
      ClashDecisiveMomentsPhase.pickCard when moment != null =>
        _CardPickerPanel(
          key: ValueKey('pick-${decisive.momentIndex}'),
          moment: moment,
          squad: decisive.pickableSquadForCurrentMoment(),
          catalogById: decisive.catalogById,
          isPreferred: decisive.isPreferredPick,
          onPick: decisive.selectPlayer,
        ),
      ClashDecisiveMomentsPhase.duel when moment != null =>
        _DuelStage(
          key: ValueKey('duel-${decisive.momentIndex}'),
          moment: moment,
          userPlayer: decisive.selectedPlayer!,
          rivalPlayer: decisive.rivalPlayer!,
          userCatalog: decisive.catalogFor(decisive.selectedPlayer!),
          rivalCatalog: decisive.catalogFor(decisive.rivalPlayer!),
          onResolveNormal: () => decisive.resolveDuel(),
          onResolveTechnique: (id) => decisive.resolveDuel(techniqueId: id),
        ),
      ClashDecisiveMomentsPhase.result when decisive.lastResolution != null =>
        _ResultCard(
          key: ValueKey('result-${decisive.momentIndex}'),
          resolution: decisive.lastResolution!,
          onContinue: decisive.continueFromResult,
        ),
      ClashDecisiveMomentsPhase.finished => _EndCard(
        key: const ValueKey('finished'),
        userScore: decisive.score.user,
        rivalScore: decisive.score.rival,
        userWon: decisive.userWon,
        onExit: _onFinish,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _ScoreAndProgressBar extends StatelessWidget {
  const _ScoreAndProgressBar({
    required this.userScore,
    required this.rivalScore,
    required this.rivalName,
    required this.momentIndex,
    required this.totalMoments,
    required this.progress,
  });

  final int userScore;
  final int rivalScore;
  final String rivalName;
  final int momentIndex;
  final int totalMoments;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Eternal XI',
                  style: theme.textTheme.labelLarge?.copyWith(
                    ),
                ),
              ),
              Text(
                '$userScore  �  $rivalScore',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: Text(
                  rivalName,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: context.xiDivider,
              color: XiColors.classicGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Momento ${momentIndex + 1} / $totalMoments',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentIntroCard extends StatelessWidget {
  const _MomentIntroCard({
    required this.moment,
    required this.pulse,
    required this.onContinue,
    super.key,
  });

  final ClashDecisiveMoment moment;
  final AnimationController pulse;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = moment.canScore ? XiColors.classicGold : XiColors.royalBlue;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.35),
                context.xiCardSurface,
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.75, end: 1).animate(pulse),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    "${moment.minute}'",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                moment.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  ),
              ),
              const SizedBox(height: 10),
              Text(
                moment.context,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.xiTextSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                moment.isUserAttacking ? 'T� atacas' : 'Defiendes',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: moment.isUserAttacking
                      ? theme.colorScheme.primary
                      : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onContinue,
                child: const Text('Ver jugada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPickerPanel extends StatelessWidget {
  const _CardPickerPanel({
    required this.moment,
    required this.squad,
    required this.catalogById,
    required this.isPreferred,
    required this.onPick,
    super.key,
  });

  final ClashDecisiveMoment moment;
  final List<MatchSquadPlayer> squad;
  final Map<String, ClashCardCatalogEntry> catalogById;
  final bool Function(MatchSquadPlayer) isPreferred;
  final void Function(int index) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          moment.isUserAttacking
              ? 'Elige qui�n resuelve la jugada'
              : 'Elige qui�n defiende',
          style: theme.textTheme.titleMedium?.copyWith(
            ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: squad.length,
            itemBuilder: (context, index) {
              final player = squad[index];
              final catalog = catalogById[player.cardId];
              final preferred = isPreferred(player);
              final name = catalog?.name ?? player.label;
              final imagePath =
                  catalog?.card.basicPortraitPath ?? 'placeholder';
              final playerId = catalog?.card.playerId;
              final rarity = catalog?.effectiveRarity;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onPick(player.index),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: preferred
                            ? XiColors.classicGold
                            : context.xiDivider,
                        width: preferred ? 2 : 1,
                      ),
                      color: context.xiCardSurface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          if (preferred)
                            Text(
                              '?',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: XiColors.classicGold,
                              ),
                            ),
                          Expanded(
                            child: ClashCardPortrait(
                              name: name,
                              imagePath: imagePath,
                              playerId: playerId,
                              height: double.infinity,
                              rarity: rarity,
                              position: player.position,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DuelStage extends StatelessWidget {
  const _DuelStage({
    required this.moment,
    required this.userPlayer,
    required this.rivalPlayer,
    required this.userCatalog,
    required this.rivalCatalog,
    required this.onResolveNormal,
    required this.onResolveTechnique,
    super.key,
  });

  final ClashDecisiveMoment moment;
  final MatchSquadPlayer userPlayer;
  final MatchSquadPlayer rivalPlayer;
  final ClashCardCatalogEntry? userCatalog;
  final ClashCardCatalogEntry? rivalCatalog;
  final VoidCallback onResolveNormal;
  final void Function(String techniqueId) onResolveTechnique;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duelType = moment.duelType;
    final isUserAttacker = moment.isUserAttacking;

    final attacker = isUserAttacker ? userPlayer : rivalPlayer;
    final defender = isUserAttacker ? rivalPlayer : userPlayer;
    final attackerCatalog = isUserAttacker ? userCatalog : rivalCatalog;
    final defenderCatalog = isUserAttacker ? rivalCatalog : userCatalog;

    final userTechniques = isUserAttacker
        ? ClashDuelTechniqueRules.compatibleForAttacker(userPlayer, duelType)
        : ClashDuelTechniqueRules.compatibleForDefender(userPlayer, duelType);

    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            duelType == ClashDuelType.shotVsSave
                ? 'Duelo: Tiro vs Parada'
                : 'Duelo: Regate vs Defensa',
            style: theme.textTheme.titleMedium?.copyWith(
              ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _DuelCardFace(
                  label: attackerCatalog?.name ?? attacker.label,
                  imagePath:
                      attackerCatalog?.card.basicPortraitPath ?? 'placeholder',
                  playerId: attackerCatalog?.card.playerId,
                  statLabel: duelType == ClashDuelType.shotVsSave
                      ? 'Tiro ${attacker.effectiveShot}'
                      : 'Regate ${attacker.effectiveDribble}',
                  rarity: attackerCatalog?.effectiveRarity,
                  position: attacker.position,
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: XiColors.classicGold,
                  ),
                ),
              ),
              Expanded(
                child: _DuelCardFace(
                  label: defenderCatalog?.name ?? defender.label,
                  imagePath:
                      defenderCatalog?.card.basicPortraitPath ?? 'placeholder',
                  playerId: defenderCatalog?.card.playerId,
                  statLabel: duelType == ClashDuelType.shotVsSave
                      ? 'Parada ${defender.effectiveSave}'
                      : 'Defensa ${defender.effectiveDefense}',
                  rarity: defenderCatalog?.effectiveRarity,
                  position: defender.position,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onResolveNormal,
              child: Text(
                duelType == ClashDuelType.shotVsSave
                    ? (isUserAttacker ? 'Disparar' : 'Parar')
                    : (isUserAttacker ? 'Regatear' : 'Entrar'),
              ),
            ),
          ),
          for (final technique in userTechniques) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: userPlayer.currentPt >= technique.ptCost
                  ? () => onResolveTechnique(technique.id)
                  : null,
              child: Text(
                '${technique.name} (${technique.ptCost} PT)',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DuelCardFace extends StatelessWidget {
  const _DuelCardFace({
    required this.label,
    required this.imagePath,
    required this.statLabel,
    required this.alignEnd,
    this.playerId,
    this.rarity,
    this.position,
  });

  final String label;
  final String imagePath;
  final int? playerId;
  final String statLabel;
  final bool alignEnd;
  final ClashRarity? rarity;
  final ClashPosition? position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = rarity != null
        ? ClashRarityBadge.color(rarity!)
        : XiColors.royalBlue;

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ClashCardPortrait(
                name: label,
                imagePath: imagePath,
                playerId: playerId,
                height: double.infinity,
                rarity: rarity,
                position: position,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            ),
        ),
        Text(
          statLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.resolution,
    required this.onContinue,
    super.key,
  });

  final ClashDuelResolution resolution;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGoal = resolution.isGoal;
    final userSide = resolution.attackerSide == MatchTeamSide.user ||
        resolution.winner == MatchTeamSide.user;
    final accent = isGoal
        ? XiColors.classicGold
        : (userSide ? Colors.greenAccent : Colors.orangeAccent);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.xiCardSurface,
          border: Border.all(color: accent.withValues(alpha: 0.6), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGoal
                  ? '�GOOOOL!'
                  : resolution.isSave
                  ? 'PARADA'
                  : resolution.attackerWon
                  ? 'GANA EL ATAQUE'
                  : 'GANA LA DEFENSA',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              resolution.eventText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '${resolution.attackerScore} � ${resolution.defenderScore}',
              style: theme.textTheme.titleLarge?.copyWith(
                ),
            ),
            if (resolution.resolvedByCoin) ...[
              const SizedBox(height: 6),
              Text(
                'Desempate al l�mite',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Siguiente momento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.userScore,
    required this.rivalScore,
    required this.userWon,
    required this.onExit,
    super.key,
  });

  final int userScore;
  final int rivalScore;
  final bool userWon;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: userWon
                ? [
                    XiColors.classicGold.withValues(alpha: 0.25),
                    context.xiCardSurface,
                  ]
                : [
                    Colors.red.withValues(alpha: 0.15),
                    context.xiCardSurface,
                  ],
          ),
          border: Border.all(
            color: userWon ? XiColors.classicGold : context.xiDivider,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userWon ? 'Victoria' : 'Derrota',
              style: theme.textTheme.headlineMedium?.copyWith(
                ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resultado final: $userScore � $rivalScore',
              style: theme.textTheme.titleLarge?.copyWith(
                ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onExit, child: const Text('Continuar')),
          ],
        ),
      ),
    );
  }
}

class _ChronicleStrip extends StatelessWidget {
  const _ChronicleStrip({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final last = lines.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.xiCardSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_rounded, size: 18, color: XiColors.classicGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                ),
            ),
          ),
        ],
      ),
    );
  }
}

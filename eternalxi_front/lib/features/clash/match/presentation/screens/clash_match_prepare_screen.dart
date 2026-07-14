import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_prepare_validation.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objectives_card.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_prepare_section.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_detail_header.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashMatchPrepareScreen extends StatefulWidget {
  const ClashMatchPrepareScreen({required this.levelId, super.key});

  final String levelId;

  @override
  State<ClashMatchPrepareScreen> createState() =>
      _ClashMatchPrepareScreenState();
}

class _ClashMatchPrepareScreenState extends State<ClashMatchPrepareScreen> {
  var _loading = true;
  var _blocked = false;
  ClashRivalTeam? _rivalTeam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final story = context.read<ClashStoryController>();
    final lineups = context.read<ClashLineupsController>();

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

    ClashRivalTeam? rivalTeam;
    final level = story.activeLevel;
    if (level?.rivalTeamId != null) {
      rivalTeam = await context.read<ClashRivalsRepository>().findTeam(
        level!.rivalTeamId!,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _blocked = !ok;
      _rivalTeam = rivalTeam;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final story = context.watch<ClashStoryController>();
    final lineups = context.watch<ClashLineupsController>();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final level = story.activeLevel;
    if (_blocked || level == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashStoryLevelBlockedTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.clashStoryCompletePreviousLevel,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.clashStory),
                  child: Text(l10n.clashStoryBackToMap),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeLineup = lineups.activeLineup;
    final lineupPower = activeLineup == null
        ? 0
        : lineups.totalPower(activeLineup);
    final validation = ClashMatchPrepareValidation.evaluate(
      level: level,
      progress: story.progress,
      activeLineup: activeLineup,
      lineupPower: lineupPower,
      rivalRecommendedPower: _rivalTeam?.recommendedPower,
    );
    final chapterTitle = story.activeChapter?.title ?? level.chapterId;
    final status = story.statusFor(level);
    final rewardsClaimed = story.progress.areRewardsClaimed(level.id);
    final lineupReady = validation.hasCompleteActiveLineup;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashHomeStory)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ClashStoryLevelDetailHeader(
            title: level.title,
            chapterTitle: chapterTitle,
            type: level.type,
            status: status,
            rewards: level.rewards,
            rewardsClaimed: rewardsClaimed,
          ),
          const SizedBox(height: 12),
          Text(
            level.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(
            label: l10n.clashMatchPrepareEnergy,
            value: '${level.energyCost}',
          ),
          if (validation.recommendedPower != null)
            _InfoTile(
              label: l10n.clashMatchPrepareRecommendedPower,
              value: '${validation.recommendedPower}',
            ),
          ClashMatchRivalPrepareSection(
            ownPower: validation.lineupPower,
            rivalTeam: _rivalTeam,
            fallbackRecommendedPower: _rivalTeam == null
                ? validation.recommendedPower
                : null,
          ),
          const SizedBox(height: 12),
          _StatusChip(
            ok: lineupReady,
            label: lineupReady
                ? l10n.clashMatchPrepareLineupComplete
                : l10n.clashMatchPrepareLineupIncomplete,
          ),
          if (validation.powerBelowRecommended &&
              validation.recommendedPower != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.clashMatchPreparePowerWarning)),
                ],
              ),
            ),
          ],
          if (level.matchObjectives.isNotEmpty) ...[
            const SizedBox(height: 20),
            ClashMatchObjectivesCard(objectives: level.matchObjectives),
          ],
          const SizedBox(height: 24),
          if (!lineupReady) ...[
            FilledButton(
              onPressed: () => context.push(AppRoutes.clashTeam7v7),
              child: Text(l10n.clashStoryPrepareTeam),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: null,
              child: Text(l10n.clashStoryStartMatch),
            ),
          ] else ...[
            FilledButton(
              onPressed: validation.canStart
                  ? () => context.push(
                      AppRoutes.clashDecisiveMoments(widget.levelId),
                    )
                  : null,
              child: const Text('Momentos decisivos'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: validation.canStart
                  ? () => context.push(AppRoutes.clashMatch(widget.levelId))
                  : null,
              child: Text(l10n.clashStoryStartMatch),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.clashTeam7v7),
              child: Text(l10n.clashMatchPrepareEditLineup),
            ),
          ],
          if (status == ClashStoryLevelStatus.completed) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.clashStory),
              child: Text(l10n.clashStoryBackToMap),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok
              ? Colors.green.withValues(alpha: 0.35)
              : Colors.red.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: ok ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

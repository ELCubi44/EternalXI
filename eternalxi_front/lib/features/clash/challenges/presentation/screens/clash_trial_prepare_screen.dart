import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_prepare_section.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashTrialPrepareScreen extends StatefulWidget {
  const ClashTrialPrepareScreen({
    required this.trialId,
    required this.floorId,
    super.key,
  });

  final String trialId;
  final String floorId;

  @override
  State<ClashTrialPrepareScreen> createState() => _ClashTrialPrepareScreenState();
}

class _ClashTrialPrepareScreenState extends State<ClashTrialPrepareScreen> {
  ClashTrial? _trial;
  ClashTrialFloor? _floor;
  ClashTrialFloorProgress? _progress;
  ClashRivalTeam? _rivalTeam;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lineups = context.read<ClashLineupsController>();
    final repo = context.read<ClashTrialsRepository>();
    if (lineups.state == ClashLineupsLoadState.idle) {
      await lineups.load();
    }
    final trial = await repo.findTrialById(widget.trialId);
    final floor = await repo.findFloor(widget.trialId, widget.floorId);
    final floors = await repo.fetchFloorProgress(widget.trialId);
    ClashTrialFloorProgress? progress;
    for (final item in floors) {
      if (item.floor.id == widget.floorId) {
        progress = item;
        break;
      }
    }
    ClashRivalTeam? rivalTeam;
    if (floor?.rivalTeamId != null) {
      rivalTeam = await context.read<ClashRivalsRepository>().findTeam(
        floor!.rivalTeamId!,
      );
    }
    if (mounted) {
      setState(() {
        _trial = trial;
        _floor = floor;
        _progress = progress;
        _rivalTeam = rivalTeam;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final repo = context.read<ClashTrialsRepository>();
    final consumed = await repo.consumeDailyAttempt();
    if (!mounted) {
      return;
    }
    if (!consumed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.clashTrialsNoAttempts),
        ),
      );
      return;
    }
    context.push(AppRoutes.clashTrialFloorMatch(widget.trialId, widget.floorId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lineups = context.watch<ClashLineupsController>();
    final floor = _floor;
    final trial = _trial;
    final progress = _progress;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (floor == null || trial == null || progress == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashHomeChallenges)),
        body: Center(child: Text(l10n.clashTrialsFloorNotFound)),
      );
    }

    final activeLineup = lineups.activeLineup;
    final lineupPower = activeLineup == null
        ? 0
        : lineups.totalPower(activeLineup);
    final hasCompleteLineup = activeLineup?.isComplete ?? false;
    final recommended = progress.scaledPower;
    final powerBelow = lineupPower < recommended;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashTrialsPrepareTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(trial.title, style: Theme.of(context).textTheme.titleLarge),
          Text(floor.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(floor.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          _InfoChip(
            label: l10n.clashTrialsScaledPower(recommended),
            highlight: powerBelow,
          ),
          _InfoChip(label: l10n.clashTrialsTechniqueGoal(floor.techniqueBonusTarget)),
          if (progress.clearCount > 0)
            _InfoChip(label: '�${progress.clearCount} ${l10n.clashTrialsRepeatRun}'),
          const SizedBox(height: 16),
          ClashMatchRivalPrepareSection(
            ownPower: lineupPower,
            rivalTeam: _rivalTeam,
            fallbackRecommendedPower: recommended,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.clashTrialsDrawRules(trial.line.displayNameEs),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: hasCompleteLineup && progress.canPlay ? _start : null,
            child: Text(l10n.clashTrialsStartFloor),
          ),
          if (!hasCompleteLineup) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clashMatchPrepareLineupIncomplete,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.orange.withValues(alpha: 0.12)
              : context.xiCardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.xiDivider),
        ),
        child: Text(label),
      ),
    );
  }
}

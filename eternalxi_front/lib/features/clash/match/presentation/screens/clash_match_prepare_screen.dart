import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_objectives_card.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_prepare_validation.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
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

    setState(() {
      _loading = false;
      _blocked = !ok;
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
            child: Text(
              l10n.clashStoryLevelBlockedBody,
              textAlign: TextAlign.center,
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
    );

    return Scaffold(
      appBar: AppBar(title: Text(level.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            level.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _InfoTile(
            label: l10n.clashMatchPrepareType,
            value: clashStoryLevelTypeLabel(level.type, l10n),
          ),
          _InfoTile(
            label: l10n.clashMatchPrepareEnergy,
            value: '${level.energyCost}',
          ),
          if (validation.recommendedPower != null)
            _InfoTile(
              label: l10n.clashMatchPrepareRecommendedPower,
              value: '${validation.recommendedPower}',
            ),
          _InfoTile(
            label: l10n.clashMatchPrepareLineupPower,
            value: '${validation.lineupPower}',
          ),
          const SizedBox(height: 12),
          _StatusChip(
            ok: validation.hasCompleteActiveLineup,
            label: validation.hasCompleteActiveLineup
                ? l10n.clashMatchPrepareLineupComplete
                : l10n.clashMatchPrepareLineupIncomplete,
          ),
          if (validation.powerBelowRecommended) ...[
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
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.clashTeam7v7),
            child: Text(l10n.clashMatchPrepareEditLineup),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: validation.canStart
                ? () => context.push(AppRoutes.clashMatch(widget.levelId))
                : null,
            child: Text(l10n.clashMatchPrepareStart),
          ),
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
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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

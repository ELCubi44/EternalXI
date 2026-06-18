import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_stage_card.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventMatchPrepareScreen extends StatefulWidget {
  const ClashEventMatchPrepareScreen({
    required this.eventId,
    required this.stageId,
    super.key,
  });

  final String eventId;
  final String stageId;

  @override
  State<ClashEventMatchPrepareScreen> createState() =>
      _ClashEventMatchPrepareScreenState();
}

class _ClashEventMatchPrepareScreenState
    extends State<ClashEventMatchPrepareScreen> {
  ClashCharacterEventStage? _stage;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lineups = context.read<ClashLineupsController>();
    final repo = context.read<ClashCharacterEventsRepository>();
    if (lineups.state == ClashLineupsLoadState.idle) {
      await lineups.load();
    }
    if (!mounted) {
      return;
    }
    final stage = await repo.findStage(widget.eventId, widget.stageId);
    if (mounted) {
      setState(() {
        _stage = stage;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lineups = context.watch<ClashLineupsController>();
    final stage = _stage;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (stage == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashEventsTitle)),
        body: Center(child: Text(l10n.clashEventsStageNotFound)),
      );
    }

    final activeLineup = lineups.activeLineup;
    final lineupPower = activeLineup == null
        ? 0
        : lineups.totalPower(activeLineup);
    final hasCompleteLineup = activeLineup?.isComplete ?? false;
    final recommended = stage.recommendedPower;
    final powerBelowRecommended =
        recommended != null && lineupPower < recommended;

    return Scaffold(
      appBar: AppBar(title: Text(stage.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            l10n.clashEventsStageTypeMatch,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
          ),
          const SizedBox(height: 16),
          if (recommended != null)
            _InfoTile(
              label: l10n.clashMatchPrepareRecommendedPower,
              value: '$recommended',
            ),
          _InfoTile(
            label: l10n.clashMatchPrepareLineupPower,
            value: '$lineupPower',
          ),
          if (stage.cardXpReward > 0)
            _InfoTile(
              label: l10n.clashEventsCardXpReward,
              value: '${stage.cardXpReward}',
            ),
          const SizedBox(height: 12),
          _StatusChip(
            ok: hasCompleteLineup,
            label: hasCompleteLineup
                ? l10n.clashMatchPrepareLineupComplete
                : l10n.clashMatchPrepareLineupIncomplete,
          ),
          if (powerBelowRecommended) ...[
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
          const SizedBox(height: 20),
          ClashEventStageCard(
            progress: ClashCharacterEventStageProgress(
              stage: stage,
              status: ClashCharacterEventStageStatus.available,
              clearCount: 0,
              canPlay: true,
            ),
            onPrimaryAction: null,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.clashTeam7v7),
            child: Text(l10n.clashMatchPrepareEditLineup),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: hasCompleteLineup
                ? () => context.push(
                    AppRoutes.clashEventStageMatch(
                      widget.eventId,
                      widget.stageId,
                    ),
                  )
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

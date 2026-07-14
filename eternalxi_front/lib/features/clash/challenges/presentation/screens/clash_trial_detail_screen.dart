import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/controllers/clash_trials_controller.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/widgets/clash_trial_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashTrialDetailScreen extends StatefulWidget {
  const ClashTrialDetailScreen({required this.trialId, super.key});

  final String trialId;

  @override
  State<ClashTrialDetailScreen> createState() => _ClashTrialDetailScreenState();
}

class _ClashTrialDetailScreenState extends State<ClashTrialDetailScreen> {
  late final ClashTrialsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashTrialsController(
      repository: context.read<ClashTrialsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.openTrial(widget.trialId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFloor(ClashTrialFloorProgress progress) {
    if (!progress.canPlay) {
      return;
    }
    context.push(
      AppRoutes.clashTrialFloorPrepare(widget.trialId, progress.floor.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final trial = _controller.activeTrial;
        if (trial == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.clashHomeChallenges)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(trial.title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                trial.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.clashTrialsLineHint(trial.line.displayNameEs),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ..._controller.floorProgress.map(
                (progress) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClashTrialFloorTile(
                    progress: progress,
                    line: trial.line,
                    onTap: () => _openFloor(progress),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_storage.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/controllers/clash_trials_controller.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/widgets/clash_trial_summary_card.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashTrialsScreen extends StatefulWidget {
  const ClashTrialsScreen({super.key});

  @override
  State<ClashTrialsScreen> createState() => _ClashTrialsScreenState();
}

class _ClashTrialsScreenState extends State<ClashTrialsScreen> {
  late final ClashTrialsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashTrialsController(
      repository: context.read<ClashTrialsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.loadTrials());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final teamUnlocked = ClashStoryGate.isTeamUnlocked(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final loading =
            _controller.state == ClashTrialsLoadState.loading &&
            _controller.summaries.isEmpty;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashHomeChallenges)),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.loadTrials,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _TrialsHeader(
                        remainingAttempts: _controller.remainingAttempts,
                        attemptLimit: ClashTrialsProgressState.dailyAttemptLimit,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.clashTrialsIntro,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.xiTextSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!teamUnlocked)
                        _LockedBanner(message: l10n.clashHomePrimaryLocked)
                      else if (_controller.summaries.isEmpty)
                        Center(child: Text(l10n.clashTrialsEmpty))
                      else
                        ..._controller.summaries.map(
                          (summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ClashTrialSummaryCard(
                              summary: summary,
                              onTap: teamUnlocked
                                  ? () => context.push(
                                      AppRoutes.clashTrialDetail(summary.trial.id),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _TrialsHeader extends StatelessWidget {
  const _TrialsHeader({
    required this.remainingAttempts,
    required this.attemptLimit,
  });

  final int remainingAttempts;
  final int attemptLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.clashTrialsModeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.clashTrialsAttemptsLeft(remainingAttempts, attemptLimit),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: context.xiTextSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

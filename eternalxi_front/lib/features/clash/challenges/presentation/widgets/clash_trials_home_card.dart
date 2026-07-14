import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashTrialsHomeCard extends StatefulWidget {
  const ClashTrialsHomeCard({super.key});

  @override
  State<ClashTrialsHomeCard> createState() => _ClashTrialsHomeCardState();
}

class _ClashTrialsHomeCardState extends State<ClashTrialsHomeCard> {
  int _remaining = ClashTrialsProgressState.dailyAttemptLimit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<ClashTrialsRepository>();
    final state = await repo.loadState();
    if (!mounted) {
      return;
    }
    setState(() => _remaining = repo.remainingDailyAttempts(state));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: context.xiCardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.xiDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.clashTrials),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.link_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.clashHomeChallenges, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      l10n.clashTrialsHomeCardSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.clashTrialsAttemptsLeft(
                  _remaining,
                  ClashTrialsProgressState.dailyAttemptLimit,
                ),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashWeeklyMissionsHomeCard extends StatefulWidget {
  const ClashWeeklyMissionsHomeCard({super.key});

  @override
  State<ClashWeeklyMissionsHomeCard> createState() =>
      _ClashWeeklyMissionsHomeCardState();
}

class _ClashWeeklyMissionsHomeCardState
    extends State<ClashWeeklyMissionsHomeCard> {
  ClashWeeklyMissionsSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final repo = context.read<ClashWeeklyMissionsRepository>();
      final summary = await repo.fetchSummary();
      if (mounted) {
        setState(() => _summary = summary);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = _summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.clashWeeklyMissionsHomeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.clashWeeklyMissionsHomePending(summary.claimableCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => context.push(AppRoutes.clashWeeklyMissions),
                child: Text(l10n.clashWeeklyMissionsHomeView),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

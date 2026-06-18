import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_compact_card.dart';
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
    final summary = _summary;
    final subtitle = summary == null
        ? null
        : l10n.clashWeeklyMissionsHomePending(summary.claimableCount);

    return ClashHomeCompactCard(
      icon: Icons.date_range_rounded,
      title: l10n.clashWeeklyMissionsHomeTitle,
      subtitle: subtitle,
      badgeCount: summary?.claimableCount,
      viewLabel: l10n.clashWeeklyMissionsHomeView,
      onView: () => context.push(AppRoutes.clashWeeklyMissions),
    );
  }
}

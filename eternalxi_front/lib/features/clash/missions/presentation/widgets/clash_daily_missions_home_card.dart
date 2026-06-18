import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_compact_card.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashDailyMissionsHomeCard extends StatefulWidget {
  const ClashDailyMissionsHomeCard({super.key});

  @override
  State<ClashDailyMissionsHomeCard> createState() =>
      _ClashDailyMissionsHomeCardState();
}

class _ClashDailyMissionsHomeCardState
    extends State<ClashDailyMissionsHomeCard> {
  ClashDailyMissionsSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final repo = context.read<ClashDailyMissionsRepository>();
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
        : l10n.clashDailyMissionsHomePending(summary.claimableCount);

    return ClashHomeCompactCard(
      icon: Icons.assignment_turned_in_rounded,
      title: l10n.clashDailyMissionsHomeTitle,
      subtitle: subtitle,
      viewLabel: l10n.clashDailyMissionsHomeView,
      onView: () => context.push(AppRoutes.clashMissions),
    );
  }
}

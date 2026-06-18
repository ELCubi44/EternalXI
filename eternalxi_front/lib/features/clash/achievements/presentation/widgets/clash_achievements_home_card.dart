import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_compact_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashAchievementsHomeCard extends StatefulWidget {
  const ClashAchievementsHomeCard({super.key});

  @override
  State<ClashAchievementsHomeCard> createState() =>
      _ClashAchievementsHomeCardState();
}

class _ClashAchievementsHomeCardState extends State<ClashAchievementsHomeCard> {
  ClashAchievementsSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    try {
      final repo = context.read<ClashAchievementsRepository>();
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
        : l10n.clashAchievementsHomePending(summary.claimableCount);

    return ClashHomeCompactCard(
      icon: Icons.emoji_events_rounded,
      title: l10n.clashAchievementsHomeTitle,
      subtitle: subtitle,
      viewLabel: l10n.clashAchievementsHomeView,
      onView: () => context.push(AppRoutes.clashAchievements),
    );
  }
}

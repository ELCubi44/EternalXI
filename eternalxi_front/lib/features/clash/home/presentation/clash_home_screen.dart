import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/widgets/clash_achievements_home_card.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/widgets/clash_gifts_home_card.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_featured_event_card.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_header.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_primary_action_grid.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_section_title.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_daily_missions_home_card.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_weekly_missions_home_card.dart';
import 'package:eternal_xi/features/clash/news/presentation/widgets/clash_news_home_card.dart';
import 'package:eternal_xi/features/clash/shop/presentation/widgets/clash_shop_home_card.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hub principal del modo Clash (Fase 35).
class ClashHomeScreen extends StatefulWidget {
  const ClashHomeScreen({super.key, this.autoCheckService});

  /// Inyectable en tests (Fase 79).
  final ClashSyncAutoCheckService? autoCheckService;

  @override
  State<ClashHomeScreen> createState() => _ClashHomeScreenState();
}

class _ClashHomeScreenState extends State<ClashHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _runAutoCheckIfEnabled(),
    );
  }

  Future<void> _runAutoCheckIfEnabled() async {
    if (!mounted) {
      return;
    }

    final service = widget.autoCheckService ?? _readAutoCheckService(context);
    if (service == null) {
      return;
    }

    await service.runIfEnabled();
    if (mounted) {
      setState(() {});
    }
  }

  ClashSyncAutoCheckService? _readAutoCheckService(BuildContext context) {
    try {
      return context.read<ClashSyncAutoCheckService>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const ClashHomeHeader(),
          const SizedBox(height: 20),
          ClashHomeSectionTitle(l10n.clashHomePlaySection),
          const ClashHomePrimaryActionGrid(),
          const SizedBox(height: 20),
          const ClashHomeFeaturedEventCard(),
          const SizedBox(height: 20),
          ClashHomeSectionTitle(l10n.clashHomeDailyActivity),
          const ClashDailyMissionsHomeCard(),
          const SizedBox(height: 8),
          const ClashWeeklyMissionsHomeCard(),
          const SizedBox(height: 8),
          const ClashAchievementsHomeCard(),
          const SizedBox(height: 20),
          ClashHomeSectionTitle(l10n.clashHomeNoticesSection),
          const ClashNewsHomeCard(),
          const SizedBox(height: 8),
          const ClashGiftsHomeCard(),
          const SizedBox(height: 8),
          const ClashShopHomeCard(),
        ],
      ),
    );
  }
}

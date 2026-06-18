import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/presentation/controllers/clash_daily_missions_controller.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_daily_mission_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashDailyMissionsScreen extends StatefulWidget {
  const ClashDailyMissionsScreen({super.key});

  @override
  State<ClashDailyMissionsScreen> createState() =>
      _ClashDailyMissionsScreenState();
}

class _ClashDailyMissionsScreenState extends State<ClashDailyMissionsScreen> {
  late final ClashDailyMissionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashDailyMissionsController(
      repository: context.read<ClashDailyMissionsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _claimMission(String missionId) async {
    final l10n = context.l10n;
    final result = await _controller.claimMission(missionId);
    if (!mounted) {
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashDailyMissionsClaimSuccess),
        ),
      );
    }
  }

  Future<void> _claimAll() async {
    final l10n = context.l10n;
    final results = await _controller.claimAll();
    if (!mounted) {
      return;
    }
    final claimed = results.where((item) => item.success).length;
    if (claimed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashDailyMissionsClaimSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final isClaiming =
            _controller.state == ClashDailyMissionsLoadState.claiming;
        final isLoading =
            _controller.state == ClashDailyMissionsLoadState.loading &&
            _controller.missions.isEmpty;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashDailyMissionsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        l10n.clashDailyMissionsResetHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.xiTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.clashDailyMissionsCompletedSummary(
                          summary.completedCount,
                          summary.totalMissions,
                        ),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clashDailyMissionsClaimedSummary(
                          summary.claimedCount,
                          summary.totalMissions,
                        ),
                        style: theme.textTheme.labelLarge,
                      ),
                      if (summary.claimableCount > 0) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: isClaiming ? null : _claimAll,
                            child: Text(l10n.clashDailyMissionsClaimAll),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ..._controller.missions.map(
                        (item) => ClashDailyMissionCard(
                          progress: item,
                          isClaiming: isClaiming,
                          onClaim: item.canClaim
                              ? () => _claimMission(item.mission.id)
                              : null,
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

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/presentation/controllers/clash_weekly_missions_controller.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_weekly_mission_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_empty_state_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashWeeklyMissionsScreen extends StatefulWidget {
  const ClashWeeklyMissionsScreen({super.key});

  @override
  State<ClashWeeklyMissionsScreen> createState() =>
      _ClashWeeklyMissionsScreenState();
}

class _ClashWeeklyMissionsScreenState extends State<ClashWeeklyMissionsScreen> {
  late final ClashWeeklyMissionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashWeeklyMissionsController(
      repository: context.read<ClashWeeklyMissionsRepository>(),
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
          content: Text(l10n.clashWeeklyMissionsClaimSuccess),
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
          content: Text(l10n.clashWeeklyMissionsClaimSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final isClaiming =
            _controller.state == ClashWeeklyMissionsLoadState.claiming;
        final isLoading =
            _controller.state == ClashWeeklyMissionsLoadState.loading &&
            _controller.missions.isEmpty;
        final progress = summary.totalMissions == 0
            ? 0.0
            : summary.completedCount / summary.totalMissions;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashWeeklyMissionsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClashProgressSummaryCard(
                        hint: l10n.clashWeeklyMissionsResetHint,
                        secondaryHint: l10n.clashWeeklyMissionsWeekLabel(
                          summary.weekKey,
                        ),
                        lines: [
                          l10n.clashWeeklyMissionsCompletedSummary(
                            summary.completedCount,
                            summary.totalMissions,
                          ),
                          l10n.clashWeeklyMissionsClaimedSummary(
                            summary.claimedCount,
                            summary.totalMissions,
                          ),
                        ],
                        progress: progress,
                        action: summary.claimableCount > 0
                            ? ClashClaimButton(
                                label: l10n.clashWeeklyMissionsClaimAll,
                                loading: isClaiming,
                                onPressed: _claimAll,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (_controller.missions.isEmpty)
                        ClashEmptyStateCard(
                          message: l10n.clashWeeklyMissionsEmpty,
                          icon: Icons.date_range_outlined,
                        )
                      else
                        ..._controller.missions.map(
                          (item) => ClashWeeklyMissionCard(
                            progress: item,
                            isClaiming: isClaiming,
                            highlightRewards: true,
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

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/presentation/controllers/clash_weekly_missions_controller.dart';
import 'package:eternal_xi/features/clash/missions/presentation/widgets/clash_weekly_mission_card.dart';
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
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final isClaiming =
            _controller.state == ClashWeeklyMissionsLoadState.claiming;
        final isLoading =
            _controller.state == ClashWeeklyMissionsLoadState.loading &&
            _controller.missions.isEmpty;

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
                      Text(
                        l10n.clashWeeklyMissionsResetHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.xiTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clashWeeklyMissionsWeekLabel(summary.weekKey),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.xiTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.clashWeeklyMissionsCompletedSummary(
                          summary.completedCount,
                          summary.totalMissions,
                        ),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clashWeeklyMissionsClaimedSummary(
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
                            child: Text(l10n.clashWeeklyMissionsClaimAll),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ..._controller.missions.map(
                        (item) => ClashWeeklyMissionCard(
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

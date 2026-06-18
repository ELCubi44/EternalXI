import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/controllers/clash_achievements_controller.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/widgets/clash_achievement_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_empty_state_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashAchievementsScreen extends StatefulWidget {
  const ClashAchievementsScreen({super.key});

  @override
  State<ClashAchievementsScreen> createState() =>
      _ClashAchievementsScreenState();
}

class _ClashAchievementsScreenState extends State<ClashAchievementsScreen> {
  late final ClashAchievementsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashAchievementsController(
      repository: context.read<ClashAchievementsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _claimAchievement(String achievementId) async {
    final l10n = context.l10n;
    final result = await _controller.claimAchievement(achievementId);
    if (!mounted) {
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashAchievementsClaimSuccess),
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
          content: Text(l10n.clashAchievementsClaimSuccess),
        ),
      );
    }
  }

  String _filterLabel(ClashAchievementFilter filter, dynamic l10n) {
    return switch (filter) {
      ClashAchievementFilter.all => l10n.clashAchievementsFilterAll,
      ClashAchievementFilter.inProgress =>
        l10n.clashAchievementsFilterInProgress,
      ClashAchievementFilter.completed => l10n.clashAchievementsFilterCompleted,
      ClashAchievementFilter.claimed => l10n.clashAchievementsFilterClaimed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final isClaiming =
            _controller.state == ClashAchievementsLoadState.claiming;
        final isLoading =
            _controller.state == ClashAchievementsLoadState.loading &&
            _controller.achievements.isEmpty;
        final filtered = _controller.filteredAchievements;
        final progress = summary.totalAchievements == 0
            ? 0.0
            : summary.completedCount / summary.totalAchievements;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashAchievementsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClashProgressSummaryCard(
                        hint: l10n.clashAchievementsPermanentHint,
                        lines: [
                          l10n.clashAchievementsCompletedSummary(
                            summary.completedCount,
                            summary.totalAchievements,
                          ),
                          l10n.clashAchievementsClaimedSummary(
                            summary.claimedCount,
                            summary.totalAchievements,
                          ),
                        ],
                        progress: progress,
                        action: summary.claimableCount > 0
                            ? ClashClaimButton(
                                label: l10n.clashAchievementsClaimAll,
                                loading: isClaiming,
                                onPressed: _claimAll,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ClashAchievementFilter.values
                              .map((filter) {
                                final selected = _controller.filter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(_filterLabel(filter, l10n)),
                                    selected: selected,
                                    onSelected: (_) =>
                                        _controller.setFilter(filter),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        ClashEmptyStateCard(
                          message: l10n.clashAchievementsEmptyFilter,
                          icon: Icons.emoji_events_outlined,
                        )
                      else
                        ...filtered.map(
                          (item) => ClashAchievementCard(
                            progress: item,
                            isClaiming: isClaiming,
                            onClaim: item.canClaim
                                ? () => _claimAchievement(item.achievement.id)
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

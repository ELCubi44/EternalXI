import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:flutter/material.dart';

class ClashDailyMissionCard extends StatelessWidget {
  const ClashDailyMissionCard({
    super.key,
    required this.progress,
    required this.onClaim,
    this.isClaiming = false,
  });

  final ClashDailyMissionProgress progress;
  final VoidCallback? onClaim;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mission = progress.mission;

    final statusLabel = progress.claimed
        ? l10n.clashDailyMissionsStatusClaimed
        : progress.isCompleted
        ? l10n.clashDailyMissionsStatusClaim
        : l10n.clashDailyMissionsStatusInProgress;

    final statusColor = progress.claimed
        ? context.xiTextSecondary
        : progress.isCompleted
        ? theme.colorScheme.primary
        : context.xiTextSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mission.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.clashDailyMissionsProgress(
                      progress.current,
                      mission.target,
                    ),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _rewardLabel(context, mission.reward),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            if (progress.canClaim) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: isClaiming ? null : onClaim,
                  child: Text(l10n.clashDailyMissionsStatusClaim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rewardLabel(BuildContext context, ClashDailyMissionReward reward) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (reward.coins > 0) {
      parts.add(l10n.clashDailyMissionsRewardCoins(reward.coins));
    }
    if (reward.gems > 0) {
      parts.add(l10n.clashDailyMissionsRewardGems(reward.gems));
    }
    if (reward.expMaterial != null) {
      parts.add(
        l10n.clashShopGrantLine(
          reward.expMaterial!.id,
          reward.expMaterial!.quantity,
        ),
      );
    }
    if (reward.techniqueBook != null) {
      parts.add(
        l10n.clashShopGrantLine(
          reward.techniqueBook!.id,
          reward.techniqueBook!.quantity,
        ),
      );
    }
    return parts.join(' · ');
  }
}

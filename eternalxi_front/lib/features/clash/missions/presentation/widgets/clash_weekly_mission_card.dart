import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:flutter/material.dart';

class ClashWeeklyMissionCard extends StatelessWidget {
  const ClashWeeklyMissionCard({
    super.key,
    required this.progress,
    required this.onClaim,
    this.isClaiming = false,
  });

  final ClashWeeklyMissionProgress progress;
  final VoidCallback? onClaim;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mission = progress.mission;

    final statusLabel = progress.claimed
        ? l10n.clashWeeklyMissionsStatusClaimed
        : progress.isCompleted
        ? l10n.clashWeeklyMissionsStatusClaim
        : l10n.clashWeeklyMissionsStatusInProgress;

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
                    l10n.clashWeeklyMissionsProgress(
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
                  child: Text(l10n.clashWeeklyMissionsStatusClaim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rewardLabel(BuildContext context, ClashWeeklyMissionReward reward) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (reward.coins > 0) {
      parts.add(l10n.clashWeeklyMissionsRewardCoins(reward.coins));
    }
    if (reward.gems > 0) {
      parts.add(l10n.clashWeeklyMissionsRewardGems(reward.gems));
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
    if (reward.evolutionMaterial != null) {
      parts.add(
        l10n.clashShopGrantLine(
          reward.evolutionMaterial!.id,
          reward.evolutionMaterial!.quantity,
        ),
      );
    }
    if (reward.ticket != null) {
      parts.add(
        l10n.clashShopGrantLine(reward.ticket!.id, reward.ticket!.quantity),
      );
    }
    return parts.join(' · ');
  }
}

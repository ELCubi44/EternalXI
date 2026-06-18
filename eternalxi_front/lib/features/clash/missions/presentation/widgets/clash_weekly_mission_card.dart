import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_status_chip.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_reward_preview_row.dart';
import 'package:flutter/material.dart';

class ClashWeeklyMissionCard extends StatelessWidget {
  const ClashWeeklyMissionCard({
    super.key,
    required this.progress,
    required this.onClaim,
    this.isClaiming = false,
    this.highlightRewards = false,
  });

  final ClashWeeklyMissionProgress progress;
  final VoidCallback? onClaim;
  final bool isClaiming;
  final bool highlightRewards;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mission = progress.mission;
    final fraction = mission.target <= 0
        ? 0.0
        : (progress.current / mission.target).clamp(0.0, 1.0);

    final status = progress.claimed
        ? ClashProgressStatus.claimed
        : progress.isCompleted
        ? ClashProgressStatus.claimable
        : ClashProgressStatus.inProgress;

    final statusLabel = switch (status) {
      ClashProgressStatus.claimed => l10n.clashWeeklyMissionsStatusClaimed,
      ClashProgressStatus.claimable => l10n.clashWeeklyMissionsStatusClaim,
      ClashProgressStatus.inProgress =>
        l10n.clashWeeklyMissionsStatusInProgress,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: progress.canClaim
            ? theme.colorScheme.secondary.withValues(alpha: 0.08)
            : context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress.canClaim
              ? theme.colorScheme.secondary
              : context.xiDivider,
          width: progress.canClaim ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 20,
                color: highlightRewards
                    ? theme.colorScheme.secondary
                    : context.xiTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ClashProgressStatusChip(label: statusLabel, status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mission.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: theme.colorScheme.secondary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashWeeklyMissionsProgress(progress.current, mission.target),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClashRewardPreviewRow(rewards: _rewardParts(context, mission.reward)),
          if (progress.canClaim) ...[
            const SizedBox(height: 14),
            ClashClaimButton(
              label: l10n.clashWeeklyMissionsStatusClaim,
              loading: isClaiming,
              onPressed: onClaim,
            ),
          ],
        ],
      ),
    );
  }

  List<String> _rewardParts(
    BuildContext context,
    ClashWeeklyMissionReward reward,
  ) {
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
    return parts;
  }
}

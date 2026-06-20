import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_status_chip.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_reward_preview_row.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
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
    final fraction = mission.target <= 0
        ? 0.0
        : (progress.current / mission.target).clamp(0.0, 1.0);

    final status = progress.claimed
        ? ClashProgressStatus.claimed
        : progress.isCompleted
        ? ClashProgressStatus.claimable
        : ClashProgressStatus.inProgress;

    final statusLabel = switch (status) {
      ClashProgressStatus.claimed => l10n.clashDailyMissionsStatusClaimed,
      ClashProgressStatus.claimable => l10n.clashDailyMissionsStatusClaim,
      ClashProgressStatus.inProgress => l10n.clashDailyMissionsStatusInProgress,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: progress.canClaim
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress.canClaim
              ? theme.colorScheme.primary
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
              Expanded(
                child: Text(
                  mission.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashDailyMissionsProgress(progress.current, mission.target),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClashRewardPreviewRow(
            items: ClashRewardDisplayBuilder.fromDailyMissionReward(
              mission.reward,
              l10n,
            ),
          ),
          if (progress.canClaim) ...[
            const SizedBox(height: 14),
            ClashClaimButton(
              label: l10n.clashDailyMissionsStatusClaim,
              loading: isClaiming,
              onPressed: onClaim,
            ),
          ],
        ],
      ),
    );
  }
}

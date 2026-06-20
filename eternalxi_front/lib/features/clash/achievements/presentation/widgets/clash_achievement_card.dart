import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_status_chip.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_reward_preview_row.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:flutter/material.dart';

class ClashAchievementCard extends StatelessWidget {
  const ClashAchievementCard({
    super.key,
    required this.progress,
    required this.onClaim,
    this.isClaiming = false,
  });

  final ClashAchievementProgress progress;
  final VoidCallback? onClaim;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final achievement = progress.achievement;
    final fraction = achievement.target <= 0
        ? 0.0
        : (progress.current / achievement.target).clamp(0.0, 1.0);

    final status = progress.claimed
        ? ClashProgressStatus.claimed
        : progress.isCompleted
        ? ClashProgressStatus.claimable
        : ClashProgressStatus.inProgress;

    final statusLabel = switch (status) {
      ClashProgressStatus.claimed => l10n.clashAchievementsStatusClaimed,
      ClashProgressStatus.claimable => l10n.clashAchievementsStatusClaim,
      ClashProgressStatus.inProgress => l10n.clashAchievementsStatusInProgress,
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(achievement.type),
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClashProgressStatusChip(label: statusLabel, status: status),
            ],
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
            l10n.clashAchievementsProgress(
              progress.current,
              achievement.target,
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClashRewardPreviewRow(
            items: ClashRewardDisplayBuilder.fromAchievementReward(
              achievement.reward,
              l10n,
            ),
          ),
          if (progress.canClaim) ...[
            const SizedBox(height: 14),
            ClashClaimButton(
              label: l10n.clashAchievementsStatusClaim,
              loading: isClaiming,
              onPressed: onClaim,
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(ClashAchievementType type) {
    return switch (type) {
      ClashAchievementType.playMatch => Icons.sports_soccer_rounded,
      ClashAchievementType.winMatch => Icons.emoji_events_rounded,
      ClashAchievementType.summon => Icons.auto_awesome_rounded,
      ClashAchievementType.collectCards => Icons.style_rounded,
      ClashAchievementType.levelUpCard => Icons.trending_up_rounded,
      ClashAchievementType.upgradeTechnique => Icons.menu_book_rounded,
      ClashAchievementType.evolveCard => Icons.military_tech_rounded,
      ClashAchievementType.unlockSkillNode => Icons.hub_rounded,
    };
  }
}

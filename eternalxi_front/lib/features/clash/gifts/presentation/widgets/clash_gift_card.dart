import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_status.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_status_chip.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_reward_preview_row.dart';
import 'package:flutter/material.dart';

class ClashGiftCard extends StatelessWidget {
  const ClashGiftCard({
    super.key,
    required this.entry,
    required this.onClaim,
    this.isClaiming = false,
  });

  final ClashGiftEntry entry;
  final VoidCallback? onClaim;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gift = entry.gift;
    final isAvailable = entry.status == ClashGiftStatus.available;

    final status = switch (entry.status) {
      ClashGiftStatus.available => ClashProgressStatus.claimable,
      ClashGiftStatus.claimed => ClashProgressStatus.claimed,
      ClashGiftStatus.expired => ClashProgressStatus.inProgress,
    };

    final statusLabel = switch (entry.status) {
      ClashGiftStatus.available => l10n.clashGiftsStatusAvailable,
      ClashGiftStatus.claimed => l10n.clashGiftsStatusClaimed,
      ClashGiftStatus.expired => l10n.clashGiftsStatusExpired,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? theme.colorScheme.primary : context.xiDivider,
          width: isAvailable ? 1.5 : 1,
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
                  Icons.card_giftcard_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (gift.isPinned) ...[
                          Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            gift.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gift.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                        height: 1.4,
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
          ClashRewardPreviewRow(rewards: _rewardParts(context, gift.rewards)),
          if (entry.canClaim) ...[
            const SizedBox(height: 14),
            ClashClaimButton(
              label: l10n.clashGiftsStatusClaim,
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
    ClashAchievementReward reward,
  ) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (reward.coins > 0) {
      parts.add(l10n.clashAchievementsRewardCoins(reward.coins));
    }
    if (reward.gems > 0) {
      parts.add(l10n.clashAchievementsRewardGems(reward.gems));
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

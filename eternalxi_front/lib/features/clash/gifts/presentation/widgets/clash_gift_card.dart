import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_status.dart';
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

    final statusLabel = switch (entry.status) {
      ClashGiftStatus.available => l10n.clashGiftsStatusAvailable,
      ClashGiftStatus.claimed => l10n.clashGiftsStatusClaimed,
      ClashGiftStatus.expired => l10n.clashGiftsStatusExpired,
    };

    final statusColor = switch (entry.status) {
      ClashGiftStatus.available => theme.colorScheme.primary,
      ClashGiftStatus.claimed => context.xiTextSecondary,
      ClashGiftStatus.expired => theme.colorScheme.error,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gift.isPinned) ...[
                  Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    gift.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
            const SizedBox(height: 4),
            Text(
              gift.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _rewardLabel(context, gift.rewards),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            if (entry.canClaim) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: isClaiming ? null : onClaim,
                  child: Text(l10n.clashGiftsStatusClaim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rewardLabel(BuildContext context, ClashAchievementReward reward) {
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
    return parts.join(' · ');
  }
}

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_status.dart';
import 'package:flutter/material.dart';

/// Chip compacto de recompensa con icono, label y cantidad (Fase 58).
class ClashRewardChip extends StatelessWidget {
  const ClashRewardChip({required this.item, this.muted = false, super.key});

  final ClashRewardDisplayItem item;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final textColor = muted ? context.xiTextSecondary : null;
    final iconColor = muted
        ? context.xiTextSecondary
        : theme.colorScheme.primary;

    final quantityText = item.showQuantity
        ? l10n.clashRewardQuantitySuffix(item.quantity!)
        : null;
    final detail = item.detail?.trim();
    final hasDetail = detail != null && detail.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundForStatus(context, item.status, muted),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _borderForStatus(context, item.status, muted),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                  ),
                ),
                if (hasDetail)
                  Text(
                    detail,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: context.xiTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (quantityText != null) ...[
            const SizedBox(width: 4),
            Text(
              quantityText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _backgroundForStatus(
    BuildContext context,
    ClashRewardDisplayStatus status,
    bool muted,
  ) {
    if (muted || status == ClashRewardDisplayStatus.unavailable) {
      return context.xiChipBackground.withValues(alpha: 0.6);
    }
    if (status == ClashRewardDisplayStatus.claimed) {
      return Colors.green.withValues(alpha: 0.08);
    }
    return context.xiChipBackground;
  }

  Color _borderForStatus(
    BuildContext context,
    ClashRewardDisplayStatus status,
    bool muted,
  ) {
    if (status == ClashRewardDisplayStatus.claimed) {
      return Colors.green.withValues(alpha: 0.35);
    }
    if (status == ClashRewardDisplayStatus.unavailable || muted) {
      return context.xiDivider;
    }
    return context.xiDivider;
  }
}

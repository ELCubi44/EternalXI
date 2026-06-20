import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';

class ClashRewardHistoryTile extends StatelessWidget {
  const ClashRewardHistoryTile({required this.entry, super.key});

  final ClashRewardHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = ClashRewardDisplayBuilder.fromGrantResult(
      entry.toGrantResult(),
      l10n,
    );
    final statusLabel = entry.isFailure
        ? l10n.clashRewardHistoryStatusFailure
        : entry.isPartial
        ? l10n.clashRewardHistoryStatusPartial
        : null;
    final statusColor = entry.isFailure
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sourceLabel(l10n, entry.sourceType),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(entry.createdAt, l10n),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
          ),
          if (statusLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              statusLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClashRewardList(items: items),
          ],
        ],
      ),
    );
  }

  String _sourceLabel(dynamic l10n, ClashRewardHistorySourceType sourceType) {
    return switch (sourceType) {
      ClashRewardHistorySourceType.gift => l10n.clashRewardHistorySourceGift,
      ClashRewardHistorySourceType.achievement =>
        l10n.clashRewardHistorySourceAchievement,
      ClashRewardHistorySourceType.dailyMission =>
        l10n.clashRewardHistorySourceDailyMission,
      ClashRewardHistorySourceType.weeklyMission =>
        l10n.clashRewardHistorySourceWeeklyMission,
      ClashRewardHistorySourceType.shop => l10n.clashRewardHistorySourceShop,
      ClashRewardHistorySourceType.event => l10n.clashRewardHistorySourceEvent,
      ClashRewardHistorySourceType.story => l10n.clashRewardHistorySourceStory,
    };
  }

  String _formatDate(DateTime createdAt, dynamic l10n) {
    final local = createdAt.toLocal();
    final two = (int value) => value.toString().padLeft(2, '0');
    return l10n.clashRewardHistoryDate(
      local.year,
      local.month,
      local.day,
      local.hour,
      two(local.minute),
    );
  }
}

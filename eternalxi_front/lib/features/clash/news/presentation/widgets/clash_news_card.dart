import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_item.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_type.dart';
import 'package:flutter/material.dart';

class ClashNewsCard extends StatelessWidget {
  const ClashNewsCard({
    super.key,
    required this.entry,
    required this.expanded,
    required this.onTap,
    required this.typeLabel,
  });

  final ClashNewsEntry entry;
  final bool expanded;
  final VoidCallback onTap;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final item = entry.item;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatShortDate(item.publishedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isPinned) ...[
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!entry.isRead)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.clashNewsBadgeNew,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TypeChip(label: typeLabel),
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                  height: 1.4,
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 12),
                Divider(color: context.xiDivider, height: 1),
                const SizedBox(height: 12),
                Text(
                  item.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.xiDivider),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String clashNewsTypeLabel(ClashNewsType type, dynamic l10n) {
  return switch (type) {
    ClashNewsType.update => l10n.clashNewsTypeUpdate,
    ClashNewsType.event => l10n.clashNewsTypeEvent,
    ClashNewsType.banner => l10n.clashNewsTypeBanner,
    ClashNewsType.maintenance => l10n.clashNewsTypeMaintenance,
    ClashNewsType.gift => l10n.clashNewsTypeGift,
  };
}

String clashNewsFilterLabel(ClashNewsFilter filter, dynamic l10n) {
  return switch (filter) {
    ClashNewsFilter.all => l10n.clashNewsFilterAll,
    ClashNewsFilter.unread => l10n.clashNewsFilterUnread,
    ClashNewsFilter.updates => l10n.clashNewsFilterUpdates,
    ClashNewsFilter.events => l10n.clashNewsFilterEvents,
    ClashNewsFilter.banners => l10n.clashNewsFilterBanners,
    ClashNewsFilter.notices => l10n.clashNewsFilterNotices,
  };
}

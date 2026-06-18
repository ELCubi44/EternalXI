import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_pity_card.dart';
import 'package:flutter/material.dart';

/// Tarjeta expandible de entrada de historial de gacha (Fase 38).
class ClashGachaHistoryEntryCard extends StatelessWidget {
  const ClashGachaHistoryEntryCard({required this.entry, super.key});

  final ClashGachaHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateText = _formatDateTime(entry.createdAt);
    final pullLabel = switch (entry.pullType) {
      ClashGachaPullType.single => l10n.clashGachaHistoryPullSingle,
      ClashGachaPullType.multi => l10n.clashGachaHistoryPullMulti,
      ClashGachaPullType.dailySingle => l10n.clashGachaHistoryPullDaily,
      ClashGachaPullType.ticketSingle => l10n.clashGachaHistoryPullTicket,
    };
    final hasPity = entry.results.any((item) => item.wasPity);
    final hasGuarantee = entry.results.any((item) => item.wasMultiGuarantee);

    return Container(
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            entry.bannerName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                dateText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MetaChip(label: pullLabel),
                  if (entry.pullType != ClashGachaPullType.ticketSingle)
                    _MetaChip(
                      label: l10n.clashGachaHistorySpent(entry.spentGems),
                    ),
                  _MetaChip(
                    label: ClashCardEvolutionResolver.rarityLabel(
                      entry.bestRarity,
                    ),
                  ),
                  _MetaChip(label: '${entry.results.length}'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.clashGachaHistorySummary(
                  entry.results.length,
                  ClashCardEvolutionResolver.rarityLabel(entry.bestRarity),
                ),
                style: theme.textTheme.bodySmall,
              ),
              if (hasPity || hasGuarantee) ...[
                const SizedBox(height: 6),
                Wrap(
                  children: [
                    if (hasPity)
                      ClashGachaResultChip(label: l10n.clashGachaPityChip),
                    if (hasGuarantee)
                      ClashGachaResultChip(
                        label: l10n.clashGachaMultiGuaranteeChip,
                      ),
                  ],
                ),
              ],
            ],
          ),
          children: [
            for (final item in entry.results)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _HistoryResultTile(item: item),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryResultTile extends StatelessWidget {
  const _HistoryResultTile({required this.item});

  final ClashGachaHistoryResultItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = item.isNew
        ? l10n.clashGachaResultNew
        : item.upgradedRarity
        ? l10n.clashGachaResultUpgraded
        : l10n.clashGachaResultDuplicate;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.xiBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cardName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(status),
                Wrap(
                  children: [
                    if (item.wasPity)
                      ClashGachaResultChip(label: l10n.clashGachaPityChip),
                    if (item.wasMultiGuarantee)
                      ClashGachaResultChip(
                        label: l10n.clashGachaMultiGuaranteeChip,
                      ),
                  ],
                ),
              ],
            ),
          ),
          ClashRarityBadge(rarity: item.rarity),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.xiChipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}

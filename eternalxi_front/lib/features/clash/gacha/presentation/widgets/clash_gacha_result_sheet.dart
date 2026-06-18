import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_pity_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashGachaResultSheet extends StatelessWidget {
  const ClashGachaResultSheet({required this.result, super.key});

  final ClashGachaPullResult result;

  static Future<void> show(BuildContext context, ClashGachaPullResult result) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ClashGachaResultSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.clashGachaResultTitle} (${result.results.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.clashGachaResultSpent(
                result.spentGems,
                result.remainingGems,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: result.results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = result.results[index];
                  return _ResultRow(item: item);
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.clashSummonHistory);
              },
              child: Text(l10n.clashGachaViewHistory),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item});

  final ClashGachaPullResultItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = item.isNew
        ? l10n.clashGachaResultNew
        : item.upgradedRarity
        ? l10n.clashGachaResultUpgraded
        : l10n.clashGachaResultDuplicate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(12),
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
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
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
                if (item.isDuplicate)
                  Text(
                    l10n.clashGachaResultDuplicates(item.duplicateCopiesAfter),
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

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_result_card.dart';
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

  String _pullTypeLabel(dynamic l10n) => switch (result.pullType) {
    ClashGachaPullType.single => l10n.clashGachaHistoryPullSingle,
    ClashGachaPullType.multi => l10n.clashGachaHistoryPullMulti,
    ClashGachaPullType.dailySingle => l10n.clashGachaHistoryPullDaily,
    ClashGachaPullType.ticketSingle => l10n.clashGachaHistoryPullTicket,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pullLabel = _pullTypeLabel(l10n);
    final bestRarity = ClashCardEvolutionResolver.rarityLabel(
      result.bestRarity,
    );
    final isScrollable = result.results.length > 4;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: isScrollable ? 0.75 : 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${l10n.clashGachaResultTitle} (${result.results.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.clashGachaResultPullType(pullLabel),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.usedTicket
                      ? l10n.clashGachaResultTicket(result.remainingGems)
                      : l10n.clashGachaResultSpent(
                          result.spentGems,
                          result.remainingGems,
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.clashGachaResultBestRarity(bestRarity),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: result.results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return ClashGachaResultCard(item: result.results[index]);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.clashSummonHistory);
                        },
                        child: Text(l10n.clashGachaViewHistory),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.clashGachaClose),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_section.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';

class ClashShopProductCard extends StatelessWidget {
  const ClashShopProductCard({
    required this.product,
    required this.canAfford,
    required this.purchasing,
    required this.onBuy,
    super.key,
  });

  final ClashShopProduct product;
  final bool canAfford;
  final bool purchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final section = ClashShopSection.forProduct(product);
    final accent = section.accentColor(theme.colorScheme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _CategoryBadge(
                      label: _sectionLabel(l10n, section),
                      color: accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.paid_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.clashShopProductCost(product.costCoins),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.clashShopIncludes,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClashRewardList(
            items: ClashRewardDisplayBuilder.fromShopProduct(product, l10n),
            layout: ClashRewardListLayout.wrap,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: purchasing || !canAfford ? null : onBuy,
            child: purchasing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.clashShopBuyButton),
          ),
          if (!canAfford && !purchasing) ...[
            const SizedBox(height: 6),
            Text(
              l10n.clashShopButtonDisabledCoins,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _sectionLabel(dynamic l10n, ClashShopSection section) {
    return switch (section) {
      ClashShopSection.materials => l10n.clashShopSectionMaterials,
      ClashShopSection.techniques => l10n.clashShopSectionTechniques,
      ClashShopSection.evolution => l10n.clashShopSectionEvolution,
      ClashShopSection.tickets => l10n.clashShopSectionTickets,
    };
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

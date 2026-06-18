import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
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
          Text(
            product.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.clashShopProductCost(product.costCoins),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashShopIncludes,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final grant in product.grants)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                l10n.clashShopGrantLine(grant.label, grant.quantity),
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: purchasing || !canAfford ? null : onBuy,
            child: Text(l10n.clashShopBuyButton),
          ),
        ],
      ),
    );
  }
}

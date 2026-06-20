import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';

/// Diálogo de confirmación de compra en tienda Clash (Fase 39).
Future<bool?> showClashShopPurchaseDialog(
  BuildContext context, {
  required ClashShopProduct product,
  required int currentCoins,
}) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final canAfford = currentCoins >= product.costCoins;
  final balanceAfter = currentCoins - product.costCoins;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.clashShopConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                color: dialogContext.xiTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.clashShopProductCost(product.costCoins),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            if (canAfford) ...[
              const SizedBox(height: 6),
              Text(
                l10n.clashShopConfirmBalanceAfter(balanceAfter),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: dialogContext.xiTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              l10n.clashShopConfirmRewards,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ClashRewardList(
              items: ClashRewardDisplayBuilder.fromShopProduct(product, l10n),
              layout: ClashRewardListLayout.column,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: canAfford
              ? () => Navigator.of(dialogContext).pop(true)
              : null,
          child: Text(l10n.clashShopBuyButton),
        ),
      ],
    ),
  );
}

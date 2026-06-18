import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_error.dart';
import 'package:eternal_xi/features/clash/shop/presentation/controllers/clash_shop_controller.dart';
import 'package:eternal_xi/features/clash/shop/presentation/widgets/clash_shop_product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashShopScreen extends StatefulWidget {
  const ClashShopScreen({super.key});

  @override
  State<ClashShopScreen> createState() => _ClashShopScreenState();
}

class _ClashShopScreenState extends State<ClashShopScreen> {
  late final ClashShopController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashShopController(
      repository: context.read<ClashShopRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmPurchase(ClashShopProduct product) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clashShopConfirmTitle),
        content: Text(
          l10n.clashShopConfirmMessage(product.name, product.costCoins),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clashShopBuyButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final result = await _controller.purchase(product.id);
    if (!mounted) {
      return;
    }

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashShopPurchaseSuccess),
        ),
      );
      return;
    }

    final message = switch (result.error) {
      ClashShopPurchaseError.insufficientCoins =>
        l10n.clashShopInsufficientCoins,
      ClashShopPurchaseError.productNotFound => l10n.clashStoryLoadError,
      ClashShopPurchaseError.grantFailed => l10n.clashStoryLoadError,
      null => l10n.clashStoryLoadError,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClashShopController>.value(
      value: _controller,
      child: _ClashShopBody(onPurchase: _confirmPurchase),
    );
  }
}

class _ClashShopBody extends StatelessWidget {
  const _ClashShopBody({required this.onPurchase});

  final Future<void> Function(ClashShopProduct product) onPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashShopController>();

    if (controller.state == ClashShopLoadState.loading ||
        controller.state == ClashShopLoadState.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return Center(child: Text(controller.errorMessage!));
    }

    final purchasing = controller.state == ClashShopLoadState.purchasing;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          l10n.clashTabShop,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.clashShopLocalDisclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _WalletCard(coins: controller.walletCoins, gems: controller.walletGems),
        const SizedBox(height: 16),
        for (final product in controller.products) ...[
          ClashShopProductCard(
            product: product,
            canAfford: controller.canAfford(product),
            purchasing: purchasing,
            onBuy: () => onPurchase(product),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.coins, required this.gems});

  final int coins;
  final int gems;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.paid_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.clashShopWalletCoins(coins),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.diamond_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.clashGachaWalletGems(gems),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.xiTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

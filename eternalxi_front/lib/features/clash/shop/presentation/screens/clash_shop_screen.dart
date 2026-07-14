import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_section.dart';
import 'package:eternal_xi/features/clash/shop/presentation/controllers/clash_shop_controller.dart';
import 'package:eternal_xi/features/clash/shop/presentation/widgets/clash_shop_product_card.dart';
import 'package:eternal_xi/features/clash/shop/presentation/widgets/clash_shop_purchase_dialog.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
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
    final confirmed = await showClashShopPurchaseDialog(
      context,
      product: product,
      currentCoins: _controller.walletCoins,
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final result = await _controller.purchase(product.id);
    if (!mounted) {
      return;
    }

    ClashRewardFeedback.showShopPurchaseFeedback(context, result);
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

    final grouped = controller.productsBySection;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          l10n.clashTabShop,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.xiChipBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.xiDivider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: context.xiTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashShopLocalDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _WalletCard(coins: controller.walletCoins, gems: controller.walletGems),
        const SizedBox(height: 20),
        for (final section in ClashShopSection.displayOrder) ...[
          if ((grouped[section] ?? const []).isNotEmpty) ...[
            _SectionHeader(section: section),
            const SizedBox(height: 10),
            for (final product in grouped[section]!) ...[
              ClashShopProductCard(
                product: product,
                canAfford: controller.canAfford(product),
                purchasing: controller.isPurchasing(product.id),
                onBuy: () => onPurchase(product),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final ClashShopSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = section.accentColor(theme.colorScheme);
    final label = switch (section) {
      ClashShopSection.materials => l10n.clashShopSectionMaterials,
      ClashShopSection.techniques => l10n.clashShopSectionTechniques,
      ClashShopSection.evolution => l10n.clashShopSectionEvolution,
      ClashShopSection.tickets => l10n.clashShopSectionTickets,
    };

    return Row(
      children: [
        Icon(section.icon, size: 20, color: accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            ),
        ),
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
          Row(
            children: [
              Icon(Icons.paid_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashShopWalletCoins(coins),
                  style: theme.textTheme.titleSmall?.copyWith(
                    ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.diamond_rounded, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashGachaWalletGems(gems),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

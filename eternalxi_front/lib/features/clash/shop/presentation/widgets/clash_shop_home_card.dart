import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_compact_card.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tarjeta compacta de tienda en Inicio Clash (Fase 35).
class ClashShopHomeCard extends StatelessWidget {
  const ClashShopHomeCard({super.key});

  void _openShop(BuildContext context) {
    context.read<ClashNavigationController>().selectTab(3);
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      final path = GoRouterState.of(context).uri.path;
      if (path != AppRoutes.clash) {
        context.go(AppRoutes.clash);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = context.watch<ClashStoryController>().progress;
    final subtitle = l10n.clashHomeShopBalance(
      progress.walletCoins,
      progress.walletGems,
    );

    return ClashHomeCompactCard(
      icon: Icons.storefront_rounded,
      title: l10n.clashTabShop,
      subtitle: subtitle,
      viewLabel: l10n.clashHomeShopView,
      onView: () => _openShop(context),
    );
  }
}

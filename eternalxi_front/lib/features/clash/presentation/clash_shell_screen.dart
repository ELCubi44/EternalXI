import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_header_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashShellScreen extends StatelessWidget {
  const ClashShellScreen({required this.body, super.key});

  final Widget body;

  int _selectedTabIndex(BuildContext context) {
    final nav = context.watch<ClashNavigationController>();
    final routerState = GoRouter.maybeOf(context);
    if (routerState != null) {
      final path = GoRouterState.of(context).uri.path;
      if (path.contains('/cards') || path.contains('/team')) {
        return 1;
      }
    }
    return nav.tabIndex;
  }

  void _onTabSelected(BuildContext context, int index) {
    context.read<ClashNavigationController>().selectTab(index);
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
    final selectedIndex = _selectedTabIndex(context);
    final path = GoRouterState.of(context).uri.path;
    final isCardDetail = RegExp(r'^/clash/cards/[^/]+$').hasMatch(path);

    return Scaffold(
      backgroundColor: context.xiBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isCardDetail) const ClashHeaderBar(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: isCardDetail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onTabSelected(context, index),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: l10n.clashTabHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.groups_outlined),
                  selectedIcon: const Icon(Icons.groups_rounded),
                  label: l10n.clashTabTeam,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(
                    Icons.auto_awesome_rounded,
                    color: XiColors.techCyan,
                  ),
                  label: l10n.clashTabSummon,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront_rounded),
                  label: l10n.clashTabShop,
                ),
              ],
            ),
    );
  }
}

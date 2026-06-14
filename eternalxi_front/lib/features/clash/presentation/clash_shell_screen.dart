import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_header_bar.dart';
import 'package:eternal_xi/features/clash/shop/presentation/clash_shop_screen.dart';
import 'package:eternal_xi/features/clash/summon/presentation/clash_summon_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/clash_team_screen.dart';
import 'package:flutter/material.dart';

class ClashShellScreen extends StatefulWidget {
  const ClashShellScreen({super.key});

  @override
  State<ClashShellScreen> createState() => _ClashShellScreenState();
}

class _ClashShellScreenState extends State<ClashShellScreen> {
  int _tabIndex = 0;

  static const _screens = <Widget>[
    ClashHomeScreen(),
    ClashTeamScreen(),
    ClashSummonScreen(),
    ClashShopScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.xiBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ClashHeaderBar(),
          Expanded(
            child: IndexedStack(index: _tabIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          if (index == _tabIndex) return;
          setState(() => _tabIndex = index);
        },
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

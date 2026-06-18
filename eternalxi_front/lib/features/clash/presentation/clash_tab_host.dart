import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:eternal_xi/features/clash/summon/presentation/clash_summon_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/clash_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Contenedor de las cuatro pestañas principales del shell Clash.
class ClashTabHost extends StatelessWidget {
  const ClashTabHost({super.key});

  static const _screens = <Widget>[
    ClashHomeScreen(),
    ClashTeamScreen(),
    ClashSummonScreen(),
    ClashShopScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.watch<ClashNavigationController>().tabIndex;
    return IndexedStack(index: tabIndex, children: _screens);
  }
}

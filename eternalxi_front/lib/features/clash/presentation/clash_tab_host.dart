import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/content/clash_starter_bootstrap.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:eternal_xi/features/clash/summon/presentation/clash_summon_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/clash_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Contenedor de las cuatro pestanas principales del shell Clash.
class ClashTabHost extends StatefulWidget {
  const ClashTabHost({super.key});

  @override
  State<ClashTabHost> createState() => _ClashTabHostState();
}

class _ClashTabHostState extends State<ClashTabHost> {
  static const _screens = <Widget>[
    ClashHomeScreen(),
    ClashTeamScreen(),
    ClashSummonScreen(),
    ClashShopScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final bootstrap = ClashStarterBootstrap(
      collectionRepository: context.read<ClashPlayerCollectionRepository>(),
      storyRepository: context.read<ClashStoryRepository>(),
      storyController: context.read<ClashStoryController>(),
    );
    await bootstrap.runOnce();
    if (!mounted) return;
    context.read<ClashCardsRepository>().clearCacheForTests();
    await context.read<ClashCardsController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.watch<ClashNavigationController>().tabIndex;
    return IndexedStack(index: tabIndex, children: _screens);
  }
}

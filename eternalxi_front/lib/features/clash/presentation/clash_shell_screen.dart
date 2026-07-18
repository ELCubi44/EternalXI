import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_events_button.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_story_map_button.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_bottom_nav_bar.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_header_bar.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashShellScreen extends StatelessWidget {
  const ClashShellScreen({required this.body, super.key});

  final Widget body;

  /// Misma geometría que [ClashBottomNavBar] para colocar hub buttons encima.
  static const double _navPlateAspect = 1200 / 213;

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

  double _homeHubButtonsBottom(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navPad =
        bottomInset > 0 ? (bottomInset * 0.35).clamp(4.0, 12.0) : 4.0;
    final plateH = (size.width / _navPlateAspect) * 1.1;
    return plateH + navPad + 10;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedIndex = _selectedTabIndex(context);
    final path = GoRouterState.of(context).uri.path;
    final isCardDetail = RegExp(r'^/clash/cards/[^/]+$').hasMatch(path);
    final isCardCollection = path == AppRoutes.clashCards ||
        path == '${AppRoutes.clashCards}/';
    final isStoryPath = path == AppRoutes.clashStory ||
        path.startsWith('${AppRoutes.clashStory}/');
    final hideClashHeader =
        isCardDetail || isCardCollection || isStoryPath;
    // Inicio: fondo a pantalla completa con la cabecera encima (overlay).
    final headerOverBackground =
        !hideClashHeader && path == AppRoutes.clash && selectedIndex == 0;
    final showHomeHubButtons =
        path == AppRoutes.clash && selectedIndex == 0 && !isCardDetail;

    return WithFantasyAtmosphere(
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Scaffold(
              backgroundColor: Colors.transparent,
              // Solo en Inicio: el arte pasa detrás de la barra. En el resto se reserva espacio.
              extendBody: headerOverBackground,
              body: headerOverBackground
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        body,
                        const Align(
                          alignment: Alignment.topCenter,
                          child: ClashHeaderBar(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!hideClashHeader) const ClashHeaderBar(),
                        Expanded(child: body),
                      ],
                    ),
              bottomNavigationBar: isCardDetail
                  ? null
                  : Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent,
                        bottomAppBarTheme: const BottomAppBarThemeData(
                          color: Colors.transparent,
                          elevation: 0,
                        ),
                      ),
                      child: ClashBottomNavBar(
                        selectedIndex: selectedIndex,
                        onItemSelected: (index) =>
                            _onTabSelected(context, index),
                        items: [
                          ClashBottomNavItem(
                            iconAsset: ClashEpicAssets.clashNavHomeIcon,
                            label: l10n.clashTabHome,
                          ),
                          ClashBottomNavItem(
                            iconAsset: ClashEpicAssets.clashNavTeamIcon,
                            label: l10n.clashTabTeam,
                          ),
                          ClashBottomNavItem(
                            iconAsset: ClashEpicAssets.clashNavSummonIcon,
                            label: l10n.clashTabSummon,
                          ),
                          ClashBottomNavItem(
                            iconAsset: ClashEpicAssets.clashNavShopIcon,
                            label: l10n.clashTabShop,
                          ),
                        ],
                      ),
                    ),
            ),
            // Encima de la nav: si van en el body con extendBody, los toques
            // los come el tab Inicio y "Historia" parece muerto.
            if (showHomeHubButtons)
              Positioned(
                left: 10,
                right: 10,
                bottom: _homeHubButtonsBottom(context),
                child: Row(
                  children: [
                    const Expanded(child: ClashHomeStoryMapButton()),
                    SizedBox(width: MediaQuery.sizeOf(context).width * 0.04),
                    const Expanded(child: ClashHomeEventsButton()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

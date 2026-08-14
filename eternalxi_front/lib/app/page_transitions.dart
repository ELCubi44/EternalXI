import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Duration kAppPageTransitionDuration = Duration(milliseconds: 380);
const Duration kAppPageReverseDuration = Duration(milliseconds: 300);

Widget appFadeSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final enter = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final leave = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeInCubic,
  );

  return FadeTransition(
    opacity: Tween<double>(begin: 0, end: 1).animate(enter),
    child: FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.86).animate(leave),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.045, 0),
          end: Offset.zero,
        ).animate(enter),
        child: child,
      ),
    ),
  );
}

final PageTransitionsTheme appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const AppFadeSlidePageTransitionsBuilder(),
  },
);

class AppFadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppFadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return appFadeSlideTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

CustomTransitionPage<void> fadeSlidePage({
  required GoRouterState state,
  required Widget child,
  Duration duration = kAppPageTransitionDuration,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name ?? state.uri.toString(),
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: kAppPageReverseDuration,
    transitionsBuilder: appFadeSlideTransition,
  );
}

GoRoute fadeGoRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  List<RouteBase> routes = const [],
  String? Function(BuildContext context, GoRouterState state)? redirect,
  Duration duration = kAppPageTransitionDuration,
}) {
  return GoRoute(
    path: path,
    redirect: redirect,
    routes: routes,
    pageBuilder: (context, state) => fadeSlidePage(
      state: state,
      child: builder(context, state),
      duration: duration,
    ),
  );
}

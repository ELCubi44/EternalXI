import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:flutter/material.dart';

/// Expone [LeagueDetail], ids y recarga a las pestañas de la shell.
class LeagueShellData extends InheritedWidget {
  const LeagueShellData({
    super.key,
    required this.leagueId,
    required this.idUsuario,
    required this.detail,
    required this.isRefreshing,
    required this.reload,
    required this.selectTab,
    required this.currentTabIndex,
    required this.registerLineupLeaveGuard,
    required this.confirmLeaveLineupIfNeeded,
    required super.child,
  });

  final int leagueId;
  final int idUsuario;
  final LeagueDetail? detail;
  final bool isRefreshing;
  final Future<void> Function() reload;
  final void Function(int tabIndex) selectTab;
  final int currentTabIndex;
  final void Function(Future<bool> Function()? guard) registerLineupLeaveGuard;
  final Future<bool> Function() confirmLeaveLineupIfNeeded;

  static LeagueShellData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LeagueShellData>();
    assert(scope != null, 'LeagueShellData no encontrado en el árbol');
    return scope!;
  }

  static LeagueShellData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LeagueShellData>();
  }

  @override
  bool updateShouldNotify(LeagueShellData oldWidget) {
    return detail != oldWidget.detail ||
        isRefreshing != oldWidget.isRefreshing ||
        leagueId != oldWidget.leagueId ||
        idUsuario != oldWidget.idUsuario ||
        currentTabIndex != oldWidget.currentTabIndex;
  }
}

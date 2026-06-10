import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/screens/league_market_history_screen.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_home.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_market.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_settings.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_squad.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_standings.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/features/leagues/controller/league_notifications_controller.dart';
import 'package:eternal_xi/features/leagues/widgets/league_notifications_panel.dart';
import 'package:eternal_xi/core/notifications/push_notification_handler.dart';
import 'package:eternal_xi/features/leagues/widgets/league_shell_budget_bar.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/shared/widgets/user_tokens_action.dart';
import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Shell principal de una liga: detalle en memoria y 5 pestañas a pantalla completa con [NavigationBar] M3.
class LeagueShellScreen extends StatefulWidget {
  const LeagueShellScreen({super.key, required this.leagueId, this.idUsuario});

  /// Identificador de liga en la ruta.
  final int leagueId;

  /// Si se omite, se usa [AuthController.currentUser]. Puede forzarse vía query `?idUsuario=`.
  final int? idUsuario;

  @override
  State<LeagueShellScreen> createState() => _LeagueShellScreenState();
}

class _LeagueShellScreenState extends State<LeagueShellScreen> {
  LeagueDetail? _detail;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  int _tabIndex = 0;
  int? _rewardPoints;
  LeagueNotificationsController? _notificationsController;
  int _refreshGeneration = 0;
  Future<bool> Function()? _lineupLeaveGuard;

  bool _showsBudgetAndNotifications(int tabIndex) =>
      tabIndex == 0 || tabIndex == 1 || tabIndex == 3;

  void _registerLineupLeaveGuard(Future<bool> Function()? guard) {
    _lineupLeaveGuard = guard;
  }

  Future<bool> _confirmLeaveLineupIfNeeded() async {
    if (_lineupLeaveGuard == null) {
      return true;
    }
    return _lineupLeaveGuard!();
  }

  Future<void> _leaveLeague() async {
    if (_tabIndex == 2) {
      final leave = await _confirmLeaveLineupIfNeeded();
      if (!leave || !mounted) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    // Siempre ir a la lista de ligas: context.pop() deja pantalla negra en
    // varios flujos (atrás del sistema, crear/unirse liga, push desde FCM).
    context.go(AppRoutes.leagues);
  }

  Future<void> _selectTab(int index) async {
    if (index < 0 || index > 4 || index == _tabIndex) {
      return;
    }
    if (_tabIndex == 2 && index != 2) {
      final leave = await _confirmLeaveLineupIfNeeded();
      if (!leave) {
        return;
      }
    }
    setState(() => _tabIndex = index);
    if (index == 2 && !_refreshing) {
      _reload();
    }
  }

  int? _effectiveIdUsuario() {
    final fromParam = widget.idUsuario;
    if (fromParam != null && fromParam > 0) {
      return fromParam;
    }
    final u = context.read<AuthController>().currentUser?.id;
    if (u != null && u > 0) {
      return u;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _initNotifications();
    });
  }

  void _initNotifications() {
    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null || widget.leagueId <= 0) {
      return;
    }
    _notificationsController?.dispose();
    final controller = LeagueNotificationsController(
      userApiService: context.read<UserApiService>(),
      idUsuario: idUsuario,
      idLiga: widget.leagueId,
    );
    controller.addListener(_onNotificationsChanged);
    _notificationsController = controller;
    PushNotificationHandler.instance.onForegroundMessage =
        controller.refreshUnreadCount;
    controller.refreshUnreadCount();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _notificationsController?.removeListener(_onNotificationsChanged);
    if (PushNotificationHandler.instance.onForegroundMessage ==
        _notificationsController?.refreshUnreadCount) {
      PushNotificationHandler.instance.onForegroundMessage = null;
    }
    _notificationsController?.dispose();
    super.dispose();
  }

  Future<void> _openNotifications() async {
    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null) {
      return;
    }
    await LeagueNotificationsPanel.show(
      context,
      leagueId: widget.leagueId,
      idUsuario: idUsuario,
    );
    await _notificationsController?.refreshUnreadCount();
    if (_notificationsController != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    if (widget.leagueId <= 0) {
      setState(() {
        _loading = false;
        _error = context.l10n.leagueInvalidId;
      });
      return;
    }

    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null) {
      setState(() {
        _loading = false;
        _error = context.leagueL10n.noSessionWithRoute;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final d = await api.getLeagueDetail(
        idLiga: widget.leagueId,
        idUsuario: idUsuario,
      );
      if (mounted) {
        setState(() {
          _detail = d;
          _loading = false;
        });
      }
      _loadRewardPoints(idUsuario);
    } catch (e) {
      if (mounted) {
        setState(() {
          _detail = null;
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadRewardPoints(int idUsuario) async {
    try {
      final rewardsApi = context.read<RewardsApiService>();
      final summary = await rewardsApi.getSummary(
        idLiga: widget.leagueId,
        idUsuario: idUsuario,
      );
      if (mounted) {
        setState(() => _rewardPoints = summary.puntosRecompensaUsuario);
      }
    } catch (_) {}
  }

  Future<void> _reload() async {
    if (widget.leagueId <= 0) {
      return;
    }
    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null) {
      return;
    }

    setState(() => _refreshing = true);
    try {
      final api = context.read<LeaguesApiService>();
      final d = await api.getLeagueDetail(
        idLiga: widget.leagueId,
        idUsuario: idUsuario,
      );
      if (mounted) {
        setState(() {
          _detail = d;
          _refreshGeneration++;
        });
      }
      await Future.wait([
        _loadRewardPoints(idUsuario),
        _notificationsController?.refreshUnreadCount() ?? Future.value(),
      ]);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _openMarketHistory() async {
    if (_tabIndex == 2) {
      final leave = await _confirmLeaveLineupIfNeeded();
      if (!leave || !mounted) {
        return;
      }
    }
    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null || widget.leagueId <= 0) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LeagueMarketHistoryScreen(
          leagueId: widget.leagueId,
          userId: idUsuario,
          leagueName: _detail?.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final idUsuario = _effectiveIdUsuario() ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _leaveLeague();
      },
      child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _leaveLeague),
        title: Text(_detail?.nombre ?? l10n.league),
        actions: [
          if (_rewardPoints != null)
            LeagueRewardPointsAction(
              idLiga: widget.leagueId,
              puntos: _rewardPoints!,
            )
          else
            const UserTokensAction(),
          if (_detail != null && !_loading)
            IconButton(
              tooltip: l10n.update,
              onPressed: _refreshing ? null : _reload,
              icon: _refreshing
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _detail == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(_error!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            )
          : _detail == null
          ? const SizedBox.shrink()
          : LeagueShellData(
              leagueId: widget.leagueId,
              idUsuario: idUsuario,
              detail: _detail,
              isRefreshing: _refreshing,
              refreshGeneration: _refreshGeneration,
              reload: _reload,
              selectTab: _selectTab,
              currentTabIndex: _tabIndex,
              registerLineupLeaveGuard: _registerLineupLeaveGuard,
              confirmLeaveLineupIfNeeded: _confirmLeaveLineupIfNeeded,
              child: SafeArea(
                left: true,
                right: true,
                top: false,
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showsBudgetAndNotifications(_tabIndex))
                      LeagueShellBudgetBar(
                        miDinero: _detail!.miDinero,
                        onOpenHistory: _openMarketHistory,
                        onOpenNotifications: _openNotifications,
                        unreadNotifications:
                            _notificationsController?.unreadCount ?? 0,
                      ),
                    if (_refreshing)
                      LinearProgressIndicator(
                        minHeight: 2,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _tabIndex,
                        children: const [
                          LeagueTabHome(),
                          LeagueTabStandings(),
                          LeagueTabSquad(),
                          LeagueTabMarket(),
                          LeagueTabSettings(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _detail == null || _loading
          ? null
          : NavigationBar(
              selectedIndex: _tabIndex,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (index) {
                _selectTab(index);
              },
              destinations: [
                NavigationDestination(
                  icon: const XiIcon(XiIconType.stadium),
                  selectedIcon: const XiIcon(XiIconType.stadium, color: XiColors.techCyan, filled: true),
                  label: l10n.home,
                ),
                NavigationDestination(
                  icon: const XiIcon(XiIconType.podium),
                  selectedIcon: const XiIcon(XiIconType.podium, color: XiColors.techCyan, filled: true),
                  label: l10n.standings,
                ),
                NavigationDestination(
                  icon: const XiIcon(XiIconType.tacticalBoard),
                  selectedIcon: const XiIcon(XiIconType.tacticalBoard, color: XiColors.techCyan, filled: true),
                  label: l10n.squad,
                ),
                NavigationDestination(
                  icon: const XiIcon(XiIconType.transfer),
                  selectedIcon: const XiIcon(XiIconType.transfer, color: XiColors.techCyan, filled: true),
                  label: l10n.market,
                ),
                NavigationDestination(
                  icon: const XiIcon(XiIconType.leagueSettings),
                  selectedIcon: const XiIcon(XiIconType.leagueSettings, color: XiColors.techCyan, filled: true),
                  label: l10n.settings,
                ),
              ],
            ),
      ),
    );
  }
}

import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/notifications/push_notification_handler.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/controller/league_notifications_controller.dart';
import 'package:eternal_xi/features/leagues/screens/league_market_history_screen.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_tabs.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_chat.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_home.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_market.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_settings.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_squad.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_standings.dart';
import 'package:eternal_xi/features/leagues/widgets/league_notifications_panel.dart';
import 'package:eternal_xi/features/leagues/widgets/league_shell_budget_bar.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/shared/widgets/league_settings_icon.dart';
import 'package:eternal_xi/shared/widgets/notification_bell_icon.dart';
import 'package:eternal_xi/shared/widgets/user_tokens_action.dart';
import 'package:eternal_xi/shared/widgets/xi_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LeagueShellScreen extends StatefulWidget {
  const LeagueShellScreen({super.key, required this.leagueId, this.idUsuario});

  final int leagueId;
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

  bool _showsBudgetBar(int tabIndex) =>
      tabIndex == LeagueShellTabs.market;

  void _registerLineupLeaveGuard(Future<bool> Function()? guard) {
    _lineupLeaveGuard = guard;
  }

  Future<bool> _confirmLeaveLineupIfNeeded() async {
    if (_lineupLeaveGuard == null) return true;
    return _lineupLeaveGuard!();
  }

  Future<void> _leaveLeague() async {
    if (!mounted) return;
    context.go(AppRoutes.leagues);
  }

  Future<void> _selectTab(int index) async {
    if (index < 0 ||
        index >= LeagueShellTabs.count ||
        index == _tabIndex) {
      return;
    }
    if (_tabIndex == LeagueShellTabs.squad &&
        index != LeagueShellTabs.squad) {
      final leave = await _confirmLeaveLineupIfNeeded();
      if (!leave) return;
    }
    setState(() => _tabIndex = index);
    if (index == LeagueShellTabs.market && !_refreshing) {
      _reload();
    }
  }

  void _openSquad({int segment = 0}) {
    LeagueTabSquad.externalSegmentRequest.value = segment;
    _selectTab(LeagueShellTabs.squad);
  }

  Future<void> _openSettings() async {
    if (_tabIndex == LeagueShellTabs.squad) {
      final leave = await _confirmLeaveLineupIfNeeded();
      if (!leave || !mounted) return;
    }
    final idUsuario = _effectiveIdUsuario() ?? 0;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (routeContext) => LeagueShellData(
          leagueId: widget.leagueId,
          idUsuario: idUsuario,
          detail: _detail,
          isRefreshing: _refreshing,
          refreshGeneration: _refreshGeneration,
          reload: _reload,
          selectTab: _selectTab,
          currentTabIndex: _tabIndex,
          openSquad: _openSquad,
          registerLineupLeaveGuard: _registerLineupLeaveGuard,
          confirmLeaveLineupIfNeeded: _confirmLeaveLineupIfNeeded,
          child: Scaffold(
            backgroundColor: routeContext.xiBackground,
            body: Column(
              children: [
                _XiSettingsOverlayHeader(
                  onBack: () => Navigator.of(routeContext).pop(),
                ),
                const Expanded(child: LeagueTabSettings()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _effectiveIdUsuario() {
    final fromParam = widget.idUsuario;
    if (fromParam != null && fromParam > 0) return fromParam;
    final u = context.read<AuthController>().currentUser?.id;
    if (u != null && u > 0) return u;
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
    if (idUsuario == null || widget.leagueId <= 0) return;
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
    if (mounted) setState(() {});
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
    if (idUsuario == null) return;
    await LeagueNotificationsPanel.show(
      context,
      leagueId: widget.leagueId,
      idUsuario: idUsuario,
    );
    await _notificationsController?.refreshUnreadCount();
    if (_notificationsController != null && mounted) setState(() {});
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
    if (widget.leagueId <= 0) return;
    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null) return;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openMarketHistory() async {
    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null || widget.leagueId <= 0) return;
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
    final idUsuario = _effectiveIdUsuario() ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveLeague();
      },
      child: Scaffold(
        backgroundColor: context.xiBackground,
        body: Column(
          children: [
            // ── Custom header ────────────────────────────────────────────
            _XiLeagueHeader(
              leagueName: _detail?.nombre ?? l10n.league,
              rewardPoints: _rewardPoints,
              leagueId: widget.leagueId,
              unreadCount: _notificationsController?.unreadCount ?? 0,
              onBack: _leaveLeague,
              onSettings: _openSettings,
              onNotifications: _openNotifications,
            ),
            // ── Budget bar + refresh indicator ───────────────────────────
            if (_detail != null && _showsBudgetBar(_tabIndex))
              LeagueShellBudgetBar(
                miDinero: _detail!.miDinero,
                onOpenHistory: _openMarketHistory,
              ),
            if (_refreshing)
              LinearProgressIndicator(
                minHeight: 2,
                color: XiColors.royalBlue,
                backgroundColor: context.xiSurfaceContainer,
              ),
            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const _XiLoadingState()
                  : _error != null && _detail == null
                  ? _XiErrorState(
                      message: _error!,
                      onRetry: _load,
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
                      openSquad: _openSquad,
                      registerLineupLeaveGuard: _registerLineupLeaveGuard,
                      confirmLeaveLineupIfNeeded: _confirmLeaveLineupIfNeeded,
                      child: SafeArea(
                        left: true,
                        right: true,
                        top: false,
                        bottom: false,
                        child: IndexedStack(
                          index: _tabIndex,
                          children: const [
                            LeagueTabHome(),
                            LeagueTabStandings(),
                            LeagueTabSquad(),
                            LeagueTabMarket(),
                            LeagueTabChat(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: _detail == null || _loading
            ? null
            : XiBottomNav(
                selectedIndex: _tabIndex,
                onItemSelected: _selectTab,
                items: [
                  XiBottomNavItem(
                    assetIcon: 'assets/app/nav_league_home.png',
                    label: l10n.home,
                  ),
                  XiBottomNavItem(
                    assetIcon: 'assets/app/nav_league_standings.png',
                    label: l10n.standings,
                  ),
                  XiBottomNavItem(
                    assetIcon: 'assets/app/nav_league_lineup.png',
                    label: l10n.squad,
                  ),
                  XiBottomNavItem(
                    assetIcon: 'assets/app/nav_league_market.png',
                    label: l10n.market,
                  ),
                  XiBottomNavItem(
                    assetIcon: 'assets/app/nav_league_chat.png',
                    label: l10n.chat,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Custom header ─────────────────────────────────────────────────────────────

class _XiLeagueHeader extends StatelessWidget {
  const _XiLeagueHeader({
    required this.leagueName,
    required this.rewardPoints,
    required this.leagueId,
    required this.unreadCount,
    required this.onBack,
    required this.onSettings,
    required this.onNotifications,
  });

  final String leagueName;
  final int? rewardPoints;
  final int leagueId;
  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.xiHeaderGradient,
        ),
        border: Border(
          bottom: BorderSide(color: context.xiNavBorder, width: 1),
        ),
      ),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            _HeaderBtn(
              onTap: onBack,
              child: XiIcon(
                XiIconType.backArrow,
                size: 22,
                color: context.xiTextPrimary,
              ),
            ),
            Expanded(
              child: Text(
                leagueName.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.xiHeaderTitle,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            LeagueRewardPointsAction(
              idLiga: leagueId,
              puntos: rewardPoints ?? 0,
            ),
            _HeaderNotificationBtn(
              unreadCount: unreadCount,
              onTap: onNotifications,
            ),
            _HeaderBtn(
              onTap: onSettings,
              child: const LeagueSettingsIcon(size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderNotificationBtn extends StatelessWidget {
  const _HeaderNotificationBtn({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HeaderBtn(
      onTap: onTap,
      child: NotificationBellIcon(
        size: 28,
        unreadCount: unreadCount,
      ),
    );
  }
}

class _XiSettingsOverlayHeader extends StatelessWidget {
  const _XiSettingsOverlayHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.xiHeaderGradient,
        ),
        border: Border(
          bottom: BorderSide(color: context.xiNavBorder, width: 1),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            _HeaderBtn(
              onTap: onBack,
              child: XiIcon(
                XiIconType.backArrow,
                size: 22,
                color: context.xiTextPrimary,
              ),
            ),
            Expanded(
              child: Text(
                context.l10n.settings.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.xiHeaderTitle,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 46),
          ],
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HeaderBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 46,
        height: 54,
        child: Center(child: child),
      ),
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _XiLoadingState extends StatelessWidget {
  const _XiLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: XiColors.royalBlue),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _XiErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _XiErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 52,
          color: XiColors.heroRed,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            fontSize: 14,
            color: XiColors.warmWhite,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F62D8), XiColors.royalBlue],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              context.l10n.retry.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: XiColors.warmWhite,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

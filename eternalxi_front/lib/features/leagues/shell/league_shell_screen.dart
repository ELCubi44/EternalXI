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
import 'package:eternal_xi/features/leagues/widgets/league_shell_budget_bar.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/shared/widgets/user_tokens_action.dart';
import 'package:flutter/material.dart';
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

  void _selectTab(int index) {
    if (index < 0 || index > 4 || index == _tabIndex) {
      return;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.leagueId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Identificador de liga no válido.';
      });
      return;
    }

    final idUsuario = _effectiveIdUsuario();
    if (idUsuario == null) {
      setState(() {
        _loading = false;
        _error =
            'No hay usuario en sesión. Inicia sesión o pasa idUsuario en la ruta.';
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
        setState(() => _detail = d);
      }
      _loadRewardPoints(idUsuario);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final idUsuario = _effectiveIdUsuario() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.nombre ?? 'Liga'),
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
              tooltip: 'Actualizar',
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
                  label: const Text('Reintentar'),
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
              reload: _reload,
              selectTab: _selectTab,
              currentTabIndex: _tabIndex,
              child: SafeArea(
                left: true,
                right: true,
                top: false,
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LeagueShellBudgetBar(
                      miDinero: _detail!.miDinero,
                      onOpenHistory: _openMarketHistory,
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.format_list_numbered_outlined),
                  selectedIcon: Icon(Icons.leaderboard_rounded),
                  label: 'Tabla',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_soccer_outlined),
                  selectedIcon: Icon(Icons.sports_soccer),
                  label: 'Equipo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Mercado',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
    );
  }
}

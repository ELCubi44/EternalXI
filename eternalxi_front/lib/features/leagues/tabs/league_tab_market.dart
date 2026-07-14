import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/league_listed_player.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/models/league_market_team_summary.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/controller/league_night_market_controller.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_market_sort.dart';
import 'package:eternal_xi/features/leagues/utils/league_shell_money_refresh.dart';
import 'package:eternal_xi/features/leagues/widgets/league_market_player_buy_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_night_market_item_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_night_market_summary_header.dart';
import 'package:eternal_xi/features/leagues/widgets/league_sent_offer_item_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueTabMarket extends StatefulWidget {
  const LeagueTabMarket({super.key});

  static final ValueNotifier<int?> externalSegmentRequest = ValueNotifier<int?>(
    null,
  );

  @override
  State<LeagueTabMarket> createState() => _LeagueTabMarketState();
}

class _LeagueTabMarketState extends State<LeagueTabMarket>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return Center(
        child: Text(
          context.l10n.leagueContextError,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            fontSize: 13,
            color: XiColors.steelGray,
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      key: ValueKey<String>('${shell.leagueId}_${shell.idUsuario}'),
      create: (context) => LeagueNightMarketController(
        leaguesApiService: context.read<LeaguesApiService>(),
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      )..load(),
      child: _LeagueMarketView(shell: shell),
    );
  }
}

class _LeagueMarketView extends StatefulWidget {
  const _LeagueMarketView({required this.shell});

  final LeagueShellData shell;

  @override
  State<_LeagueMarketView> createState() => _LeagueMarketViewState();
}

class _LeagueMarketViewState extends State<_LeagueMarketView> {
  int _segment = 0;
  int? _handledRefreshGeneration;

  bool _buyLoading = true;
  String? _buyError;
  List<LeagueMarketTeamSummary>? _buyTeams;
  List<LeagueOfferItem> _pendingSentOffers = const [];

  void _handleExternalSegmentRequest() {
    final request = LeagueTabMarket.externalSegmentRequest.value;
    if (!mounted || request == null) {
      return;
    }
    LeagueTabMarket.externalSegmentRequest.value = null;
    if (request < 0 || request > 2) {
      return;
    }
    if (_segment != request) {
      setState(() => _segment = request);
    }
  }

  @override
  void initState() {
    super.initState();
    LeagueTabMarket.externalSegmentRequest.addListener(
      _handleExternalSegmentRequest,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuyMarket());
  }

  @override
  void dispose() {
    LeagueTabMarket.externalSegmentRequest.removeListener(
      _handleExternalSegmentRequest,
    );
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) return;
    final gen = shell.refreshGeneration;
    if (_handledRefreshGeneration == null) {
      _handledRefreshGeneration = gen;
      return;
    }
    if (gen != _handledRefreshGeneration) {
      _handledRefreshGeneration = gen;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _reloadMarketTabData();
      });
    }
  }

  Future<void> _reloadMarketTabData() async {
    await context.read<LeagueNightMarketController>().refresh();
    await _loadBuyMarket();
  }

  Future<void> _loadBuyMarket() async {
    setState(() {
      _buyLoading = true;
      _buyError = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final results = await Future.wait([
        api.getLeagueMarketPlayers(
          idLiga: widget.shell.leagueId,
          idUsuario: widget.shell.idUsuario,
        ),
        api.getSentOffers(
          idLiga: widget.shell.leagueId,
          idUsuario: widget.shell.idUsuario,
        ),
      ]);
      if (!mounted) return;
      final rows = results[0] as List<LeagueSquadPlayer>;
      final sentOffers = results[1] as List<LeagueOfferItem>;
      final flat = rows
          .map((LeagueSquadPlayer r) => LeagueListedPlayer(squadPlayer: r))
          .toList();
      setState(() {
        _buyTeams = buildLeagueMarketTeamSummaries(flat);
        _pendingSentOffers =
            sentOffers.where((LeagueOfferItem o) => o.pendiente).toList();
        if (_pendingSentOffers.isEmpty && _segment == 2) {
          _segment = 1;
        }
        _buyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buyError = e.toString().replaceFirst('Exception: ', '');
        _buyLoading = false;
      });
    }
  }

  Future<void> _refreshAll(BuildContext context) async {
    await reloadLeagueShellAfterMoney(context);
  }

  List<Widget> _buildNightMarketSlivers(
    BuildContext context,
    LeagueNightMarketController controller,
  ) {
    if (controller.isLoading && controller.data == null) {
      return const [
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(color: XiColors.royalBlue)),
        ),
      ];
    }
    if (controller.errorMessage != null && controller.data == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 56, color: XiColors.heroRed),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 13,
                    color: XiColors.steelGray.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                _XiRetryButton(onTap: () => controller.load()),
              ],
            ),
          ),
        ),
      ];
    }
    if (controller.data == null) return const [];

    return [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        sliver: SliverToBoxAdapter(child: LeagueNightMarketSummaryHeader()),
      ),
      if (controller.data!.items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              context.leagueL10n.noPlayersToday,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 14,
                color: XiColors.steelGray.withValues(alpha: 0.7),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = controller.data!.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: LeagueNightMarketItemCard(
                  item: item,
                  market: controller.data!,
                  controller: controller,
                  onAfterMarketAction: () => _refreshAll(context),
                ),
              );
            }, childCount: controller.data!.items.length),
          ),
        ),
    ];
  }

  List<Widget> _buildBuySlivers() {
    if (_buyLoading) {
      return const [
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(color: XiColors.royalBlue)),
        ),
      ];
    }
    if (_buyError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _XiErrorState(
            message: _buyError!,
            onRetry: _loadBuyMarket,
          ),
        ),
      ];
    }
    final teams = _buyTeams ?? const <LeagueMarketTeamSummary>[];
    if (teams.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              context.leagueL10n.noPlayersAvailableYet,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 14,
                color: XiColors.steelGray.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, ti) {
            final team = teams[ti];
            final sorted = [...team.players]
              ..sort(compareLeagueListedPlayersMarketOrder);
            return Padding(
              padding: EdgeInsets.only(bottom: ti < teams.length - 1 ? 10 : 0),
              child: _TeamExpandCard(
                team: team,
                sorted: sorted,
                leagueId: widget.shell.leagueId,
                idUsuario: widget.shell.idUsuario,
                onAfterAction: _loadBuyMarket,
              ),
            );
          }, childCount: teams.length),
        ),
      ),
    ];
  }

  List<Widget> _buildSentOffersSlivers() {
    if (_buyLoading) {
      return const [
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(color: XiColors.royalBlue)),
        ),
      ];
    }
    if (_buyError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _XiErrorState(message: _buyError!, onRetry: _loadBuyMarket),
        ),
      ];
    }
    if (_pendingSentOffers.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              context.leagueL10n.noOffersPendingSnack,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 14,
                color: context.xiTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final offer = _pendingSentOffers[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _pendingSentOffers.length - 1 ? 14 : 0,
              ),
              child: LeagueSentOfferItemCard(
                offer: offer,
                idLiga: widget.shell.leagueId,
                idUsuario: widget.shell.idUsuario,
                onAfterAction: _loadBuyMarket,
              ),
            );
          }, childCount: _pendingSentOffers.length),
        ),
      ),
    ];
  }

  List<_XiTabDef> _marketTabs() {
    final l10n = context.l10n;
    final ll = context.leagueL10n;
    final tabs = <_XiTabDef>[
      _XiTabDef(
        label: l10n.market,
        icon: Icons.nights_stay_outlined,
        color: XiColors.accentViolet,
      ),
      _XiTabDef(
        label: ll.buy,
        icon: Icons.shopping_bag_outlined,
        color: XiColors.royalBlue,
      ),
    ];
    if (_pendingSentOffers.isNotEmpty) {
      tabs.add(_XiTabDef(
        label: ll.offersCount(_pendingSentOffers.length),
        icon: Icons.local_offer_outlined,
        color: XiColors.classicGold,
      ));
    }
    return tabs;
  }

  List<Widget> _segmentSlivers(
    BuildContext context,
    LeagueNightMarketController nightController,
  ) {
    switch (_segment) {
      case 0:
        return _buildNightMarketSlivers(context, nightController);
      case 2:
        return _buildSentOffersSlivers();
      case 1:
      default:
        return _buildBuySlivers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nightController = context.watch<LeagueNightMarketController>();
    final tabs = _marketTabs();
    final safeSegment = _segment.clamp(0, tabs.length - 1);

    return Stack(
      children: [
        RefreshIndicator(
          color: XiColors.royalBlue,
          backgroundColor: context.xiCardElevated,
          onRefresh: () => _refreshAll(context),
          child: CustomScrollView(
            key: const PageStorageKey<String>('league_tab_market'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _XiTabSelector(
                    tabs: tabs,
                    selected: safeSegment,
                    onSelect: (i) => setState(() => _segment = i),
                  ),
                ),
              ),
              ..._segmentSlivers(context, nightController),
            ],
          ),
        ),
        if (nightController.isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: XiColors.royalBlue,
              backgroundColor: XiColors.royalBlue.withValues(alpha: 0.1),
            ),
          ),
      ],
    );
  }
}

// ─── Custom tab selector ──────────────────────────────────────────────────────

class _XiTabDef {
  const _XiTabDef({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;
}

class _XiTabSelector extends StatelessWidget {
  const _XiTabSelector({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<_XiTabDef> tabs;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.xiSurfaceContainer,
        border: Border.all(color: context.xiBorderSubtle),
        boxShadow: context.xiCardShadow,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? tab.color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: tab.color.withValues(alpha: 0.4))
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: tab.color.withValues(alpha: 0.2), blurRadius: 10)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 15,
                      color: isSelected ? tab.color : context.xiTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: isSelected ? tab.color : context.xiTextSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Team expand card (replaces Card + ExpansionTile) ─────────────────────────

class _TeamExpandCard extends StatefulWidget {
  const _TeamExpandCard({
    required this.team,
    required this.sorted,
    required this.leagueId,
    required this.idUsuario,
    required this.onAfterAction,
  });

  final LeagueMarketTeamSummary team;
  final List<LeagueListedPlayer> sorted;
  final int leagueId;
  final int idUsuario;
  final Future<void> Function() onAfterAction;

  @override
  State<_TeamExpandCard> createState() => _TeamExpandCardState();
}

class _TeamExpandCardState extends State<_TeamExpandCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _rotCtrl.forward();
    } else {
      _rotCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.xiCompactCardGradient,
        ),
        border: Border.all(color: context.xiBorderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    LeagueTeamLogo(
                      idEquipo: widget.team.idEquipo,
                      size: 38,
                      networkImageUrl: widget.team.resolvedTeamBadgeUrl(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.team.nombreEquipo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 14,
                              color: context.xiTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ll.playersCount(widget.team.players.length),
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 10,
                              color: XiColors.royalBlue.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(
                        CurvedAnimation(parent: _rotCtrl, curve: Curves.easeOut),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: XiColors.steelGray,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable player list
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: [
                          for (final listed in widget.sorted)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LeagueMarketPlayerBuyCard(
                                player: listed.squadPlayer,
                                idLiga: widget.leagueId,
                                idUsuario: widget.idUsuario,
                                onAfterAction: widget.onAfterAction,
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _XiErrorState extends StatelessWidget {
  const _XiErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 52, color: XiColors.heroRed),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 12,
              color: XiColors.steelGray.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _XiRetryButton(onTap: onRetry),
        ],
      ),
    );
  }
}

class _XiRetryButton extends StatelessWidget {
  const _XiRetryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [XiColors.royalBlue, XiColors.royalBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: XiColors.royalBlue.withValues(alpha: 0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 16, color: XiColors.warmWhite),
            const SizedBox(width: 6),
            Text(
              context.l10n.retry,
              style: const TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 13,
                color: XiColors.warmWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

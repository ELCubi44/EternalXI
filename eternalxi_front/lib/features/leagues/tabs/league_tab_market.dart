import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_listed_player.dart';
import 'package:eternal_xi/data/models/league_market_team_summary.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/controller/league_night_market_controller.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_market_sort.dart';
import 'package:eternal_xi/features/leagues/widgets/league_market_player_buy_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_night_market_item_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_night_market_summary_header.dart';
import 'package:eternal_xi/features/leagues/widgets/league_sent_offer_item_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueTabMarket extends StatefulWidget {
  const LeagueTabMarket({super.key});

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
      return Center(child: Text(context.l10n.leagueContextError));
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
  Object? _lastShellDetailRef;

  bool _buyLoading = true;
  String? _buyError;
  List<LeagueMarketTeamSummary>? _buyTeams;
  List<LeagueOfferItem> _pendingSentOffers = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuyMarket());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final detailRef = widget.shell.detail;
    if (_lastShellDetailRef == null) {
      _lastShellDetailRef = detailRef;
      return;
    }
    if (!identical(_lastShellDetailRef, detailRef)) {
      _lastShellDetailRef = detailRef;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await context.read<LeagueNightMarketController>().refresh();
        await _loadBuyMarket();
      });
    }
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
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      setState(() {
        _buyError = e.toString().replaceFirst('Exception: ', '');
        _buyLoading = false;
      });
    }
  }

  Future<void> _refreshAll(BuildContext context) async {
    final marketErr = await context
        .read<LeagueNightMarketController>()
        .refresh();
    await _loadBuyMarket();
    await widget.shell.reload();
    if (marketErr != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(marketErr)));
    }
  }

  List<Widget> _buildNightMarketSlivers(
    BuildContext context,
    LeagueNightMarketController controller,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (controller.isLoading && controller.data == null) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
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
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () => controller.load(),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (controller.data == null) {
      return const [];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        sliver: SliverToBoxAdapter(
          child: const LeagueNightMarketSummaryHeader(),
        ),
      ),
      if (controller.data!.items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              context.leagueL10n.noPlayersToday,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
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

  List<Widget> _buildBuySlivers(ThemeData theme, ColorScheme colorScheme) {
    if (_buyLoading) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (_buyError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _buyError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: _loadBuyMarket,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey<String>(
                      'buy_team_${widget.shell.leagueId}_${team.idEquipo}',
                    ),
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    leading: LeagueTeamLogo(
                      idEquipo: team.idEquipo,
                      size: 40,
                      networkImageUrl: team.resolvedTeamBadgeUrl(),
                    ),
                    title: Text(
                      team.nombreEquipo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      context.leagueL10n.playersCount(team.players.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      for (final listed in sorted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LeagueMarketPlayerBuyCard(
                            player: listed.squadPlayer,
                            idLiga: widget.shell.leagueId,
                            idUsuario: widget.shell.idUsuario,
                            onAfterAction: _loadBuyMarket,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: teams.length),
        ),
      ),
    ];
  }

  List<Widget> _buildSentOffersSlivers(ThemeData theme, ColorScheme colorScheme) {
    if (_buyLoading) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (_buyError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _buyError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: _loadBuyMarket,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
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

  List<ButtonSegment<int>> _marketSegments() {
    final ll = context.leagueL10n;
    final segments = <ButtonSegment<int>>[
      ButtonSegment<int>(
        value: 0,
        label: Text(context.l10n.market),
        icon: const Icon(Icons.nights_stay_outlined),
      ),
      ButtonSegment<int>(
        value: 1,
        label: Text(context.leagueL10n.buy),
        icon: const Icon(Icons.shopping_bag_outlined),
      ),
    ];
    if (_pendingSentOffers.isNotEmpty) {
      segments.add(
        ButtonSegment<int>(
          value: 2,
          label: Text(ll.offersCount(_pendingSentOffers.length)),
          icon: const Icon(Icons.local_offer_outlined),
        ),
      );
    }
    return segments;
  }

  List<Widget> _segmentSlivers(
    BuildContext context,
    LeagueNightMarketController nightController,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (_segment) {
      case 0:
        return _buildNightMarketSlivers(
          context,
          nightController,
          theme,
          colorScheme,
        );
      case 2:
        return _buildSentOffersSlivers(theme, colorScheme);
      case 1:
      default:
        return _buildBuySlivers(theme, colorScheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nightController = context.watch<LeagueNightMarketController>();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refreshAll(context),
          child: CustomScrollView(
            key: const PageStorageKey<String>('league_tab_market'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: SegmentedButton<int>(
                    segments: _marketSegments(),
                    selected: {_segment},
                    onSelectionChanged: (selection) {
                      setState(() => _segment = selection.first);
                    },
                  ),
                ),
              ),
              ..._segmentSlivers(context, nightController, theme, colorScheme),
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
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}

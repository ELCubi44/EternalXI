import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/features/rewards/presentation/controllers/rewards_controller.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/coach_roulette_section.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/coach_roulette_strip.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_coach_detail_card.dart';
import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/features/leagues/utils/league_history_filters.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/league_activity_tile.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/pack_opening_animation_dialog.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_card_detail_sheet.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_card_grid.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_card_redeem_sheet.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_pack_card.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/rewards_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueRewardsScreen extends StatefulWidget {
  const LeagueRewardsScreen({
    super.key,
    required this.idLiga,
    required this.idUsuario,
    required this.leagueName,
  });

  final int idLiga;
  final int idUsuario;
  final String leagueName;

  @override
  State<LeagueRewardsScreen> createState() => _LeagueRewardsScreenState();
}

class _LeagueRewardsScreenState extends State<LeagueRewardsScreen>
    with TickerProviderStateMixin {
  TabController? _tabs;
  int _tabLen = 0;
  bool _packBusy = false;
  bool _spinBusy = false;
  String? _cardFilter;
  bool _initialLoadScheduled = false;

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  void _ensureTabs(bool showCartas) {
    final len = showCartas ? 4 : 3;
    if (_tabs != null && _tabLen == len) {
      return;
    }
    var initialIndex = 0;
    final previous = _tabs;
    if (previous != null) {
      final oldLen = _tabLen;
      final oldIndex = previous.index;
      if (len == 4 && oldLen == 3) {
        initialIndex = oldIndex >= 2 ? 3 : oldIndex;
      } else if (len == 3 && oldLen == 4) {
        initialIndex = oldIndex >= 3 ? 2 : oldIndex.clamp(0, 2);
      } else {
        initialIndex = oldIndex.clamp(0, len - 1);
      }
      previous.dispose();
    }
    _tabLen = len;
    _tabs = TabController(
      length: len,
      vsync: this,
      initialIndex: initialIndex.clamp(0, len - 1),
    );
  }

  int _cardsIndex() => 2;

  Future<void> _reloadAll(RewardsController c) async {
    await c.loadSummary();
    final s = c.summary;
    if (s?.showCartasTab == true) {
      await c.loadCards();
    }
    await c.loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RewardsController(
        rewardsApi: ctx.read<RewardsApiService>(),
        apiClient: ctx.read<ApiClient>(),
        leaguesApi: ctx.read<LeaguesApiService>(),
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
      ),
      child: Builder(
        builder: (context) {
          final c = context.watch<RewardsController>();
          if (!_initialLoadScheduled &&
              c.summary == null &&
              !c.loadingSummary &&
              c.errorMessage == null) {
            _initialLoadScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _reloadAll(context.read<RewardsController>());
            });
          }
          if (c.summary != null) {
            _ensureTabs(c.summary!.showCartasTab);
          }

          final s = c.summary;
          final showCartas = s?.showCartasTab ?? false;
          final rl10n = context.rewardsL10n;
          final colorScheme = Theme.of(context).colorScheme;
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(context.l10n.leagueRewards),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      rl10n.shopSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            body: c.loadingSummary && s == null
                ? const Center(child: CircularProgressIndicator())
                : c.errorMessage != null && s == null
                ? _ErrorBody(
                    message: c.errorMessage!,
                    onRetry: () => _reloadAll(context.read<RewardsController>()),
                  )
                : s == null || _tabs == null
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      Expanded(
                        child: NestedScrollView(
                          headerSliverBuilder: (context, inner) {
                            return [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    0,
                                  ),
                                  child: RewardsSummaryHeader(
                                    summary: s,
                                    leagueName: widget.leagueName,
                                  ),
                                ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _TabBarDelegate(
                                  TabBar(
                                    controller: _tabs,
                                    isScrollable: true,
                                    tabs: [
                                      Tab(text: rl10n.tabPacks),
                                      Tab(text: rl10n.tabCoach),
                                      if (showCartas) Tab(text: rl10n.tabCards),
                                      Tab(text: rl10n.tabHistory),
                                    ],
                                  ),
                                ),
                              ),
                            ];
                          },
                          body: TabBarView(
                            controller: _tabs,
                            children: [
                              _PacksTab(
                                summary: s,
                                busy: _packBusy,
                                onOpen: (packType) => _openPack(
                                  context,
                                  c,
                                  packType,
                                  showCartas,
                                ),
                              ),
                              ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  CoachRouletteSection(
                                    summary: s,
                                    busy: _spinBusy,
                                    onSpin: () => _spin(context, c),
                                  ),
                                ],
                              ),
                              if (showCartas)
                                _CardsTabBody(
                                  c: c,
                                  filter: _cardFilter,
                                  onFilter: (f) => setState(() => _cardFilter = f),
                                  onUse: (RewardCardModel card) =>
                                      openRewardCardRedeemSheet(
                                    context: context,
                                    rewards: c,
                                    card: card,
                                  ),
                                  onTap: (RewardCardModel card) async {
                                    final wantsUse =
                                        await showRewardCardDetailSheet(
                                      context: context,
                                      card: card,
                                    );
                                    if (wantsUse && card.isAvailable && context.mounted) {
                                      await openRewardCardRedeemSheet(
                                        context: context,
                                        rewards: c,
                                        card: card,
                                      );
                                    }
                                  },
                                ),
                              _ActivityTab(c: c),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _openPack(
    BuildContext context,
    RewardsController c,
    String packType,
    bool showCartas,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _packBusy = true);
    final res = await c.openPack(packType);
    if (!mounted) {
      return;
    }
    setState(() => _packBusy = false);
    if (res == null) {
      final msg = c.errorMessage ?? context.rewardsL10n.actionFailed;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showPackOpeningAnimationDialog(
      context: context,
      result: res,
      onViewCards: () {
        final show = c.summary?.showCartasTab ?? false;
        if (_tabs != null && show) {
          _tabs!.animateTo(_cardsIndex());
        }
      },
    );
    if (!context.mounted) {
      return;
    }
    await _reloadAll(c);
  }

  Future<void> _spin(BuildContext context, RewardsController c) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _spinBusy = true);
    final r = await c.spinCoachRoulette();
    if (!mounted) {
      return;
    }
    setState(() => _spinBusy = false);
    if (r == null) {
      final msg = c.errorMessage ?? context.rewardsL10n.actionFailed;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    if (r.alreadyUsed) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.rewardsL10n.rouletteAlreadyUsed)),
      );
      return;
    }
    final winner = r.entrenadorGanador;
    if (!context.mounted) {
      return;
    }
    if (winner != null) {
      await showCoachRouletteDialog(
        context: context,
        itemsRuleta: r.itemsRuleta,
        entrenadorGanador: winner,
      );
      if (!context.mounted) {
        return;
      }
      await showCoachWonSheet(context: context, coach: winner);
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _PacksTab extends StatelessWidget {
  const _PacksTab({
    required this.summary,
    required this.busy,
    required this.onOpen,
  });

  final RewardSummaryModel summary;
  final bool busy;
  final void Function(String packType) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final p in summary.sobres)
          RewardPackCard(
            pack: p,
            userPoints: summary.puntosRecompensaUsuario,
            busy: busy,
            onOpen: () => onOpen(p.packType),
          ),
      ],
    );
  }
}

class _CardsTabBody extends StatelessWidget {
  const _CardsTabBody({
    required this.c,
    required this.filter,
    required this.onFilter,
    required this.onUse,
    required this.onTap,
  });

  final RewardsController c;
  final String? filter;
  final ValueChanged<String?> onFilter;
  final void Function(RewardCardModel card) onUse;
  final void Function(RewardCardModel card) onTap;

  List<RewardCardModel> _filtered() {
    final list = c.cards;
    final f = filter;
    if (f == null || f == 'ALL') {
      return list;
    }
    return list.where((card) {
      final t = card.tipoEfecto.toUpperCase();
      switch (f) {
        case 'SELL':
          return t == 'SELL_PLAYER_BONUS';
        case 'CLAUSE':
          return t == 'DIRECT_CLAUSE';
        case 'PROT':
          return t == 'PROTECT_PLAYER';
        case 'PTS':
          return t == 'ADD_LEAGUE_POINTS';
        case 'VAL':
          return card.isValueBoost;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rl10n = context.rewardsL10n;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _FilterChip(
                label: rl10n.filterAll,
                selected: filter == null || filter == 'ALL',
                onTap: () => onFilter('ALL'),
              ),
              _FilterChip(
                label: rl10n.filterSell,
                selected: filter == 'SELL',
                onTap: () => onFilter('SELL'),
              ),
              _FilterChip(
                label: rl10n.filterClause,
                selected: filter == 'CLAUSE',
                onTap: () => onFilter('CLAUSE'),
              ),
              _FilterChip(
                label: rl10n.filterProtection,
                selected: filter == 'PROT',
                onTap: () => onFilter('PROT'),
              ),
              _FilterChip(
                label: rl10n.filterPoints,
                selected: filter == 'PTS',
                onTap: () => onFilter('PTS'),
              ),
              _FilterChip(
                label: rl10n.filterValue,
                selected: filter == 'VAL',
                onTap: () => onFilter('VAL'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await c.loadCards();
            },
            child: RewardCardGrid(
              cards: _filtered(),
              onUse: (card) => onUse(card),
              onTap: (card) => onTap(card),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        checkmarkColor: cs.primary,
        backgroundColor: cs.surfaceContainerHigh,
        selectedColor: cs.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: selected ? cs.onSurface : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ActivityTab extends StatefulWidget {
  const _ActivityTab({required this.c});
  final RewardsController c;

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  String _filter = LeagueShopActivityFilters.all;

  List<LeagueActivityEvent> get _visibleEvents {
    return widget.c.activity
        .where(LeagueShopActivityFilters.isShopEvent)
        .where((e) => LeagueShopActivityFilters.matchesFilter(e, _filter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final visible = _visibleEvents;
    final cs = Theme.of(context).colorScheme;
    final rl10n = context.rewardsL10n;
    const filterKeys = [
      LeagueShopActivityFilters.all,
      LeagueShopActivityFilters.packs,
      LeagueShopActivityFilters.roulette,
      LeagueShopActivityFilters.cards,
    ];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              for (final key in filterKeys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(rl10n.shopFilterLabel(key)),
                    selected: _filter == key,
                    onSelected: (_) => setState(() => _filter = key),
                    checkmarkColor: cs.primary,
                    backgroundColor: cs.surfaceContainerHigh,
                    selectedColor: cs.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: _filter == key
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => c.loadActivity(),
            color: cs.primary,
            child: c.loadingActivity && c.activity.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          SizedBox(height: 60),
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: cs.outline,
                          ),
                          SizedBox(height: 12),
                          Text(
                            rl10n.activityEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: visible.length + (c.hasMoreActivity ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= visible.length) {
                            if (!c.loadingActivity) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                c.loadActivity(loadMore: true);
                              });
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return LeagueActivityTile(event: visible[i]);
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    );
  }
}

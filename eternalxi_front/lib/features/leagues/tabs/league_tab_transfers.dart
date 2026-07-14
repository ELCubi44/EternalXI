import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/controller/league_offers_controller.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_shell_money_refresh.dart';
import 'package:eternal_xi/features/leagues/widgets/league_sent_offer_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueTabTransfers extends StatefulWidget {
  const LeagueTabTransfers({super.key});

  static final ValueNotifier<int?> externalSegmentRequest = ValueNotifier<int?>(
    null,
  );

  @override
  State<LeagueTabTransfers> createState() => _LeagueTabTransfersState();
}

class _LeagueTabTransfersState extends State<LeagueTabTransfers>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _segment = 0;
  int? _handledRefreshGeneration;

  void _handleExternalSegmentRequest() {
    final request = LeagueTabTransfers.externalSegmentRequest.value;
    if (!mounted || request == null) return;
    LeagueTabTransfers.externalSegmentRequest.value = null;
    if (request < 0 || request > 1) return;
    if (_segment != request) setState(() => _segment = request);
  }

  @override
  void initState() {
    super.initState();
    LeagueTabTransfers.externalSegmentRequest.addListener(
      _handleExternalSegmentRequest,
    );
  }

  @override
  void dispose() {
    LeagueTabTransfers.externalSegmentRequest.removeListener(
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
      context.read<LeagueOffersController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return Center(
        child: Text(
          context.l10n.leagueContextError,
          style: TextStyle(
            fontFamily: 'Lumiare',
            fontSize: 13,
            color: context.xiTextSecondary,
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      key: ValueKey<String>('${shell.leagueId}_${shell.idUsuario}'),
      create: (ctx) => LeagueOffersController(
        leaguesApiService: ctx.read<LeaguesApiService>(),
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      )..load(),
      child: _TransfersBody(shell: shell, segment: _segment, onSegment: (i) => setState(() => _segment = i)),
    );
  }
}

class _TransfersBody extends StatelessWidget {
  const _TransfersBody({
    required this.shell,
    required this.segment,
    required this.onSegment,
  });

  final LeagueShellData shell;
  final int segment;
  final ValueChanged<int> onSegment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ll = context.leagueL10n;
    final ctrl = context.watch<LeagueOffersController>();

    Future<void> onRefresh() async {
      final err = await ctrl.refresh();
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      await reloadLeagueShellAfterMoney(context);
    }

    final sentPending =
        ctrl.sent.where((LeagueOfferItem o) => o.pendiente).toList();
    final receivedPending =
        ctrl.received.where((LeagueOfferItem o) => o.pendiente).toList();
    final list = segment == 0 ? sentPending : receivedPending;

    return RefreshIndicator(
      color: XiColors.royalBlue,
      backgroundColor: context.xiCardElevated,
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const PageStorageKey<String>('league_tab_transfers'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: XiColors.classicGold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.transfers.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Lumiare',
                          fontSize: 14,
                          color: context.xiTextPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SegmentBar(
                    segment: segment,
                    sentCount: sentPending.length,
                    receivedCount: receivedPending.length,
                    onSegment: onSegment,
                  ),
                ],
              ),
            ),
          ),
          if (ctrl.isLoading && ctrl.sent.isEmpty && ctrl.received.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: XiColors.royalBlue),
              ),
            )
          else if (ctrl.errorMessage != null && list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: XiColors.heroRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ctrl.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 13,
                        color: context.xiTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _XiRetryChip(label: l10n.retry, onTap: () => ctrl.load()),
                  ],
                ),
              ),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  segment == 0 ? ll.noOffersPendingSnack : ll.noPendingOffers,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 14,
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final offer = list[index];
                  if (segment == 0) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < list.length - 1 ? 14 : 0,
                      ),
                      child: LeagueSentOfferItemCard(
                        offer: offer,
                        idLiga: shell.leagueId,
                        idUsuario: shell.idUsuario,
                        onAfterAction: () => ctrl.refresh(),
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < list.length - 1 ? 14 : 0,
                    ),
                    child: _ReceivedOfferCard(
                      offer: offer,
                      controller: ctrl,
                      idLiga: shell.leagueId,
                      idUsuario: shell.idUsuario,
                    ),
                  );
                }, childCount: list.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.segment,
    required this.sentCount,
    required this.receivedCount,
    required this.onSegment,
  });

  final int segment;
  final int sentCount;
  final int receivedCount;
  final ValueChanged<int> onSegment;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.isXiDark
            ? XiColors.surfaceContainer
            : XiColors.warmWhite,
        border: Border.all(color: context.xiDivider.withValues(alpha: 0.5)),
        boxShadow: context.xiCardShadow,
      ),
      child: Row(
        children: [
          _seg(context, 0, ll.offersTab, sentCount, XiColors.royalBlue),
          _seg(
            context,
            1,
            ll.receivedOffersTitle,
            receivedCount,
            XiColors.energyOrange,
          ),
        ],
      ),
    );
  }

  Widget _seg(
    BuildContext context,
    int i,
    String label,
    int count,
    Color color,
  ) {
    final selected = segment == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSegment(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.45))
                : null,
          ),
          child: Text(
            count > 0 ? '$label ($count)' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: selected ? color : context.xiTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceivedOfferCard extends StatelessWidget {
  const _ReceivedOfferCard({
    required this.offer,
    required this.controller,
    required this.idLiga,
    required this.idUsuario,
  });

  final LeagueOfferItem offer;
  final LeagueOffersController controller;
  final int idLiga;
  final int idUsuario;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final busy = controller.actionOfferId == offer.idOferta;
    final buyer = offer.nicknameComprador.trim().isEmpty
        ? '—'
        : offer.nicknameComprador.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isXiDark
              ? [const Color(0xFF152240), XiColors.surfaceContainer]
              : [XiColors.warmWhite, const Color(0xFFFFF3DC)],
        ),
        border: Border.all(
          color: XiColors.energyOrange.withValues(alpha: 0.35),
        ),
        boxShadow: context.xiCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.nombreVisible.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 13,
                    color: context.xiTextPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                LeagueMoneyFormat.euros(offer.cantidad.toDouble()),
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 18,
                  color: XiColors.classicGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${ll.offerSentTitle}: $buyer',
            style: TextStyle(
              fontFamily: 'Lumiare',
              fontSize: 11,
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  label: ll.reject,
                  color: XiColors.heroRed,
                  busy: busy,
                  onTap: () async {
                    final r = await controller.reject(offer.idOferta);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(r.message)),
                    );
                    if (r.success) await reloadLeagueShellAfterMoney(context);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  label: ll.accept,
                  color: XiColors.emeraldGreen,
                  busy: busy,
                  onTap: () async {
                    final r = await controller.accept(offer.idOferta);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(r.message)),
                    );
                    if (r.success) await reloadLeagueShellAfterMoney(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: XiColors.warmWhite,
                ),
              )
            : Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 11,
                  color: XiColors.warmWhite,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}

class _XiRetryChip extends StatelessWidget {
  const _XiRetryChip({required this.label, required this.onTap});

  final String label;
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
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Lumiare',
            fontSize: 12,
            color: XiColors.warmWhite,
          ),
        ),
      ),
    );
  }
}

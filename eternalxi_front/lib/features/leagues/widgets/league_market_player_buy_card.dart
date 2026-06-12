import 'package:eternal_xi/app/icons/xi_icons.dart';
import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/utils/league_offer_flow.dart';
import 'package:eternal_xi/features/leagues/utils/league_shell_money_refresh.dart';
import 'package:eternal_xi/features/leagues/utils/league_starter_probability_ui.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/shared/widgets/money_coins_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueMarketPlayerBuyCard extends StatefulWidget {
  const LeagueMarketPlayerBuyCard({
    super.key,
    required this.player,
    required this.idLiga,
    required this.idUsuario,
    required this.onAfterAction,
  });

  final LeagueSquadPlayer player;
  final int idLiga;
  final int idUsuario;
  final Future<void> Function() onAfterAction;

  static double directBuyPrice(LeagueSquadPlayer p) => p.valor * 2.0;

  @override
  State<LeagueMarketPlayerBuyCard> createState() =>
      _LeagueMarketPlayerBuyCardState();
}

class _LeagueMarketPlayerBuyCardState
    extends State<LeagueMarketPlayerBuyCard>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _press;
  late final Animation<double> _scale;

  bool get _isOwn => widget.player.idUsuarioDueno == widget.idUsuario;
  bool get _isMarket =>
      widget.player.idUsuarioDueno == LeagueSquadPlayer.usuarioMercadoId ||
      widget.player.enPoolMercado ||
      widget.player.esMercado;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _buyNow() async {
    if (_busy) return;
    final price = LeagueMarketPlayerBuyCard.directBuyPrice(widget.player);
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: XiColors.surfaceElevated,
        title: Text(
          ll.buyPlayer,
          style: const TextStyle(
            fontFamily: 'Lumiare',
            fontWeight: FontWeight.w800,
            color: XiColors.warmWhite,
          ),
        ),
        content: Text(
          ll.buyDirectDetailedBody(
            LeagueMoneyFormat.money(price),
            LeagueMoneyFormat.money(widget.player.valor),
          ),
          style: const TextStyle(
            fontFamily: 'Lumiare',
            color: XiColors.techLightGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(ll.buy),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final api = context.read<LeaguesApiService>();
    setState(() => _busy = true);
    try {
      final result = await api.buyLeaguePlayerNow(
        idLiga: widget.idLiga,
        idLigaJugador: widget.player.idLigaJugador,
        idUsuario: widget.idUsuario,
      );
      await Future.wait([
        reloadLeagueShellAfterMoney(context),
        widget.onAfterAction(),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.leagueL10n.purchaseCompleted(
              LeagueMoneyFormat.money(result.cantidadCompra.toDouble()),
              LeagueMoneyFormat.money(result.nuevoSaldo.toDouble()),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOffer() async {
    if (_busy || _isOwn || _isMarket) return;
    final shell = LeagueShellData.maybeOf(context);
    final miDinero = shell?.detail?.miDinero.floor();
    setState(() => _busy = true);
    try {
      await openLeaguePlayerOfferFlow(
        context: context,
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
        player: widget.player,
        miDinero: miDinero,
        onAfterSuccess: widget.onAfterAction,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDetail() {
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: widget.player,
      leagueId: widget.idLiga,
      idLigaJugador: widget.player.idLigaJugador,
      idUsuario: widget.idUsuario,
      isOwnPlayerHint: _isOwn,
      isMarketPlayerHint: _isMarket,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final ll = context.leagueL10n;
    final name = LeagueDisplayStrings.playerShortName(
      pila: p.pila,
      nombre: p.nombre,
      ll: ll,
    );
    final buyPrice = LeagueMarketPlayerBuyCard.directBuyPrice(p);
    final ownerName = p.nombreDuenoVisible.trim().isNotEmpty
        ? p.nombreDuenoVisible.trim()
        : (p.propietarioNick.trim().isNotEmpty ? p.propietarioNick.trim() : '—');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) {
          _press.reverse();
          if (!_busy) _openDetail();
        },
        onTapCancel: () => _press.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.xiCompactCardGradient,
              ),
              border: Border.all(color: context.xiBorderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  ClipOval(
                    child: LeaguePlayerAvatar(
                      player: p,
                      size: 48,
                      circular: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Lumiare',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.xiTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (_isOwn)
                          _StatusPill(
                            label: ll.youAreOwnerAlready,
                            bg: context.isXiDark
                                ? const Color(0xFF0A1E3A)
                                : XiColors.royalBlue.withValues(alpha: 0.12),
                            fg: XiColors.royalBlue,
                          )
                        else if (_isMarket)
                          Row(
                            children: [
                              const MoneyCoinsIcon(size: 20),
                              const SizedBox(width: 5),
                              Text(
                                LeagueMoneyFormat.money(buyPrice),
                                style: const TextStyle(
                                  fontFamily: 'Lumiare',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: XiColors.classicGold,
                                ),
                              ),
                            ],
                          )
                        else
                          _StatusPill(
                            label: ownerName,
                            bg: context.isXiDark
                                ? const Color(0xFF1A1030)
                                : XiColors.royalBlue.withValues(alpha: 0.12),
                            fg: context.isXiDark
                                ? const Color(0xFFB8A0E0)
                                : XiColors.magicPurple,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LeagueMarketPlayerCornerStats(
                    estado: p.estado,
                    valoracion: p.valoracion,
                    probabilidadTitular: p.probabilidadTitular,
                  ),
                  const SizedBox(width: 8),
                  // Action button
                  _ActionBtn(
                    isOwn: _isOwn,
                    isMarket: _isMarket,
                    busy: _busy,
                    onBuy: _buyNow,
                    onOffer: _sendOffer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusPill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final bool isOwn;
  final bool isMarket;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onOffer;
  const _ActionBtn({
    required this.isOwn,
    required this.isMarket,
    required this.busy,
    required this.onBuy,
    required this.onOffer,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isXiDark;
    if (isOwn) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? const Color(0xFF0A1830) : context.xiSurfaceInset,
          border: Border.all(
            color: dark
                ? const Color(0x3030D6E8)
                : XiColors.steelGray.withValues(alpha: 0.35),
          ),
        ),
        child: Center(
          child: XiIcon(
            XiIconType.lock,
            size: 16,
            color: dark ? XiColors.steelGray : XiColors.nightBlue.withValues(alpha: 0.55),
          ),
        ),
      );
    }
    if (busy) {
      return const SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: XiColors.royalBlue,
            ),
          ),
        ),
      );
    }
    if (isMarket) {
      return GestureDetector(
        onTap: onBuy,
        child: _MarketPrimaryActionCircle(
          child: const Icon(
            Icons.shopping_cart_checkout_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onOffer,
      child: _MarketPrimaryActionCircle(
        child: const Icon(
          Icons.local_offer_outlined,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MarketPrimaryActionCircle extends StatelessWidget {
  const _MarketPrimaryActionCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F62D8), XiColors.royalBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: XiColors.royalBlue.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_offer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Fila de jugador en pestaña Compra con CTA según propietario.
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

  /// Precio mostrado = doble de [LeagueSquadPlayer.valor] (valor actual en liga).
  static double directBuyPrice(LeagueSquadPlayer p) => p.valor * 2.0;

  @override
  State<LeagueMarketPlayerBuyCard> createState() =>
      _LeagueMarketPlayerBuyCardState();
}

class _LeagueMarketPlayerBuyCardState extends State<LeagueMarketPlayerBuyCard> {
  bool _busy = false;

  bool get _isOwn => widget.player.idUsuarioDueno == widget.idUsuario;
  bool get _isMarket =>
      widget.player.idUsuarioDueno == LeagueSquadPlayer.usuarioMercadoId ||
      widget.player.enPoolMercado ||
      widget.player.esMercado;

  Future<void> _buyNow() async {
    if (_busy) {
      return;
    }
    final price = LeagueMarketPlayerBuyCard.directBuyPrice(widget.player);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Comprar jugador'),
        content: Text(
          'Se realizará la compra directa por ${LeagueMoneyFormat.money(price)} '
          '(2× el valor actual ${LeagueMoneyFormat.money(widget.player.valor)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }

    final api = context.read<LeaguesApiService>();
    final shell = LeagueShellData.maybeOf(context);
    setState(() => _busy = true);
    try {
      final result = await api.buyLeaguePlayerNow(
        idLiga: widget.idLiga,
        idLigaJugador: widget.player.idLigaJugador,
        idUsuario: widget.idUsuario,
      );
      await Future.wait([shell?.reload() ?? Future.value(), widget.onAfterAction()]);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compra por ${LeagueMoneyFormat.money(result.cantidadCompra.toDouble())}. '
            'Nuevo saldo: ${LeagueMoneyFormat.money(result.nuevoSaldo.toDouble())}.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendOffer() async {
    if (_busy || _isOwn || _isMarket) {
      return;
    }
    setState(() => _busy = true);
    try {
      await LeaguePlayerOfferSheet.show(
        context: context,
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
        player: widget.player,
        onAfterSuccess: () async {
          final shell = LeagueShellData.maybeOf(context);
          await Future.wait([
            shell?.reload() ?? Future.value(),
            widget.onAfterAction(),
          ]);
        },
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openPlayerDetail() {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final p = widget.player;
    final name = LeagueDisplayStrings.playerShortName(
      pila: p.pila,
      nombre: p.nombre,
    );
    final buyPrice = LeagueMarketPlayerBuyCard.directBuyPrice(p);
    final ownerName = p.nombreDuenoVisible.trim().isNotEmpty
        ? p.nombreDuenoVisible.trim()
        : (p.propietarioNick.trim().isNotEmpty ? p.propietarioNick.trim() : '—');

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _busy
                  ? null
                  : _openPlayerDetail,
              borderRadius: BorderRadius.circular(40),
              child: LeaguePlayerAvatar(player: p, size: 52, circular: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _busy ? null : _openPlayerDetail,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_isOwn)
                    Text(
                      'Eres el dueño y ya',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (_isMarket)
                    Text(
                      LeagueMoneyFormat.money(buyPrice),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ownerName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (_isOwn)
              FilledButton.tonalIcon(
                onPressed: null,
                icon: const Icon(Icons.lock_person_outlined, size: 18),
                label: const SizedBox.shrink(),
              )
            else if (_isMarket)
              FilledButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                onPressed: _busy ? null : _buyNow,
                label: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.local_offer_outlined, size: 18),
                onPressed: _busy ? null : _sendOffer,
                label: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

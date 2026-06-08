import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_display_strings.dart';
import 'package:eternal_xi/features/leagues/utils/league_shell_money_refresh.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_offer_sheet.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Tarjeta de una oferta enviada pendiente (estilo similar al mercado nocturno).
class LeagueSentOfferItemCard extends StatefulWidget {
  const LeagueSentOfferItemCard({
    super.key,
    required this.offer,
    required this.idLiga,
    required this.idUsuario,
    required this.onAfterAction,
  });

  final LeagueOfferItem offer;
  final int idLiga;
  final int idUsuario;
  final Future<void> Function() onAfterAction;

  @override
  State<LeagueSentOfferItemCard> createState() =>
      _LeagueSentOfferItemCardState();
}

class _LeagueSentOfferItemCardState extends State<LeagueSentOfferItemCard> {
  bool _busy = false;

  LeagueOfferItem get _offer => widget.offer;

  int? get _miDinero {
    final shell = LeagueShellData.maybeOf(context);
    final money = shell?.detail?.miDinero;
    if (money == null) {
      return null;
    }
    return money.floor();
  }

  Future<void> _openOfferSheet() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await LeaguePlayerOfferSheet.show(
        context: context,
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuario,
        player: _offer.toSquadPlayer(),
        miDinero: _miDinero,
        idOferta: _offer.idOferta,
        cantidadActual: _offer.cantidad,
        onAfterSuccess: () async {
          await Future.wait([
            reloadLeagueShellAfterMoney(context),
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

  Future<void> _confirmCancel() async {
    if (_busy) {
      return;
    }
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.l10n.cancelOffer),
        content: Text(ll.cancelOfferConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(ll.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.l10n.cancelOffer),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      final api = context.read<LeaguesApiService>();
      final shell = LeagueShellData.maybeOf(context);
      final response = await api.cancelOffer(
        idLiga: widget.idLiga,
        idOferta: _offer.idOferta,
        idUsuario: widget.idUsuario,
      );
      await Future.wait([
        shell?.reload() ?? Future.value(),
        widget.onAfterAction(),
      ]);
      if (!mounted) {
        return;
      }
      final ll = context.leagueL10n;
      final msg = response.message.trim().isEmpty
          ? ll.offerCancelledSuccess
          : response.message.trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  void _openPlayerDetail() {
    final player = _offer.toSquadPlayer();
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: player,
      leagueId: widget.idLiga,
      idLigaJugador: _offer.idLigaJugador,
      idUsuario: widget.idUsuario,
      isOwnPlayerHint: false,
      isMarketPlayerHint: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uri = LeaguePlayerPhoto.resolve(_offer.toSquadPlayer());
    final name = LeagueDisplayStrings.playerShortName(
      pila: _offer.pila,
      nombre: _offer.nombreVisible.trim().isNotEmpty
          ? _offer.nombreVisible
          : _offer.nombre,
      ll: ll,
    );
    final ownerName = _offer.nicknameDuenoActual.trim().isEmpty
        ? '—'
        : _offer.nicknameDuenoActual.trim();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _openOfferSheet,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: uri != null
                            ? Image.network(
                                uri.toString(),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _avatarFallback(colorScheme),
                              )
                            : _avatarFallback(colorScheme),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _busy ? null : _openPlayerDetail,
                          ),
                        ),
                      ),
                      if (_busy)
                        Positioned.fill(
                          child: ColoredBox(
                            color: colorScheme.scrim.withValues(alpha: 0.35),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            LeagueTeamLogo(
                              idEquipo: _offer.idEquipo,
                              size: 24,
                              networkImageUrl: _offer
                                  .toSquadPlayer()
                                  .resolvedFotoEquipoUrl(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _offer.nombreEquipo.trim().isEmpty
                                    ? '—'
                                    : _offer.nombreEquipo,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                            ll.ownerNamed(ownerName),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: ll.currentValueLabel,
                      value: LeagueMoneyFormat.money(
                        _offer.valorActual.toDouble(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      label: ll.yourOffer,
                      value: LeagueMoneyFormat.money(
                        _offer.cantidad.toDouble(),
                      ),
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _openOfferSheet,
                      child: Text(ll.updateOffer),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: ll.cancelOfferTooltip,
                    onPressed: _busy ? null : _confirmCancel,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(ColorScheme colorScheme) {
    return Container(
      width: 88,
      height: 88,
      color: colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        size: 44,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? colorScheme.onPrimaryContainer : null,
            ),
          ),
        ],
      ),
    );
  }
}

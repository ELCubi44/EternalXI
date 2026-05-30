import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/night_market_models.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/controller/league_night_market_controller.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/utils/league_night_market_format.dart';
import 'package:eternal_xi/features/leagues/utils/league_night_market_images.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_photo.dart';
import 'package:eternal_xi/features/leagues/widgets/league_night_market_bid_sheet.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

class LeagueNightMarketItemCard extends StatelessWidget {
  const LeagueNightMarketItemCard({
    super.key,
    required this.item,
    required this.market,
    required this.controller,
    required this.onAfterMarketAction,
  });

  final NightMarketItem item;
  final NightMarketResponse market;
  final LeagueNightMarketController controller;
  final Future<void> Function() onAfterMarketAction;

  Future<void> _openBidSheet(BuildContext context) async {
    await LeagueNightMarketBidSheet.show(
      context: context,
      item: item,
      market: market,
      controller: controller,
      onAfterSuccess: onAfterMarketAction,
    );
  }

  void _openPlayerDetail(BuildContext context) {
    final player = LeagueSquadPlayer(
      idLigaJugador: item.idLigaJugador,
      idJugador: item.idJugador,
      nombre: item.nombre,
      pila: item.pila,
      posicion: item.posicion,
      valoracion: item.valoracion.toDouble(),
      idEquipo: item.idEquipo,
      nombreEquipo: item.nombreEquipo,
      estado: item.estado,
      cansancio: item.cansancio,
      valor: item.valorActual.toDouble(),
      fotoJugador: item.fotoJugador,
      enPoolMercado: true,
      propietarioNick: '',
      idUsuarioDueno: LeagueSquadPlayer.usuarioMercadoId,
      fotoEquipo: item.fotoEquipo,
      esMercado: true,
    );
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: player,
      leagueId: market.idLiga,
      idLigaJugador: item.idLigaJugador,
      idUsuario: market.idUsuario,
      isOwnPlayerHint: false,
      isMarketPlayerHint: true,
      isNightMarketPlayerHint: true,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ll = context.leagueL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ll.deleteBid),
        content: Text(ll.deleteBidConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(ll.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }

    final result = await controller.deleteBid(
      idMercadoDiario: item.idMercadoDiario,
    );

    if (!context.mounted) {
      return;
    }

    if (result.success) {
      await onAfterMarketAction();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uri = LeaguePlayerPhoto.resolveNightMarket(
      idJugador: item.idJugador,
      fotoJugador: item.fotoJugador,
    );
    final busy = controller.actionItemId == item.idMercadoDiario;

    final name = item.nombreVisible.trim().isEmpty
        ? (item.nombre.trim().isEmpty ? ll.genericPlayer : item.nombre)
        : item.nombreVisible;

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
        onTap: busy ? null : () => _openBidSheet(context),
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
                            onTap: busy ? null : () => _openPlayerDetail(context),
                          ),
                        ),
                      ),
                      if (busy)
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
                          onTap: busy ? null : () => _openPlayerDetail(context),
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
                              idEquipo: item.idEquipo,
                              size: 24,
                              networkImageUrl:
                                  LeagueNightMarketImages.teamBadgeNetworkUrl(
                                    idEquipo: item.idEquipo,
                                    fotoEquipo: item.fotoEquipo,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.nombreEquipo.trim().isEmpty
                                    ? '—'
                                    : item.nombreEquipo,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final features = <_FeatureData>[
                              _FeatureData(
                                icon: Icons.sports_soccer_rounded,
                                label: ll.positionLabel,
                                value: LeagueNightMarketFormat.posicionLabel(
                                  item.posicion,
                                ),
                                color: colorScheme.onSurfaceVariant,
                                showLabel: false,
                              ),
                              _FeatureData(
                                icon: Icons.star_rounded,
                                label: ll.valuationLabel,
                                value: '${item.valoracion}',
                                color: colorScheme.primary,
                                showLabel: false,
                              ),
                            ];
                            final visibleFeatures = features;
                            final itemWidth = (constraints.maxWidth - 8) / 2;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final f in visibleFeatures)
                                  SizedBox(
                                    width: itemWidth,
                                    child: _FeatureChip(data: f),
                                  ),
                              ],
                            );
                          },
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
                      value: LeagueNightMarketFormat.moneyInt(item.valorActual),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      label: ll.totalBids,
                      value: '${item.totalPujas}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : () => _openBidSheet(context),
                      child: Text(
                        item.miPuja == null ? ll.bidForPlayer : ll.updateBid,
                      ),
                    ),
                  ),
                  if (item.miPuja != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: ll.deleteBid,
                      onPressed: busy ? null : () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
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

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showLabel;
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.data});

  final _FeatureData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 14, color: data.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              data.showLabel ? '${data.label}: ${data.value}' : data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
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
            ),
          ),
        ],
      ),
    );
  }
}

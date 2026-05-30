import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_availability_icons.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_estado_titularidad.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

/// Ficha de jugador en modo plantilla (lista completa).
class LeagueSquadPlayerTile extends StatelessWidget {
  const LeagueSquadPlayerTile({super.key, required this.player, this.onTap});

  final LeagueSquadPlayer player;
  final VoidCallback? onTap;

  static String _rating(double v) {
    if (v.isNaN || v.isInfinite) {
      return '—';
    }
    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = player.nombre.trim().isNotEmpty
        ? player.nombre.trim()
        : player.pila.trim();
    final teamName = player.nombreEquipo.trim();
    final isInjured = leaguePlayerEstadoIsLesionado(player.estado);
    final isSanctioned = leaguePlayerEstadoIsSancionado(player.estado);

    final pointsLabel =
        player.puntosTotales == player.puntosTotales.roundToDouble()
        ? '${player.puntosTotales.toInt()}'
        : player.puntosTotales.toStringAsFixed(1).replaceAll('.', ',');
    const pointsOrange = Color(0xFFFF6D00);
    final isProtected = player.jugadorProtegido;
    final hasPendingOffer = player.tieneOfertaPendiente;
    final offerAccent = Colors.amber.shade700;
    const protectedColor = Color(0xFF64B5F6);
    final baseBorder = colorScheme.outlineVariant.withValues(alpha: 0.35);
    final highlightBorder = hasPendingOffer
        ? offerAccent.withValues(alpha: 0.72)
        : isProtected
            ? protectedColor.withValues(alpha: 0.55)
            : baseBorder;

    final card = Card(
      elevation: hasPendingOffer ? 2 : (isProtected ? 1 : 0),
      shadowColor: hasPendingOffer
          ? offerAccent.withValues(alpha: 0.25)
          : isProtected
              ? protectedColor.withValues(alpha: 0.2)
              : Colors.transparent,
      color: hasPendingOffer
          ? Color.alphaBlend(
              offerAccent.withValues(alpha: 0.09),
              colorScheme.surfaceContainerHigh,
            )
          : isProtected
              ? Color.alphaBlend(
                  protectedColor.withValues(alpha: 0.06),
                  colorScheme.surfaceContainerHigh,
                )
              : colorScheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: highlightBorder,
          width: (hasPendingOffer || isProtected) ? 1.3 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isProtected) ...[
                  Tooltip(
                    message: player.proteccionHastaFinTemporada
                        ? 'Protegido temporada'
                        : player.proteccionJornadaFin != null
                            ? 'Protegido hasta J${player.proteccionJornadaFin}'
                            : 'Protegido',
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: protectedColor,
                        boxShadow: [
                          BoxShadow(
                            color: protectedColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.surfaceContainerHighest,
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(Icons.shield_rounded, size: 13, color: Colors.white),
                    ),
                  ),
                ],
                if (hasPendingOffer) ...[
                  Tooltip(
                    message: ll.hasPendingOfferTooltip,
                    child: Semantics(
                      label: ll.hasPendingOfferTooltip,
                      child: Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: offerAccent,
                          boxShadow: [
                            BoxShadow(
                              color: offerAccent.withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 0.5,
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.surfaceContainerHighest,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_offer_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                Tooltip(
                  message: 'Puntos totales',
                  child: Text(
                    pointsLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: pointsOrange,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LeaguePlayerAvatar(player: player, size: 48, circular: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      LeagueTeamLogo(
                        idEquipo: player.idEquipo,
                        size: 22,
                        networkImageUrl: player.resolvedFotoEquipoUrl(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          teamName.isEmpty ? '—' : teamName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isInjured || isSanctioned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isInjured)
                        Icon(
                          LeaguePlayerAvailabilityIcons.injured,
                          size: 20,
                          color: colorScheme.error,
                        ),
                      if (isInjured && isSanctioned)
                        const SizedBox(width: 6),
                      if (isSanctioned)
                        Icon(
                          LeaguePlayerAvailabilityIcons.sanctioned,
                          size: 20,
                          color: colorScheme.tertiary,
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    icon: Icons.star_rounded,
                    text: _rating(player.valoracion),
                    colorScheme: colorScheme,
                    theme: theme,
                    emphasize: true,
                    stretch: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    icon: Icons.payments_outlined,
                    text: LeagueMoneyFormat.money(player.valor),
                    colorScheme: colorScheme,
                    theme: theme,
                    emphasize: false,
                    stretch: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.theme,
    this.emphasize = false,
    this.stretch = false,
  });

  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool emphasize;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final bg = emphasize
        ? colorScheme.primaryContainer.withValues(alpha: 0.55)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    return Container(
      width: stretch ? double.infinity : null,
      constraints: stretch ? null : const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

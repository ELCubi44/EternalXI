import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/features/leagues/widgets/league_fichajes_phase_banner.dart';
import 'package:flutter/material.dart';

/// Encabezado compacto con datos del detalle de liga (GET /leagues/{id}).
class LeagueSummaryHeader extends StatelessWidget {
  const LeagueSummaryHeader({super.key, required this.detail});

  final LeagueDetail detail;

  String get _seasonLabel {
    final n = detail.nombreTemporada.trim();
    if (n.isNotEmpty) {
      return n;
    }
    return 'Temporada';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seasonUri = detail.idTemporada > 0
        ? LeagueAssetUrls.seasonCover(detail.idTemporada).toString()
        : null;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (seasonUri != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.network(
                        seasonUri,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.calendar_month_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        avatar: seasonUri == null
                            ? Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                                color: colorScheme.primary,
                              )
                            : null,
                        label: Text(_seasonLabel),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        avatar: Icon(
                          Icons.groups_2_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        label: Text('${detail.participantes} participantes'),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (detail.soyAdmin)
                        Chip(
                          avatar: Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          label: const Text('Administrador'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (detail.nicknameAdministrador.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Administrador: ${detail.nicknameAdministrador.trim()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            LeagueFichajesPhaseBanner(detail: detail),
            const SizedBox(height: 12),
            Text(
              'Código de invitación',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              detail.codigoInvitacion.isEmpty ? '—' : detail.codigoInvitacion,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.stars_rounded,
                    label: 'Puntos',
                    value: LeagueMoneyFormat.points(detail.misPuntos),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Dinero',
                    value: LeagueMoneyFormat.money(detail.miDinero),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.trending_up,
                    label: 'Valor equipo',
                    value: LeagueMoneyFormat.teamValue(detail.miValorEquipo),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

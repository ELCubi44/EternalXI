import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_availability_icons.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_estado_titularidad.dart';
import 'package:flutter/material.dart';

/// Etiqueta cualitativa para UI (no sustituye al porcentaje numérico del backend).
String starterTitularidadBandLabel(int? p, LeagueL10n ll) =>
    ll.starterProbabilityBandLabel(p);

String starterTitularidadPercentLabel(int? p, LeagueL10n ll) {
  if (p == null) {
    return ll.starterProbUnknown;
  }
  return '$p%';
}

Color starterTitularidadChipBackground(int? p, ColorScheme cs) {
  if (p == null) {
    return cs.surfaceContainerHighest.withValues(alpha: 0.72);
  }
  if (p >= 80) {
    return cs.primaryContainer.withValues(alpha: 0.5);
  }
  if (p >= 50) {
    return cs.secondaryContainer.withValues(alpha: 0.42);
  }
  if (p >= 25) {
    return cs.tertiaryContainer.withValues(alpha: 0.38);
  }
  if (p >= 1) {
    return cs.surfaceContainerHighest.withValues(alpha: 0.78);
  }
  return cs.errorContainer.withValues(alpha: 0.38);
}

Color starterTitularidadChipForeground(int? p, ColorScheme cs) {
  if (p == null) {
    return cs.onSurfaceVariant;
  }
  if (p >= 80) {
    return cs.onPrimaryContainer;
  }
  if (p >= 50) {
    return cs.onSecondaryContainer;
  }
  if (p >= 25) {
    return cs.onTertiaryContainer;
  }
  if (p >= 1) {
    return cs.onSurface;
  }
  return cs.onErrorContainer;
}

/// Rojo (baja) → verde (alta). Backend suele usar 0–95.
Color starterTitularidadScaleBackgroundSolid(int percent) {
  final t = (percent.clamp(0, 100)) / 100.0;
  const red = Color(0xFFC62828);
  const green = Color(0xFF2E7D32);
  return Color.lerp(red, green, t)!;
}

Color starterTitularidadScaleOnBackground(int percent) {
  final bg = starterTitularidadScaleBackgroundSolid(percent);
  return bg.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
}

/// Badge compacto de probabilidad de jugar la próxima jornada.
class LeaguePlayProbabilityBadge extends StatelessWidget {
  const LeaguePlayProbabilityBadge({
    required this.percent,
    super.key,
  });

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: starterTitularidadScaleBackgroundSolid(percent),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.88),
          width: 1.1,
        ),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontFamily: 'Lumiare',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: starterTitularidadScaleOnBackground(percent),
          height: 1.0,
        ),
      ),
    );
  }
}

String leagueMarketPlayerRatingLabel(num value) {
  if (value.isNaN || value.isInfinite) {
    return '—';
  }
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

/// Esquina superior derecha en cards de mercado: % jugar, valoración e iconos.
class LeagueMarketPlayerCornerStats extends StatelessWidget {
  const LeagueMarketPlayerCornerStats({
    super.key,
    required this.estado,
    required this.valoracion,
    this.probabilidadTitular,
    this.showValoracion = true,
    this.showAvailabilityIcons = false,
  });

  final String estado;
  final num valoracion;
  final int? probabilidadTitular;
  final bool showValoracion;
  final bool showAvailabilityIcons;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ll = LeagueL10n.of(context);
    final showPlayProb = probabilidadTitular != null &&
        !leaguePlayerEstadoOcultaProbabilidadTitular(estado);
    final isInjured = leaguePlayerEstadoIsLesionado(estado);
    final isSanctioned = leaguePlayerEstadoIsSancionado(estado);
    final rating = leagueMarketPlayerRatingLabel(valoracion);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showPlayProb)
          LeaguePlayProbabilityBadge(percent: probabilidadTitular!),
        if (showPlayProb && showValoracion) const SizedBox(height: 3),
        if (showValoracion)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 11, color: cs.primary),
              const SizedBox(width: 2),
              Text(
                rating,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  height: 1.0,
                ),
              ),
            ],
          ),
        if (showAvailabilityIcons && (isInjured || isSanctioned)) ...[
          if (showPlayProb || showValoracion) const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInjured)
                Tooltip(
                  message: ll.injured,
                  child: LeaguePlayerAvailabilityIcons.injured(size: 28),
                ),
              if (isInjured && isSanctioned) const SizedBox(width: 6),
              if (isSanctioned)
                Tooltip(
                  message: ll.suspended,
                  child: LeaguePlayerAvailabilityIcons.sanctioned(size: 28),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

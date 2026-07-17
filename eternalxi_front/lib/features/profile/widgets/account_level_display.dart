import 'dart:math' as math;

import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Barra de experiencia de cuenta. [compact] = solo línea + nivel a la derecha.
class AccountLevelDisplay extends StatelessWidget {
  const AccountLevelDisplay({
    super.key,
    required this.nivel,
    required this.rango,
    required this.xpEnNivel,
    required this.xpParaSiguiente,
    this.compact = false,
    this.showXpUnit = false,
    this.animateProgress = false,
    this.displayXpEnNivel,
    this.displayXpParaSiguiente,
    this.progressFrom,
    this.progressAnimationDuration,
  });

  final int nivel;
  final String rango;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final bool compact;
  /// Si true, muestra "xp" tras el contador (p. ej. `312/354 xp`).
  final bool showXpUnit;
  final bool animateProgress;
  final int? displayXpEnNivel;
  final int? displayXpParaSiguiente;
  final double? progressFrom;
  final Duration? progressAnimationDuration;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactLevelBar(
        nivel: nivel,
        rango: rango,
        xpEnNivel: displayXpEnNivel ?? xpEnNivel,
        xpParaSiguiente: displayXpParaSiguiente ?? xpParaSiguiente,
        showXpUnit: showXpUnit,
        animateProgress: animateProgress,
        progressFrom: progressFrom,
        progressAnimationDuration: progressAnimationDuration,
      );
    }
    return _CardLevelBar(
      nivel: nivel,
      rango: rango,
      xpEnNivel: displayXpEnNivel ?? xpEnNivel,
      xpParaSiguiente: displayXpParaSiguiente ?? xpParaSiguiente,
      animateProgress: animateProgress,
      progressFrom: progressFrom,
      progressAnimationDuration: progressAnimationDuration,
    );
  }
}

/// Anillo de XP alrededor de la foto de perfil (arco desde abajo-derecha).
class AccountLevelAvatarRing extends StatelessWidget {
  const AccountLevelAvatarRing({
    super.key,
    required this.nivel,
    required this.xpEnNivel,
    required this.xpParaSiguiente,
    required this.child,
    this.ringStroke = 4.5,
    this.ringGap = 5,
    this.animateProgress = false,
    this.displayXpEnNivel,
    this.displayXpParaSiguiente,
    this.progressFrom,
    this.progressAnimationDuration,
  });

  final int nivel;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final Widget child;
  final double ringStroke;
  final double ringGap;
  final bool animateProgress;
  final int? displayXpEnNivel;
  final int? displayXpParaSiguiente;
  final double? progressFrom;
  final Duration? progressAnimationDuration;

  /// Arco desde abajo-derecha, ~270° en sentido horario.
  static const double arcStartAngle = math.pi / 4;
  static const double arcSweepAngle = math.pi * 1.5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentXp = displayXpEnNivel ?? xpEnNivel;
    final maxXp = (displayXpParaSiguiente ?? xpParaSiguiente) <= 0
        ? 1
        : (displayXpParaSiguiente ?? xpParaSiguiente);
    final progress = (currentXp / maxXp).clamp(0.0, 1.0);
    final from = (progressFrom ?? 0).clamp(0.0, 1.0);
    final padding = ringStroke + ringGap;

    return Semantics(
      label: 'Nivel $nivel. Experiencia $currentXp de $maxXp.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: animateProgress
                    ? (progressAnimationDuration ??
                        const Duration(milliseconds: 900))
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: from, end: progress),
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _AvatarXpArcPainter(
                      progress: value,
                      trackColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.85,
                      ),
                      progressColor: XiColors.techCyan,
                      strokeWidth: ringStroke,
                      startAngle: arcStartAngle,
                      sweepAngle: arcSweepAngle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: child,
                    ),
                  );
                },
              ),
              Positioned(
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: XiColors.royalBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: XiColors.techCyan.withValues(alpha: 0.55),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: XiColors.royalBlue.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$nivel',
                    style: const TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 10,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarXpArcPainter extends CustomPainter {
  const _AvatarXpArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, track);

    if (progress > 0) {
      final fill = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarXpArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _CompactLevelBar extends StatelessWidget {
  const _CompactLevelBar({
    required this.nivel,
    required this.rango,
    required this.xpEnNivel,
    required this.xpParaSiguiente,
    required this.showXpUnit,
    required this.animateProgress,
    this.progressFrom,
    this.progressAnimationDuration,
  });

  final int nivel;
  final String rango;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final bool showXpUnit;
  final bool animateProgress;
  final double? progressFrom;
  final Duration? progressAnimationDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxXp = xpParaSiguiente <= 0 ? 1 : xpParaSiguiente;
    final progress = (xpEnNivel / maxXp).clamp(0.0, 1.0);
    final from = (progressFrom ?? 0).clamp(0.0, 1.0);
    final xpLabel = showXpUnit ? '$xpEnNivel/$maxXp xp' : '$xpEnNivel/$maxXp';

    return Semantics(
      label: 'Nivel $nivel, $rango. Experiencia $xpEnNivel de $maxXp.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                xpLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Nivel $nivel',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              duration: animateProgress
                  ? (progressAnimationDuration ??
                      const Duration(milliseconds: 900))
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: from, end: progress),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                );
              },
            ),
          ),
          if (rango.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rango,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardLevelBar extends StatelessWidget {
  const _CardLevelBar({
    required this.nivel,
    required this.rango,
    required this.xpEnNivel,
    required this.xpParaSiguiente,
    required this.animateProgress,
    this.progressFrom,
    this.progressAnimationDuration,
  });

  final int nivel;
  final String rango;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final bool animateProgress;
  final double? progressFrom;
  final Duration? progressAnimationDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxXp = xpParaSiguiente <= 0 ? 1 : xpParaSiguiente;
    final progress = (xpEnNivel / maxXp).clamp(0.0, 1.0);
    final from = (progressFrom ?? 0).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: 'Nivel $nivel, rango $rango. Experiencia $xpEnNivel de $maxXp.',
      child: Material(
        color: cs.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rango,
                      style: theme.textTheme.titleSmall?.copyWith(
                        ),
                    ),
                  ),
                  Text(
                    'Nivel $nivel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$xpEnNivel/$maxXp',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  duration: animateProgress
                      ? const Duration(milliseconds: 900)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: from, end: progress),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: cs.surface.withValues(alpha: 0.35),
                      color: cs.primary,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    this.animateProgress = false,
    this.displayXpEnNivel,
    this.displayXpParaSiguiente,
    this.progressFrom,
  });

  final int nivel;
  final String rango;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final bool compact;
  final bool animateProgress;
  final int? displayXpEnNivel;
  final int? displayXpParaSiguiente;
  final double? progressFrom;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactLevelBar(
        nivel: nivel,
        rango: rango,
        xpEnNivel: displayXpEnNivel ?? xpEnNivel,
        xpParaSiguiente: displayXpParaSiguiente ?? xpParaSiguiente,
        animateProgress: animateProgress,
        progressFrom: progressFrom,
      );
    }
    return _CardLevelBar(
      nivel: nivel,
      rango: rango,
      xpEnNivel: displayXpEnNivel ?? xpEnNivel,
      xpParaSiguiente: displayXpParaSiguiente ?? xpParaSiguiente,
      animateProgress: animateProgress,
      progressFrom: progressFrom,
    );
  }
}

class _CompactLevelBar extends StatelessWidget {
  const _CompactLevelBar({
    required this.nivel,
    required this.rango,
    required this.xpEnNivel,
    required this.xpParaSiguiente,
    required this.animateProgress,
    this.progressFrom,
  });

  final int nivel;
  final String rango;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final bool animateProgress;
  final double? progressFrom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxXp = xpParaSiguiente <= 0 ? 1 : xpParaSiguiente;
    final progress = (xpEnNivel / maxXp).clamp(0.0, 1.0);
    final from = (progressFrom ?? 0).clamp(0.0, 1.0);

    return Semantics(
      label: 'Nivel $nivel, $rango. Experiencia $xpEnNivel de $maxXp.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xpEnNivel/$maxXp',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Nivel $nivel',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
                  ? const Duration(milliseconds: 900)
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
  });

  final int nivel;
  final String rango;
  final int xpEnNivel;
  final int xpParaSiguiente;
  final bool animateProgress;
  final double? progressFrom;

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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Nivel $nivel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$xpEnNivel/$maxXp',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
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

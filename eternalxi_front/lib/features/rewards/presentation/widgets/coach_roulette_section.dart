import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_coach_detail_card.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:flutter/material.dart';

class CoachRouletteSection extends StatelessWidget {
  const CoachRouletteSection({
    super.key,
    required this.summary,
    required this.busy,
    required this.onSpin,
  });

  final RewardSummaryModel summary;
  final bool busy;
  final VoidCallback? onSpin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = summary.ruletaEntrenadorUsada;
    final coach = summary.entrenadorActual;
    final canAfford =
        summary.puntosRecompensaUsuario >= summary.costeRuletaEntrenador;
    final enabled = !used && canAfford && !busy;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: used
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF311B92),
                  Color(0xFF4527A0),
                ],
              ),
        color: used ? const Color(0xFF1C2742) : null,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  used ? Icons.sports_soccer_rounded : Icons.casino_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    used ? 'Tu entrenador' : 'Ruleta de entrenador',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!used) ...[
                  CoachRouletteInfoButton(
                    costePuntos: summary.costeRuletaEntrenador,
                  ),
                  const SizedBox(width: 6),
                ],
                if (!used && summary.costeRuletaEntrenador > 0)
                  Text(
                    formatRewardPoints(summary.costeRuletaEntrenador),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFE082),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (used && coach != null)
              RewardCoachDetailCard(coach: coach)
            else if (used)
              Text(
                'Ruleta ya utilizada',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              )
            else ...[
              Text(
                'Consigue un entrenador libre para esta liga.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              if (!canAfford)
                Text(
                  'Puntos insuficientes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFFAB91),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (!canAfford) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: enabled ? onSpin : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.06),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Girar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

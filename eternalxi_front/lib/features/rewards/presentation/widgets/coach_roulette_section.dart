import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
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
    final canAfford =
        summary.puntosRecompensaUsuario >= summary.costeRuletaEntrenador;
    final enabled = !used && canAfford && !busy;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C2742), Color(0xFF12182A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.casino_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ruleta de entrenador',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (summary.costeRuletaEntrenador > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF263238),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'Coste: ${formatRewardPoints(summary.costeRuletaEntrenador)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFFFE082),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Consigue un entrenador libre para esta liga. Solo puedes usar la ruleta una vez.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          if (used && summary.entrenadorActual != null) ...[
            const SizedBox(height: 12),
            _CoachResult(coach: summary.entrenadorActual!),
          ] else if (summary.entrenadorActual != null) ...[
            const SizedBox(height: 10),
            _CoachHint(coach: summary.entrenadorActual!),
          ],
          const SizedBox(height: 14),
          if (used)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: Text(
                'Ruleta ya utilizada',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else ...[
            if (!canAfford)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Puntos insuficientes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFFAB91),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: enabled ? onSpin : null,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: const Text('Girar ruleta'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoachHint extends StatelessWidget {
  const _CoachHint({required this.coach});

  final RewardCoachItem coach;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Entrenador actual: ${coach.displayName}'
      '${(coach.nombreEquipo?.trim().isNotEmpty ?? false) ? ' (${coach.nombreEquipo})' : ''}.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFFFFD54F),
      ),
    );
  }
}

class _CoachResult extends StatelessWidget {
  const _CoachResult({required this.coach});

  final RewardCoachItem coach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF1A237E).withValues(alpha: 0.3),
        border: Border.all(color: const Color(0xFF5C6BC0).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_rounded, color: Color(0xFF9FA8DA), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrenador conseguido',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFFFD54F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coach.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((coach.nombreEquipo ?? '').trim().isNotEmpty)
                  Text(
                    coach.nombreEquipo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

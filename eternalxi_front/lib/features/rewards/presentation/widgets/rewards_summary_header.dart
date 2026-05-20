import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:flutter/material.dart';

class RewardsSummaryHeader extends StatelessWidget {
  const RewardsSummaryHeader({
    super.key,
    required this.summary,
    required this.leagueName,
  });

  final RewardSummaryModel summary;
  final String leagueName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coach = summary.entrenadorActual;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leagueName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ChipStat(
                icon: Icons.stars_rounded,
                label: 'Puntos',
                value: formatRewardPoints(summary.puntosRecompensaUsuario),
              ),
              _ChipStat(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Presupuesto',
                value: formatRewardMoney(summary.dineroLiga),
              ),
              _ChipStat(
                icon: Icons.style_rounded,
                label: 'Cartas',
                value:
                    '${summary.cartasDisponibles} disp. · ${summary.cartasUsadas} usadas',
              ),
            ],
          ),
          if (coach != null) ...[
            const SizedBox(height: 12),
            _CoachLine(coach: coach),
          ],
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1C2742).withValues(alpha: 0.95),
            const Color(0xFF12182A).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachLine extends StatelessWidget {
  const _CoachLine({required this.coach});

  final RewardCoachItem coach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1A237E).withValues(alpha: 0.35),
        border: Border.all(color: const Color(0xFF5C6BC0).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_rounded, color: Color(0xFF9FA8DA), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Entrenador: ${coach.displayName}'
              '${(coach.nombreEquipo?.trim().isNotEmpty ?? false) ? ' · ${coach.nombreEquipo}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

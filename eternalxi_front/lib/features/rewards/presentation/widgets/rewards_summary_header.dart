import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
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
          Row(
            children: [
              Expanded(
                child: _ChipStat(
                  icon: Icons.stars_rounded,
                  label: 'Puntos',
                  value: formatRewardPoints(summary.puntosRecompensaUsuario),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChipStat(
                  icon: Icons.style_rounded,
                  label: 'Cartas disponibles',
                  value: '${summary.cartasDisponibles}',
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

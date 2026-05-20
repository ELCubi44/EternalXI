import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/features/leagues/utils/league_config_labels.dart';
import 'package:flutter/material.dart';

/// Aviso de semana previa de fichajes antes del primer partido.
class LeagueFichajesPhaseBanner extends StatelessWidget {
  const LeagueFichajesPhaseBanner({super.key, required this.detail});

  final LeagueDetail detail;

  @override
  Widget build(BuildContext context) {
    if (!detail.isFichajesPhaseActive) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final start = detail.primerPartidoEn!;
    final when = LeagueConfigLabels.formatLeagueStart(start);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: colorScheme.onTertiaryContainer,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fase de fichajes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La liga empieza el $when',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

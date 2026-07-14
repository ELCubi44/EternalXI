import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/features/leagues/utils/league_config_labels.dart';
import 'package:flutter/material.dart';

/// Resumen de reglas de la liga en ajustes / detalle.
class LeagueConfigSummaryCard extends StatelessWidget {
  const LeagueConfigSummaryCard({super.key, required this.detail});

  final LeagueDetail detail;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final rows = LeagueConfigLabels.summaryRows(detail, l10n: context.l10n);
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ll.leagueConfigSummaryTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20),
              _SummaryRow(row: rows[i], theme: theme, colorScheme: colorScheme),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.row,
    required this.theme,
    required this.colorScheme,
  });

  final LeagueConfigSummaryRow row;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            row.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            row.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

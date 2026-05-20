import 'package:eternal_xi/features/leagues/utils/league_config_labels.dart';
import 'package:flutter/material.dart';

/// Controles de configuración avanzada al crear una liga.
class CreateLeagueAdvancedConfigSection extends StatelessWidget {
  const CreateLeagueAdvancedConfigSection({
    super.key,
    required this.maxParticipantes,
    required this.semanaPreviaFichajes,
    required this.permiteEntresemana,
    required this.idaYVuelta,
    required this.recompensaBaseJornada,
    required this.dineroPorPuntoFantasy,
    required this.enabled,
    required this.onMaxParticipantesChanged,
    required this.onSemanaPreviaChanged,
    required this.onPermiteEntresemanaChanged,
    required this.onIdaYVueltaChanged,
    required this.onRecompensaChanged,
    required this.onDineroPorPuntoChanged,
  });

  final int maxParticipantes;
  final bool semanaPreviaFichajes;
  final bool permiteEntresemana;
  final bool idaYVuelta;
  final int recompensaBaseJornada;
  final int dineroPorPuntoFantasy;
  final bool enabled;
  final ValueChanged<int> onMaxParticipantesChanged;
  final ValueChanged<bool> onSemanaPreviaChanged;
  final ValueChanged<bool> onPermiteEntresemanaChanged;
  final ValueChanged<bool> onIdaYVueltaChanged;
  final ValueChanged<int> onRecompensaChanged;
  final ValueChanged<int> onDineroPorPuntoChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Configuración avanzada',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Participantes, calendario, recompensas y economía de la liga.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel(
          title: 'Participantes de la liga',
          subtitle: 'Managers fantasy (no equipos del calendario real).',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in LeagueConfigLabels.maxParticipantesOptions)
              FilterChip(
                label: Text('$n'),
                selected: maxParticipantes == n,
                onSelected: enabled
                    ? (selected) {
                        if (selected) {
                          onMaxParticipantesChanged(n);
                        }
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Semana previa de fichajes'),
          subtitle: const Text(
            'Si está activa, la primera jornada se retrasa una semana para fichar. '
            'Si no, la liga empieza en el primer bloque disponible.',
          ),
          value: semanaPreviaFichajes,
          onChanged: enabled ? onSemanaPreviaChanged : null,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Añadir jornadas entre semana'),
          subtitle: const Text(
            'La liga siempre jugará los fines de semana. Si activas esta opción, '
            'también habrá jornadas martes y miércoles para que termine antes.',
          ),
          value: permiteEntresemana,
          onChanged: enabled ? onPermiteEntresemanaChanged : null,
        ),
        const SizedBox(height: 12),
        _FieldLabel(title: 'Formato de liga'),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('Ida y vuelta'),
            ),
            ButtonSegment(
              value: false,
              label: Text('Solo ida'),
            ),
          ],
          selected: {idaYVuelta},
          onSelectionChanged: enabled
              ? (s) => onIdaYVueltaChanged(s.first)
              : null,
        ),
        const SizedBox(height: 20),
        _FieldLabel(
          title: 'Puntos recompensa por jornada',
          subtitle:
              '${LeagueConfigLabels.recompensaMin}–${LeagueConfigLabels.recompensaMax} pts',
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: recompensaBaseJornada.toDouble(),
                min: LeagueConfigLabels.recompensaMin.toDouble(),
                max: LeagueConfigLabels.recompensaMax.toDouble(),
                divisions:
                    (LeagueConfigLabels.recompensaMax -
                            LeagueConfigLabels.recompensaMin) ~/
                        LeagueConfigLabels.recompensaStep,
                label: '$recompensaBaseJornada',
                onChanged: enabled
                    ? (v) {
                        final step = LeagueConfigLabels.recompensaStep;
                        final snapped =
                            ((v / step).round() * step)
                                .clamp(
                                  LeagueConfigLabels.recompensaMin,
                                  LeagueConfigLabels.recompensaMax,
                                )
                                .toInt();
                        onRecompensaChanged(snapped);
                      }
                    : null,
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '$recompensaBaseJornada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FieldLabel(title: 'Dinero por punto fantasy'),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final amount in LeagueConfigLabels.dineroPorPuntoOptions)
              ButtonSegment(
                value: amount,
                label: Text(
                  LeagueConfigLabels.dineroPorPuntoOptionLabel(amount),
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
          selected: {dineroPorPuntoFantasy},
          onSelectionChanged: enabled
              ? (s) => onDineroPorPuntoChanged(s.first)
              : null,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

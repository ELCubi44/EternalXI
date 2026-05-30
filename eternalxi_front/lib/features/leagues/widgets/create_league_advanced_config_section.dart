import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
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
    final l10n = context.l10n;
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.advancedConfig,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ll.advancedConfigSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel(
          title: ll.leagueParticipantsTitle,
          subtitle: ll.leagueParticipantsSubtitle,
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
          title: Text(ll.signingWeekTitle),
          subtitle: Text(ll.signingWeekSubtitleFull),
          value: semanaPreviaFichajes,
          onChanged: enabled ? onSemanaPreviaChanged : null,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(ll.midweekMatchdaysTitle),
          subtitle: Text(ll.midweekMatchdaysSubtitleFull),
          value: permiteEntresemana,
          onChanged: enabled ? onPermiteEntresemanaChanged : null,
        ),
        const SizedBox(height: 12),
        _FieldLabel(title: ll.leagueFormat),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: Text(ll.roundTrip),
            ),
            ButtonSegment(
              value: false,
              label: Text(ll.singleLeg),
            ),
          ],
          selected: {idaYVuelta},
          onSelectionChanged: enabled
              ? (s) => onIdaYVueltaChanged(s.first)
              : null,
        ),
        const SizedBox(height: 20),
        _FieldLabel(
          title: ll.minRewardPerMatchday,
          subtitle: ll.minRewardSliderSubtitle(
            LeagueConfigLabels.recompensaStep,
            LeagueConfigLabels.recompensaMin,
            LeagueConfigLabels.recompensaMax,
          ),
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
        const SizedBox(height: 6),
        Text(
          ll.rewardDistributionWithParticipants(
            maxParticipantes,
            LeagueConfigLabels.rewardDistributionPreview(
              minReward: recompensaBaseJornada,
              participantCount: maxParticipantes,
              l10n: l10n,
            ),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _FieldLabel(title: ll.moneyPerFantasyPoint),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final amount in LeagueConfigLabels.dineroPorPuntoOptions)
              ButtonSegment(
                value: amount,
                label: Text(
                  LeagueConfigLabels.dineroPorPuntoOptionLabel(
                    amount,
                    l10n: l10n,
                  ),
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

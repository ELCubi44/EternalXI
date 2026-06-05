import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_player_round_stats.dart';
import 'package:eternal_xi/features/leagues/utils/league_jornada_points_display.dart';
import 'package:eternal_xi/features/leagues/utils/league_round_stat_display.dart';
import 'package:eternal_xi/features/leagues/utils/league_saves_stat_visibility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Carrusel horizontal de jornadas + detalle de stats para la ficha de jugador.
///
/// Totales y desglose de puntos: solo backend (`stat.puntos`, `puntosDesglose`).
class LeaguePlayerProfileRoundsSection extends StatefulWidget {
  const LeaguePlayerProfileRoundsSection({
    super.key,
    required this.roundStats,
    required this.playerPosition,
    this.initialSelectedIdJornada,
  });

  final List<LeaguePlayerRoundStats> roundStats;
  final String playerPosition;

  final int? initialSelectedIdJornada;

  @override
  State<LeaguePlayerProfileRoundsSection> createState() =>
      _LeaguePlayerProfileRoundsSectionState();
}

class _LeaguePlayerProfileRoundsSectionState
    extends State<LeaguePlayerProfileRoundsSection> {
  List<LeaguePlayerRoundStats> _rounds = const [];
  int _selected = 0;
  bool _userPickedRound = false;
  final ScrollController _scrollController = ScrollController();

  static int _defaultRoundIndex(List<LeaguePlayerRoundStats> rounds) {
    for (var i = 0; i < rounds.length; i++) {
      if (rounds[i].estadoJornada.trim().toUpperCase() == 'EN_CURSO') {
        return i;
      }
    }
    return 0;
  }

  static String _estadoBonito(String raw, LeagueL10n ll) {
    switch (raw.trim().toUpperCase()) {
      case 'EN_CURSO':
        return ll.roundInProgress;
      case 'FINALIZADA':
        return ll.roundFinished;
      case 'PENDIENTE':
        return ll.roundPending;
      default:
        final t = raw.trim();
        return t.isEmpty ? '—' : t;
    }
  }

  void _scrollChipIntoView() {
    if (!_scrollController.hasClients || _rounds.isEmpty) {
      return;
    }
    const w = 56.0;
    final offset =
        (_selected * w) -
        _scrollController.position.viewportDimension / 2 +
        w / 2;
    final max = _scrollController.position.maxScrollExtent;
    final min = _scrollController.position.minScrollExtent;
    _scrollController.animateTo(
      offset.clamp(min, max),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _syncRounds();
  }

  @override
  void didUpdateWidget(covariant LeaguePlayerProfileRoundsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roundStats != widget.roundStats ||
        oldWidget.initialSelectedIdJornada != widget.initialSelectedIdJornada) {
      _syncRounds();
    }
  }

  void _syncRounds() {
    final prevId = _rounds.isEmpty ||
            _selected < 0 ||
            _selected >= _rounds.length
        ? null
        : _rounds[_selected].idJornada;
    final sorted = [...widget.roundStats]
      ..sort((a, b) => a.numeroJornada.compareTo(b.numeroJornada));
    _rounds = sorted;
    if (sorted.isEmpty) {
      _selected = 0;
    } else {
      var idx = -1;
      if (prevId != null && prevId > 0) {
        idx = sorted.indexWhere((r) => r.idJornada == prevId);
      }
      if (idx < 0 &&
          !_userPickedRound &&
          widget.initialSelectedIdJornada != null &&
          widget.initialSelectedIdJornada! > 0) {
        idx = sorted.indexWhere(
          (r) => r.idJornada == widget.initialSelectedIdJornada,
        );
      }
      _selected = idx >= 0
          ? idx
          : _defaultRoundIndex(sorted).clamp(0, sorted.length - 1);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChipIntoView());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_RoundStatRow> _rowsFor(LeaguePlayerRoundStats stat, LeagueL10n ll) {
    final d = stat.puntosDesglose;
    final matchVisible = leagueRoundMatchStatsAreVisible(stat.estadoJornada);
    final yesNo = (bool v) => v ? ll.yesWord : ll.noWord;
    final rows = <_RoundStatRow>[
      _RoundStatRow(
        icon: Icons.timer_outlined,
        label: ll.statMinutesPlayed,
        value: leagueRoundStatDisplayValue(
          '${stat.minutosJugados}',
          officialPoints: d.minutos,
        ),
      ),
      _RoundStatRow(
        icon: Icons.sports_soccer,
        label: ll.statGoals,
        value: leagueRoundStatDisplayValue(
          '${stat.goles}',
          officialPoints: d.goles,
        ),
      ),
      _RoundStatRow(
        icon: Icons.handshake_outlined,
        label: ll.statAssists,
        value: leagueRoundStatDisplayValue(
          '${stat.asistencias}',
          officialPoints: d.asistencias,
        ),
      ),
      _RoundStatRow(
        icon: Icons.sports_handball_outlined,
        label: ll.statDribbles,
        value: leagueRoundStatDisplayValue(
          '${stat.regates}',
          officialPoints: d.regates,
        ),
      ),
      _RoundStatRow(
        icon: Icons.shield_moon_outlined,
        label: ll.statBallsRecovered,
        value: leagueRoundStatDisplayValue(
          '${stat.balonesRecuperados}',
          officialPoints: d.balonesRecuperados,
        ),
      ),
    ];

    if (leagueShouldShowSavesStat(widget.playerPosition, stat.paradas)) {
      rows.add(
        _RoundStatRow(
          icon: Icons.pan_tool_alt_outlined,
          label: ll.statSaves,
          value: leagueRoundStatDisplayValue(
            '${stat.paradas}',
            officialPoints: d.paradas,
          ),
        ),
      );
    }

    rows.addAll([
      _RoundStatRow(
        icon: Icons.clean_hands_outlined,
        label: ll.statCleanSheet,
        value: leagueRoundStatDisplayValue(
          yesNo(stat.porteriaCero),
          officialPoints: d.porteriaCero,
        ),
      ),
      _RoundStatRow(
        icon: Icons.shield_outlined,
        label: ll.statGoalsConceded,
        value: leagueRoundStatDisplayValue(
          '${stat.golesEncajados}',
          officialPoints: d.golesEncajados,
        ),
      ),
      _RoundStatRow(
        icon: Icons.credit_card,
        label: ll.statYellowCards,
        value: leagueRoundStatDisplayValue(
          '${stat.tarjetasAmarillas}',
          officialPoints: d.tarjetasAmarillas,
        ),
      ),
      _RoundStatRow(
        icon: Icons.report_rounded,
        label: ll.statRedCards,
        value: leagueRoundStatDisplayValue(
          '${stat.tarjetasRojas}',
          officialPoints: d.tarjetasRojas,
        ),
      ),
    ]);

    if (matchVisible) {
      rows.add(
        _RoundStatRow(
          icon: Icons.healing_outlined,
          label: ll.statInjuredInMatch,
          value: leagueRoundStatDisplayValue(
            yesNo(stat.lesionadoEnPartido),
            officialPoints: d.lesion,
          ),
        ),
      );
    }

    rows.add(
      _RoundStatRow(
        icon: Icons.newspaper_rounded,
        label: ll.statNewspaperRating,
        value: leagueRoundStatDisplayValue(
          _noteLabel(stat.notaPeriodico),
          officialPoints: matchVisible ? d.notaPeriodico : null,
        ),
      ),
    );

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_rounds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Text(
          ll.noRoundsForPlayerDetail,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      );
    }

    final stat = _rounds[_selected.clamp(0, _rounds.length - 1)];
    final statRows = _rowsFor(stat, ll);

    if (kDebugMode) {
      debugPrint(
        '[player-detail][full-stat] {idJornada:${stat.idJornada},puntos:${stat.puntos},puntosDesglose:${stat.puntosDesglose.hasAny},estadoJornada:${stat.estadoJornada}}',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_view_week_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ll.roundHistoryByMatchdays,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _rounds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final rr = _rounds[i];
                    final sel = i == _selected;
                    final chipLabel = leagueJornadaChipLabel(
                      estadoJornada: rr.estadoJornada,
                      numeroJornada: rr.numeroJornada,
                      ll: ll,
                    );
                    return ChoiceChip(
                      label: Text(chipLabel),
                      selected: sel,
                      onSelected: (_) {
                        setState(() {
                          _userPickedRound = true;
                          _selected = i;
                        });
                        _scrollChipIntoView();
                      },
                      visualDensity: VisualDensity.compact,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: sel
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurface,
                      ),
                      selectedColor: colorScheme.secondaryContainer,
                      backgroundColor: colorScheme.surface.withValues(
                        alpha: 0.7,
                      ),
                      side: BorderSide(
                        color: sel
                            ? colorScheme.primary.withValues(alpha: 0.65)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.45,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leagueJornadaIsInProgress(stat.estadoJornada)
                            ? ll.roundInProgressMatchday
                            : stat.numeroJornada > 0
                            ? ll.matchday(stat.numeroJornada)
                            : '—',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (stat.estadoJornada.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _estadoBonito(stat.estadoJornada, ll),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (leagueJornadaShowsGrantedPoints(stat.estadoJornada)) ...[
                        const SizedBox(height: 12),
                        _StatLine(
                          icon: Icons.stars_rounded,
                          label: ll.statPoints,
                          value: LeagueMoneyFormat.points(stat.puntos),
                          emphasized: true,
                        ),
                      ],
                      for (final row in statRows)
                        _StatLine(
                          icon: row.icon,
                          label: row.label,
                          value: row.value,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _noteLabel(double? note) {
    if (note == null) {
      return 'Sin nota';
    }
    if (note == note.roundToDouble()) {
      return note.toInt().toString();
    }
    return note.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _RoundStatRow {
  const _RoundStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: emphasized ? const Color(0xFFFF6D00) : null,
            ),
          ),
        ],
      ),
    );
  }
}

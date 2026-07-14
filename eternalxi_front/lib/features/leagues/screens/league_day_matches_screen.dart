import 'dart:async';

import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_match_live_payload.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/screens/league_match_detail_screen.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';
import 'package:eternal_xi/features/leagues/utils/league_spanish_datetime.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lista de partidos de un día concreto.
class LeagueDayMatchesScreen extends StatefulWidget {
  const LeagueDayMatchesScreen({
    super.key,
    required this.leagueId,
    required this.idUsuario,
    required this.day,
    required this.matches,
  });

  final int leagueId;
  final int idUsuario;
  final DateTime day;
  final List<LeagueMatchSummary> matches;

  @override
  State<LeagueDayMatchesScreen> createState() => _LeagueDayMatchesScreenState();
}

class _LeagueDayMatchesScreenState extends State<LeagueDayMatchesScreen> {
  Timer? _pollTimer;
  final Map<int, LeagueMatchLivePayload> _liveByMatchId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshVisibleMatchesLive();
      if (!mounted) {
        return;
      }
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
        await _refreshVisibleMatchesLive();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  static String _titleDate(DateTime d) {
    final l = d.toLocal();
    return LeagueSpanishDateTime.formatDateNumeric(
      DateTime(l.year, l.month, l.day),
    );
  }

  static String _teamLabel(String raw) {
    final t = raw.trim();
    return t.isEmpty ? '—' : t;
  }

  static DateTime _calendarDayKey(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  List<LeagueMatchSummary> _visibleMatches() {
    final dayKey = _calendarDayKey(widget.day);
    return widget.matches.where((m) {
      final fp = m.fechaPartido;
      if (fp == null) {
        return false;
      }
      return _calendarDayKey(fp) == dayKey;
    }).toList();
  }

  Future<void> _refreshVisibleMatchesLive() async {
    final visible = _visibleMatches();
    if (visible.isEmpty) {
      return;
    }
    final api = context.read<LeaguesApiService>();
    final nextById = <int, LeagueMatchLivePayload>{..._liveByMatchId};

    await Future.wait(
      visible.map((m) async {
        if (m.idPartido <= 0) {
          return;
        }
        try {
          final live = await api.getLeagueMatchLive(
            idLiga: widget.leagueId,
            idPartido: m.idPartido,
            idUsuario: widget.idUsuario,
          );
          nextById[m.idPartido] = live;
        } catch (_) {
          // Live opcional para la previa: mantener fallback al summary.
        }
      }),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _liveByMatchId
        ..clear()
        ..addAll(nextById);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dayKey = _calendarDayKey(widget.day);
    final filtered = _visibleMatches();

    if (kDebugMode) {
      debugPrint(
        '[LeagueDayMatches] dayKey=$dayKey day=${widget.day.toIso8601String()} '
        'incoming=${widget.matches.length} filtered=${filtered.length}',
      );
      for (final m in filtered) {
        final fp = m.fechaPartido;
        debugPrint(
          '[LeagueDayMatches] idPartido=${m.idPartido} kickoff=$fp '
          'local=${fp?.toLocal()} filterDay=${fp == null ? null : _calendarDayKey(fp)}',
        );
      }
    }

    final ll = context.leagueL10n;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(ll.matchesOnDate(_titleDate(widget.day))),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final m = filtered[i];
          final live = _liveByMatchId[m.idPartido];
          final phase = resolveLeagueMatchDisplayPhase(
            live: live,
            detailEstado: null,
            summaryEstado: m.estado,
          );
          final effectiveGolesLocal = resolveLeagueMatchScoreLocal(
            live: live,
            detail: null,
            summary: m,
          );
          final effectiveGolesVisitante = resolveLeagueMatchScoreVisitante(
            live: live,
            detail: null,
            summary: m,
          );
          final minuteLabel = resolveLiveMinuteLabel(live: live, phase: phase);
          final kick = m.fechaPartido;
          final todayChip = LeagueSpanishDateTime.todayChipIfSameDay(
            kick,
            english: ll.isEnglish,
          );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => LeagueMatchDetailScreen(
                      leagueId: widget.leagueId,
                      idUsuario: widget.idUsuario,
                      summary: m,
                    ),
                  ),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainerHigh,
                      colorScheme.surface.withValues(alpha: 0.92),
                    ],
                  ),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(phase: phase, compact: true),
                          if (todayChip != null &&
                              phase != LeagueMatchDisplayPhase.finished)
                            Chip(
                              label: Text(todayChip),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: colorScheme.tertiaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _TeamRow(
                              alignEnd: false,
                              name: _teamLabel(m.nombreLocal),
                              idEquipo: m.idEquipoLocal,
                              imageUrl: m.escudoLocalUrl(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _MatchCenterBadge(
                                phase: phase,
                                golesLocal: effectiveGolesLocal,
                                golesVisitante: effectiveGolesVisitante,
                                kickoff: kick,
                                minuteLabel: minuteLabel,
                                compact: true,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: _TeamRow(
                              alignEnd: true,
                              name: _teamLabel(m.nombreVisitante),
                              idEquipo: m.idEquipoVisitante,
                              imageUrl: m.escudoVisitanteUrl(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.alignEnd,
    required this.name,
    required this.idEquipo,
    required this.imageUrl,
  });

  final bool alignEnd;
  final String name;
  final int idEquipo;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!alignEnd) ...[
          LeagueTeamLogo(
            idEquipo: idEquipo,
            size: 44,
            networkImageUrl: imageUrl,
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            name,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: theme.textTheme.titleSmall?.copyWith(
              height: 1.15,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 10),
          LeagueTeamLogo(
            idEquipo: idEquipo,
            size: 44,
            networkImageUrl: imageUrl,
          ),
        ],
      ],
    );
    return row;
  }
}

class _MatchCenterBadge extends StatelessWidget {
  const _MatchCenterBadge({
    required this.phase,
    required this.golesLocal,
    required this.golesVisitante,
    required this.kickoff,
    this.minuteLabel,
    this.compact = false,
  });

  final LeagueMatchDisplayPhase phase;
  final int golesLocal;
  final int golesVisitante;
  final DateTime? kickoff;
  final String? minuteLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (phase) {
      case LeagueMatchDisplayPhase.pending:
        final t = LeagueSpanishDateTime.formatTimeHm(kickoff);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 22, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              t,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ll.kickoffLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      case LeagueMatchDisplayPhase.live:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$golesLocal - $golesVisitante',
              textAlign: TextAlign.center,
              style: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                ),
            ),
            if (minuteLabel != null) ...[
              const SizedBox(height: 3),
              Text(
                minuteLabel!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      case LeagueMatchDisplayPhase.finished:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$golesLocal - $golesVisitante',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                ),
            ),
          ],
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.phase, this.compact = false});

  final LeagueMatchDisplayPhase phase;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ll = context.leagueL10n;
    final label = leagueMatchPhaseLabel(phase, ll);
    Color bg;
    Color fg;
    IconData icon;
    switch (phase) {
      case LeagueMatchDisplayPhase.pending:
        bg = colorScheme.secondaryContainer;
        fg = colorScheme.onSecondaryContainer;
        icon = Icons.event_available_outlined;
        break;
      case LeagueMatchDisplayPhase.live:
        bg = colorScheme.errorContainer;
        fg = colorScheme.onErrorContainer;
        icon = Icons.sensors;
        break;
      case LeagueMatchDisplayPhase.finished:
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        icon = Icons.flag_outlined;
        break;
    }
    return Chip(
      avatar: Icon(icon, size: compact ? 16 : 18, color: fg),
      label: Text(label),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      side: BorderSide.none,
      backgroundColor: bg,
      labelStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: fg),
    );
  }
}

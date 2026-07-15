import 'dart:async';

import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_match_detail_payload.dart';
import 'package:eternal_xi/data/models/league_match_live_payload.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';
import 'package:eternal_xi/features/leagues/utils/league_spanish_datetime.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_lineups_tab.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_timeline_tab.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueMatchDetailScreen extends StatefulWidget {
  const LeagueMatchDetailScreen({
    super.key,
    required this.leagueId,
    required this.idUsuario,
    required this.summary,
  });

  final int leagueId;
  final int idUsuario;
  final LeagueMatchSummary summary;

  @override
  State<LeagueMatchDetailScreen> createState() =>
      _LeagueMatchDetailScreenState();
}

class _LeagueMatchDetailScreenState extends State<LeagueMatchDetailScreen> {
  LeagueMatchDetailPayload? _payload;
  LeagueMatchLivePayload? _live;
  bool _loading = true;
  String? _error;
  int _segment = 0;
  Timer? _liveTimer;
  bool _livePolling = false;

  @override
  void dispose() {
    _stopLivePolling();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.summary.idPartido <= 0) {
      setState(() {
        _loading = false;
        _error = context.leagueL10n.invalidMatchIdError;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final p = await api.getLeagueMatchDetail(
        idLiga: widget.leagueId,
        idPartido: widget.summary.idPartido,
        idUsuario: widget.idUsuario,
        summaryFallback: widget.summary,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _payload = p;
        _loading = false;
      });
      if (kDebugMode) {
        final raw = p.raw;
        final k = p.inicioPartidoDetalle;
        final lk = k?.toLocal();
        final lkDay = lk == null ? null : DateTime(lk.year, lk.month, lk.day);
        debugPrint(
          '[LeagueMatchDetail] idPartido=${p.summary.idPartido} '
          'inicioEn(raw)=${raw['inicioEn'] ?? raw['inicio_en']} '
          'parsed=$k local=$lk localDay=$lkDay',
        );
      }
      await _bootstrapLive(api);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _bootstrapLive(LeaguesApiService api) async {
    await _fetchLiveQuiet(api);
  }

  Future<void> _fetchLiveQuiet(LeaguesApiService api) async {
    try {
      final live = await api.getLeagueMatchLive(
        idLiga: widget.leagueId,
        idPartido: widget.summary.idPartido,
        idUsuario: widget.idUsuario,
      );
      if (!mounted) {
        return;
      }
      setState(() => _live = live);
      _syncLivePolling(api);
    } on ApiException catch (_) {
      if (!mounted) {
        return;
      }
      _syncLivePolling(context.read<LeaguesApiService>());
    } catch (_) {
      if (!mounted) {
        return;
      }
      _syncLivePolling(context.read<LeaguesApiService>());
    }
  }

  void _syncLivePolling(LeaguesApiService api) {
    if (!mounted || _payload == null) {
      return;
    }
    final phase = _effectivePhase();
    if (shouldPollLeagueMatchLive(phase: phase, kickoff: _kickoff())) {
      _startLivePolling(api);
    } else {
      _stopLivePolling();
    }
  }

  void _startLivePolling(LeaguesApiService api) {
    if (_livePolling) {
      return;
    }
    _stopLivePolling();
    _livePolling = true;
    _liveTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      await _fetchLiveQuiet(api);
    });
  }

  void _stopLivePolling() {
    _liveTimer?.cancel();
    _liveTimer = null;
    _livePolling = false;
  }

  LeagueMatchSummary get _effectiveSummary =>
      _payload?.summary ?? widget.summary;

  LeagueMatchDisplayPhase _effectivePhase() {
    return resolveLeagueMatchDisplayPhase(
      live: _live,
      detailEstado: _payload?.estadoPartido,
      summaryEstado: _effectiveSummary.estado,
    );
  }

  DateTime? _kickoff() {
    final p = _payload;
    return p?.inicioPartidoDetalle ??
        p?.summary.fechaPartido ??
        widget.summary.fechaPartido;
  }

  int _scoreLocal() {
    return resolveLeagueMatchScoreLocal(
      live: _live,
      detail: _payload,
      summary: _effectiveSummary,
    );
  }

  int _scoreVisitante() {
    return resolveLeagueMatchScoreVisitante(
      live: _live,
      detail: _payload,
      summary: _effectiveSummary,
    );
  }

  String? _liveMinuteLabel() {
    return resolveLiveMinuteLabel(live: _live, phase: _effectivePhase());
  }

  Widget _hero(ThemeData theme, ColorScheme colorScheme) {
    final ll = context.leagueL10n;
    final s = _effectiveSummary;
    final phase = _effectivePhase();
    final jNum = _payload?.numeroJornadaDetalle ?? widget.summary.numeroJornada;
    final kick = _kickoff();
    final dateStr =
        LeagueSpanishDateTime.formatDateLong(kick, english: ll.isEnglish);
    final timeStr = LeagueSpanishDateTime.formatTimeHm(kick);
    final gl = _scoreLocal();
    final gv = _scoreVisitante();

    Widget centerContent;
    switch (phase) {
      case LeagueMatchDisplayPhase.pending:
        centerContent = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateStr,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeStr,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ll.scheduledKickoffLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        );
        break;
      case LeagueMatchDisplayPhase.live:
        final minLabel = _liveMinuteLabel();
        centerContent = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    size: 12,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ll.liveBadge,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.error,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$gl - $gv',
              style: theme.textTheme.displaySmall?.copyWith(
                height: 1.05,
              ),
            ),
            if (minLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                minLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                ll.inPlayLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
        break;
      case LeagueMatchDisplayPhase.finished:
        centerContent = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$gl - $gv',
              style: theme.textTheme.displaySmall?.copyWith(
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ll.finishedLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.55),
            colorScheme.surfaceContainerHigh,
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
        child: Column(
          children: [
            if (jNum != null && jNum > 0) ...[
              Text(
                ll.matchday(jNum),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 0.6,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _TeamHeaderLarge(
                    name: s.nombreLocal,
                    idEquipo: s.idEquipoLocal,
                    imageUrl: s.escudoLocalUrl(),
                    onTap: s.idEquipoLocal > 0
                        ? () => LeagueInnerNavigation.openCatalogTeamPlayers(
                              context: context,
                              idEquipo: s.idEquipoLocal,
                              nombreEquipo: s.nombreLocal.trim().isEmpty
                                  ? null
                                  : s.nombreLocal.trim(),
                              fotoEquipo: s.escudoLocalUrl(),
                              idLiga: widget.leagueId,
                              idUsuario: widget.idUsuario,
                            )
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'vs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamHeaderLarge(
                    name: s.nombreVisitante,
                    idEquipo: s.idEquipoVisitante,
                    imageUrl: s.escudoVisitanteUrl(),
                    onTap: s.idEquipoVisitante > 0
                        ? () => LeagueInnerNavigation.openCatalogTeamPlayers(
                              context: context,
                              idEquipo: s.idEquipoVisitante,
                              nombreEquipo: s.nombreVisitante.trim().isEmpty
                                  ? null
                                  : s.nombreVisitante.trim(),
                              fotoEquipo: s.escudoVisitanteUrl(),
                              idLiga: widget.leagueId,
                              idUsuario: widget.idUsuario,
                            )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            centerContent,
          ],
        ),
      ),
    );
  }

  String _appBarTitle() {
    final a = _effectiveSummary.nombreLocal.trim();
    final b = _effectiveSummary.nombreVisitante.trim();
    if (a.isEmpty && b.isEmpty) {
      return context.leagueL10n.matchTitle;
    }
    if (a.isEmpty) {
      return b;
    }
    if (b.isEmpty) {
      return a;
    }
    return '$a — $b';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ll = context.leagueL10n;
    final payload = _payload;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _appBarTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _stopLivePolling();
          await _load();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _hero(theme, colorScheme),
            const SizedBox(height: 16),
            if (_loading && payload == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && payload == null)
              _DetailError(message: _error!, onRetry: _load)
            else if (payload == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  ll.couldNotLoadMatchInfo,
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DetailError(
                    message: _error!,
                    onRetry: _load,
                    compact: true,
                  ),
                ),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text(ll.timelineTab),
                    icon: const Icon(Icons.timeline_outlined),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(ll.lineupsTab),
                    icon: const Icon(Icons.grid_on_outlined),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (selected) {
                  setState(() => _segment = selected.first);
                },
              ),
              const SizedBox(height: 12),
              if (_segment == 0)
                LeagueMatchTimelineTab(
                  roster: buildLeagueMatchRoster(detail: payload, live: _live),
                  events: resolveLeagueMatchTimelineEvents(
                    live: _live,
                    detail: payload,
                    summaryEstado: _effectiveSummary.estado,
                  ),
                  phase: _effectivePhase(),
                  scoreLocal: _scoreLocal(),
                  scoreVisitante: _scoreVisitante(),
                  liveMinuteLabel: _liveMinuteLabel(),
                  localTeamName: _effectiveSummary.nombreLocal,
                  awayTeamName: _effectiveSummary.nombreVisitante,
                )
              else
                LeagueMatchLineupsTab(
                  payload: payload,
                  summary: _effectiveSummary,
                  live: _live,
                  onOpenTeamPlayers: (idEquipo, nombreEquipo, fotoEquipo) =>
                      LeagueInnerNavigation.openCatalogTeamPlayers(
                        context: context,
                        idEquipo: idEquipo,
                        nombreEquipo: nombreEquipo,
                        fotoEquipo: fotoEquipo,
                        idLiga: widget.leagueId,
                        idUsuario: widget.idUsuario,
                      ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamHeaderLarge extends StatelessWidget {
  const _TeamHeaderLarge({
    required this.name,
    required this.idEquipo,
    required this.imageUrl,
    this.onTap,
  });

  final String name;
  final int idEquipo;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ll = context.leagueL10n;
    final n = name.trim();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LeagueTeamLogo(idEquipo: idEquipo, size: 68, networkImageUrl: imageUrl),
              const SizedBox(height: 12),
              Text(
                n.isEmpty ? ll.genericTeam : n,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(
          alpha: compact ? 0.4 : 0.55,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        compact ? 10 : 14,
        14,
        compact ? 10 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}

import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_participant_lineup_history.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/utils/league_spanish_datetime.dart';
import 'package:eternal_xi/features/leagues/utils/league_jornada_points_display.dart';
import 'package:eternal_xi/features/leagues/widgets/league_participant_lineup_round_pitch.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/features/leagues/widgets/league_round_fantasy_substitution_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParticipantLineupHistoryScreen extends StatefulWidget {
  const ParticipantLineupHistoryScreen({
    super.key,
    required this.idLiga,
    required this.idLigaParticipante,
    required this.idUsuarioSolicitante,
    this.idUsuarioParticipante,
    this.nickname,
  });

  final int idLiga;
  final int idLigaParticipante;
  final int idUsuarioSolicitante;
  final int? idUsuarioParticipante;
  final String? nickname;

  @override
  State<ParticipantLineupHistoryScreen> createState() =>
      _ParticipantLineupHistoryScreenState();
}

class _ParticipantLineupHistoryScreenState
    extends State<ParticipantLineupHistoryScreen> {
  bool _loading = true;
  String? _error;
  LeagueParticipantLineupHistorySummary? _data;
  int? _selectedJornadaId;
  LeagueParticipantLineupRoundSummary? _selectedRound;
  LeagueParticipantLineupRoundDetail? _selectedDetail;
  bool _loadingRoundDetail = false;
  String? _roundDetailError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _humanError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final data = await api.getParticipantLineupHistory(
        idLiga: widget.idLiga,
        idLigaParticipante: widget.idLigaParticipante,
        idUsuario: widget.idUsuarioSolicitante,
        fallbackParticipantUserId: widget.idUsuarioParticipante,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _selectedJornadaId = _pickInitialRound(data)?.idJornada;
        _selectedRound = _pickInitialRound(data);
        _selectedDetail = null;
        _roundDetailError = null;
        _loading = false;
      });
      final initial = _pickInitialRound(data);
      if (initial != null && initial.alineacionDisponible) {
        await _loadRoundDetail(initial);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _humanError(e);
        _loading = false;
      });
    }
  }

  LeagueParticipantLineupRoundSummary? _pickInitialRound(
    LeagueParticipantLineupHistorySummary data,
  ) {
    if (data.jornadas.isEmpty) {
      return null;
    }
    for (final j in data.jornadas) {
      if (j.isInProgress) {
        return j;
      }
    }
    for (final j in data.jornadas) {
      if (j.alineacionDisponible) {
        return j;
      }
    }
    return data.jornadas.first;
  }

  Future<void> _loadRoundDetail(
    LeagueParticipantLineupRoundSummary round,
  ) async {
    final data = _data;
    if (data == null) {
      return;
    }
    setState(() {
      _loadingRoundDetail = true;
      _roundDetailError = null;
      _selectedRound = round;
      _selectedJornadaId = round.idJornada;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final detail = await api.getParticipantLineupRoundDetail(
        idLiga: data.idLiga,
        idLigaParticipante: data.idLigaParticipante,
        idJornada: round.idJornada,
        idUsuario: widget.idUsuarioSolicitante,
        fallbackParticipantUserId: data.idUsuarioParticipante,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedDetail = detail;
        _loadingRoundDetail = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _roundDetailError = _humanError(e);
        _selectedDetail = null;
        _loadingRoundDetail = false;
      });
    }
  }

  Future<void> _onRoundSelected(LeagueParticipantLineupRoundSummary round) async {
    if (_selectedJornadaId == round.idJornada) {
      return;
    }
    if (!round.alineacionDisponible) {
      setState(() {
        _selectedRound = round;
        _selectedJornadaId = round.idJornada;
        _selectedDetail = null;
        _roundDetailError = null;
      });
      return;
    }
    await _loadRoundDetail(round);
  }

  void _openPlayerDetail(LeagueParticipantLineupRoundPlayer player) {
    final participantUserId = _data?.idUsuarioParticipante ?? widget.idUsuarioParticipante;
    final hasParticipantUser = (participantUserId ?? 0) > 0;
    final isOwnHint = hasParticipantUser
        ? participantUserId == widget.idUsuarioSolicitante
        : null;
    final isMarketHint = hasParticipantUser ? false : null;
    final jid = (_selectedJornadaId != null && _selectedJornadaId! > 0)
        ? _selectedJornadaId
        : null;
    LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: player.toSquadPlayer(),
      leagueId: widget.idLiga,
      idLigaJugador: player.idLigaJugador,
      idUsuario: widget.idUsuarioSolicitante,
      idJornada: jid,
      isOwnPlayerHint: isOwnHint,
      isMarketPlayerHint: isMarketHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ll = context.leagueL10n;
    final nick = (_data?.nickname.trim().isNotEmpty ?? false)
        ? _data!.nickname.trim()
        : (widget.nickname?.trim().isNotEmpty ?? false)
        ? widget.nickname!.trim()
        : ll.participantFallback;

    return Scaffold(
      appBar: AppBar(title: Text(ll.lineupHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ll.couldNotLoadHistoryTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      ),
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.retry),
                  ),
                ],
              )
            : _data == null || _data!.jornadas.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 72),
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 56,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    ll.noMatchdaysAvailable,
                    style: theme.textTheme.titleMedium?.copyWith(
                      ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ll.noMatchdaysHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  Text(
                    nick,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _data!.jornadas.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final row = _data!.jornadas[i];
                        final selected = _selectedJornadaId == row.idJornada;
                        final label = leagueJornadaChipLabel(
                          estadoJornada: row.estadoJornada,
                          numeroJornada: row.numeroJornada,
                          ll: ll,
                        );
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => _onRoundSelected(row),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_selectedRound != null)
                    _RoundHeader(
                      row: _selectedRound!,
                      detail: _detailForSelectedRound(
                        _selectedRound!,
                        _selectedDetail,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_selectedRound == null)
                    const SizedBox.shrink()
                  else if (!_selectedRound!.alineacionDisponible)
                    const _RoundEmptyState()
                  else if (_loadingRoundDetail)
                    const Center(child: CircularProgressIndicator())
                  else if (_roundDetailError != null)
                    _RoundErrorState(
                      message: _roundDetailError!,
                      onRetry: () => _loadRoundDetail(_selectedRound!),
                    )
                  else if (_selectedDetail != null) ...[
                    LeagueParticipantLineupRoundPitch(
                      titulares: _selectedDetail!.titulares,
                      idCapitan: _selectedDetail!.idCapitan,
                      formacionEfectiva: _selectedDetail!.formacionEfectiva,
                      emptySlots: _selectedDetail!.emptySlots,
                      showJornadaPitchBadges:
                          _selectedDetail!.shouldShowJornadaPitchBadges,
                      entrenadorAsignado: _selectedDetail!.entrenadorAsignado,
                      onPlayerTap: _openPlayerDetail,
                    ),
                    const SizedBox(height: 16),
                    _BenchSection(
                      players: _selectedDetail!.reservas,
                      showJornadaPitchBadges:
                          _selectedDetail!.shouldShowJornadaPitchBadges,
                      onPlayerTap: _openPlayerDetail,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Detalle cargado solo si coincide con [round]; evita mostrar totales de otra jornada
/// mientras el fetch está en curso.
LeagueParticipantLineupRoundDetail? _detailForSelectedRound(
  LeagueParticipantLineupRoundSummary round,
  LeagueParticipantLineupRoundDetail? detail,
) {
  if (detail == null || detail.idJornada != round.idJornada) {
    return null;
  }
  return detail;
}

class _RoundHeader extends StatelessWidget {
  const _RoundHeader({required this.row, this.detail});

  final LeagueParticipantLineupRoundSummary row;

  /// Si existe y es de la misma jornada que [row], el marcador de puntos usa
  /// [LeagueParticipantLineupRoundDetail.puntosTotales] (incluye capitán, míster, penalizaciones).
  /// Si no, [LeagueParticipantLineupRoundSummary.puntosTotales] del listado.
  final LeagueParticipantLineupRoundDetail? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ll = context.leagueL10n;
    final style = _RoundStatusStyle.fromRound(row, colorScheme, ll);
    final showPoints = leagueJornadaShowsFantasyPoints(row.estadoJornada);
    final points = detail?.puntosTotales ?? row.puntosTotales;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                row.isInProgress
                    ? ll.roundInProgressMatchday
                    : ll.matchdayShort(row.numeroJornada),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: style.foreground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.isInProgress
                        ? ll.roundInProgressMatchday
                        : ll.matchday(row.numeroJornada),
                    style: theme.textTheme.titleSmall?.copyWith(
                      ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    style.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: style.foreground,
                    ),
                  ),
                  if (row.inicioJornada != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${LeagueSpanishDateTime.formatDateLong(row.inicioJornada)} · ${LeagueSpanishDateTime.formatTimeHm(row.inicioJornada)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showPoints)
              Text(
                '${points.toStringAsFixed(points % 1 == 0 ? 0 : 1)} pts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: row.isInProgress
                      ? colorScheme.tertiary
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundStatusStyle {
  const _RoundStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  factory _RoundStatusStyle.fromRound(
    LeagueParticipantLineupRoundSummary row,
    ColorScheme colorScheme,
    LeagueL10n ll,
  ) {
    if (row.isPending) {
      return _RoundStatusStyle(
        label: ll.roundPending,
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.onSurfaceVariant,
      );
    }
    if (row.isInProgress) {
      return _RoundStatusStyle(
        label: ll.roundInProgress,
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      );
    }
    return _RoundStatusStyle(
      label: ll.roundFinished,
      background: colorScheme.primaryContainer,
      foreground: colorScheme.onPrimaryContainer,
    );
  }
}

class _RoundEmptyState extends StatelessWidget {
  const _RoundEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.leagueL10n.noLineupSaved,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundErrorState extends StatelessWidget {
  const _RoundErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.leagueL10n.couldNotLoadLineup,
              style: theme.textTheme.titleSmall?.copyWith(
                ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchSection extends StatelessWidget {
  const _BenchSection({
    required this.players,
    required this.showJornadaPitchBadges,
    this.onPlayerTap,
  });

  final List<LeagueParticipantLineupRoundPlayer> players;
  final bool showJornadaPitchBadges;
  final void Function(LeagueParticipantLineupRoundPlayer player)? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final byRole = <String, List<LeagueParticipantLineupRoundPlayer>>{
      'POR': [],
      'DEF': [],
      'MC': [],
      'DEL': [],
    };
    for (final p in players) {
      final pos = p.posicion.trim().toUpperCase();
      final normalized = switch (pos) {
        'POR' || 'GK' => 'POR',
        'DEF' || 'DF' => 'DEF',
        'MC' || 'MED' || 'MID' => 'MC',
        'DEL' || 'FW' || 'DC' => 'DEL',
        _ => 'MC',
      };
      byRole[normalized]!.add(p);
    }
    final ll = context.leagueL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ll.benchLabel,
          style: theme.textTheme.titleSmall?.copyWith(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _benchCell(context, colorScheme, 'POR', byRole['POR']!, showJornadaPitchBadges),
            const SizedBox(width: 8),
            _benchCell(context, colorScheme, 'DEF', byRole['DEF']!, showJornadaPitchBadges),
            const SizedBox(width: 8),
            _benchCell(context, colorScheme, 'MC', byRole['MC']!, showJornadaPitchBadges),
            const SizedBox(width: 8),
            _benchCell(context, colorScheme, 'DEL', byRole['DEL']!, showJornadaPitchBadges),
          ],
        ),
      ],
    );
  }

  Widget _benchCell(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    List<LeagueParticipantLineupRoundPlayer> items,
    bool showJornadaPitchBadges,
  ) {
    final theme = Theme.of(context);
    final player = items.isEmpty ? null : items.first;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: player == null
                ? const SizedBox(width: 44, height: 76)
                : _HistoryBenchPlayerBubble(
                    player: player,
                    showJornadaPitchBadges: showJornadaPitchBadges,
                    onTap: onPlayerTap == null
                        ? null
                        : () => onPlayerTap!(player),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBenchPlayerBubble extends StatelessWidget {
  const _HistoryBenchPlayerBubble({
    required this.player,
    required this.showJornadaPitchBadges,
    this.onTap,
  });

  final LeagueParticipantLineupRoundPlayer player;
  final bool showJornadaPitchBadges;
  final VoidCallback? onTap;

  String get _displayName {
    final preferred = player.nombreMostrado.trim().isNotEmpty
        ? player.nombreMostrado.trim()
        : player.pila.trim().isNotEmpty
        ? player.pila.trim()
        : player.nombre.trim();
    if (preferred.length <= 10) {
      return preferred;
    }
    return '${preferred.substring(0, 9)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointsBadge = leagueRoundPlayerPitchBadgeText(
      player,
      showJornadaPitchBadges,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                    child: LeaguePlayerAvatar(
                      player: player.toSquadPlayer(),
                      size: 44,
                      circular: true,
                    ),
                  ),
                  if (pointsBadge.isNotEmpty)
                    Positioned(
                      left: -4,
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        child: Text(
                          pointsBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  if (showJornadaPitchBadges &&
                      player.fantasyBanquilloContandoPorSuplencia)
                    Positioned(
                      right: -6,
                      top: -8,
                      child: LeagueRoundFantasySubstitutionBadge(
                        message: context.leagueL10n.starterSubstitutionHint,
                        iconSize: 12,
                        padding: const EdgeInsets.all(2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

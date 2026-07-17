import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/league_round_standing_row.dart';
import 'package:eternal_xi/data/models/league_standing_row.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/utils/league_jornada_points_display.dart';
import 'package:eternal_xi/features/leagues/widgets/league_standing_row_card.dart';
import 'package:eternal_xi/features/profile/navigation/user_profile_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueTabStandings extends StatefulWidget {
  const LeagueTabStandings({super.key});

  @override
  State<LeagueTabStandings> createState() => _LeagueTabStandingsState();
}

class _LeagueTabStandingsState extends State<LeagueTabStandings>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<LeagueStandingRow>? _globalRows;
  List<LeagueRoundSummary> _playedRounds = const [];
  List<LeagueRoundStandingRow>? _roundRows;
  int? _selectedJornadaId;

  bool _loading = true;
  bool _roundLoading = false;
  String? _error;
  String? _roundError;
  int? _handledRefreshGeneration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    final gen = shell.refreshGeneration;
    if (_handledRefreshGeneration == null) {
      _handledRefreshGeneration = gen;
      return;
    }
    if (gen != _handledRefreshGeneration) {
      _handledRefreshGeneration = gen;
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.leagueContextError;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final results = await Future.wait([
        api.getStandings(idLiga: shell.leagueId, idUsuario: shell.idUsuario),
        api.getLeagueRounds(idLiga: shell.leagueId, idUsuario: shell.idUsuario),
      ]);
      if (!mounted) {
        return;
      }
      final rounds = results[1] as List<LeagueRoundSummary>;
      final played = rounds
          .where(
            (LeagueRoundSummary r) => leagueRoundSummaryIsSelectableInStandings(
              finalizada: r.finalizada,
              estado: r.estado,
              actual: r.actual,
            ),
          )
          .toList()
        ..sort(
          (a, b) => leagueRoundSummarySortWeight(
            finalizada: b.finalizada,
            estado: b.estado,
            actual: b.actual,
            numero: b.numero,
          ).compareTo(
            leagueRoundSummarySortWeight(
              finalizada: a.finalizada,
              estado: a.estado,
              actual: a.actual,
              numero: a.numero,
            ),
          ),
        );

      setState(() {
        _globalRows = results[0] as List<LeagueStandingRow>;
        _playedRounds = played;
        _loading = false;
        if (_selectedJornadaId != null &&
            !played.any((r) => r.id == _selectedJornadaId)) {
          _selectedJornadaId = null;
          _roundRows = null;
        }
      });

      if (_selectedJornadaId != null) {
        await _loadRoundStandings(_selectedJornadaId!);
      }
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

  Future<void> _loadRoundStandings(int idJornada) async {
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      return;
    }
    setState(() {
      _roundLoading = true;
      _roundError = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final rows = await api.getRoundStandings(
        idLiga: shell.leagueId,
        idJornada: idJornada,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _roundRows = rows;
        _roundLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _roundError = e.toString().replaceFirst('Exception: ', '');
        _roundLoading = false;
      });
    }
  }

  Future<void> _onJornadaChanged(int? idJornada) async {
    setState(() {
      _selectedJornadaId = idJornada;
      _roundRows = null;
      _roundError = null;
    });
    if (idJornada != null) {
      await _loadRoundStandings(idJornada);
    }
  }

  String _standingsViewLabel(LeagueL10n ll) {
    if (_selectedJornadaId == null) {
      return ll.globalStandings;
    }
    for (final round in _playedRounds) {
      if (round.id != _selectedJornadaId) {
        continue;
      }
      if (leagueJornadaIsInProgress(round.estado) || round.actual) {
        return ll.roundInProgressMatchday;
      }
      return round.numero > 0 ? ll.matchday(round.numero) : round.nombre;
    }
    return ll.globalStandings;
  }

  void _openPeer({
    required LeagueShellData shell,
    required int idUsuario,
    required int idLigaParticipante,
    required String nickname,
  }) {
    if (idUsuario == shell.idUsuario) {
      shell.openSquad(segment: 0);
      return;
    }
    LeagueInnerNavigation.openParticipantSquad(
      context: context,
      leagueId: shell.leagueId,
      idUsuarioViewer: shell.idUsuario,
      idUsuarioTarget: idUsuario,
      idLigaParticipante: idLigaParticipante,
      nickname: nickname,
    );
  }

  void _openProfile({
    required int idUsuario,
    required String nickname,
  }) {
    if (idUsuario <= 0) {
      return;
    }
    UserProfileNavigation.openPublicProfile(
      context,
      userId: idUsuario,
      nicknameHint: nickname,
    );
  }

  LeagueStandingRow _roundAsGlobalRow(LeagueRoundStandingRow round) {
    return LeagueStandingRow(
      posicion: round.posicion,
      idLigaParticipante: round.idLigaParticipante,
      idUsuario: round.idUsuario,
      nickname: round.nickname,
      puntosTotales: round.puntosFantasyJornada.toDouble(),
      dinero: 0,
      valorTotalEquipo: round.valorTotalEquipo,
      admin: round.admin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ll = context.leagueL10n;
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shell = LeagueShellData.maybeOf(context);
    final viewingRound = _selectedJornadaId != null;
    final listLoading = _loading || (viewingRound && _roundLoading);

    return RefreshIndicator(
      onRefresh: () async {
        final s = LeagueShellData.maybeOf(context);
        if (s != null) {
          await s.reload();
        }
      },
      child: CustomScrollView(
        key: const PageStorageKey<String>('league_tab_standings'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.standings,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      ),
                  ),
                  if (_playedRounds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _StandingsViewPicker(
                      label: ll.viewLabel,
                      enabled: !_loading,
                      selectedId: _selectedJornadaId,
                      selectedLabel: _standingsViewLabel(ll),
                      options: [
                        (null, ll.globalStandings),
                        for (final round in _playedRounds)
                          (
                            round.id,
                            leagueJornadaIsInProgress(round.estado) ||
                                    round.actual
                                ? ll.roundInProgressMatchday
                                : round.numero > 0
                                ? ll.matchday(round.numero)
                                : round.nombre,
                          ),
                      ],
                      onSelected: _onJornadaChanged,
                    ),
                    if (viewingRound)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          ll.roundStandingsHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (listLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!viewingRound && _error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StandingsError(
                message: _error!,
                onRetry: _load,
                colorScheme: colorScheme,
                theme: theme,
              ),
            )
          else if (viewingRound && _roundError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StandingsError(
                message: _roundError!,
                onRetry: () => _loadRoundStandings(_selectedJornadaId!),
                colorScheme: colorScheme,
                theme: theme,
              ),
            )
          else if (!viewingRound && (_globalRows == null || _globalRows!.isEmpty))
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StandingsEmpty(colorScheme: colorScheme, theme: theme),
            )
          else if (viewingRound && (_roundRows == null || _roundRows!.isEmpty))
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  ll.noRoundStandingsData,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (!viewingRound) {
                    final row = _globalRows![index];
                    final isMe =
                        shell != null && row.idUsuario == shell.idUsuario;
                    return LeagueStandingRowCard(
                      row: row,
                      isFirstPlace: row.posicion == 1,
                      isCurrentUser: isMe,
                      onAvatarTap: row.idUsuario <= 0
                          ? null
                          : () => _openProfile(
                              idUsuario: row.idUsuario,
                              nickname: row.nickname,
                            ),
                      onPeerTap: shell == null || row.idUsuario <= 0
                          ? null
                          : () => _openPeer(
                              shell: shell,
                              idUsuario: row.idUsuario,
                              idLigaParticipante: row.idLigaParticipante,
                              nickname: row.nickname,
                            ),
                    );
                  }

                  final roundRow = _roundRows![index];
                  final row = _roundAsGlobalRow(roundRow);
                  final isMe =
                      shell != null && row.idUsuario == shell.idUsuario;
                  final selectedIdx = _playedRounds.indexWhere(
                    (r) => r.id == _selectedJornadaId,
                  );
                  final selectedRound = selectedIdx >= 0
                      ? _playedRounds[selectedIdx]
                      : null;
                  return LeagueStandingRowCard(
                    row: row,
                    isFirstPlace: roundRow.posicion == 1,
                    isCurrentUser: isMe,
                    puntosFantasyJornada: roundRow.puntosFantasyJornada,
                    puntosRecompensaJornada: roundRow.puntosRecompensaJornada,
                    showRoundFantasyPoints: true,
                    showRoundRewardPoints: selectedRound != null &&
                        leagueJornadaShowsGrantedPoints(selectedRound.estado),
                    onAvatarTap: row.idUsuario <= 0
                        ? null
                        : () => _openProfile(
                            idUsuario: row.idUsuario,
                            nickname: row.nickname,
                          ),
                    onPeerTap: shell == null || row.idUsuario <= 0
                        ? null
                        : () => _openPeer(
                            shell: shell,
                            idUsuario: row.idUsuario,
                            idLigaParticipante: row.idLigaParticipante,
                            nickname: row.nickname,
                          ),
                  );
                }, childCount: viewingRound ? _roundRows!.length : _globalRows!.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandingsError extends StatelessWidget {
  const _StandingsError({
    required this.message,
    required this.onRetry,
    required this.colorScheme,
    required this.theme,
  });

  final String message;
  final VoidCallback onRetry;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
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

class _StandingsEmpty extends StatelessWidget {
  const _StandingsEmpty({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_list_numbered_outlined,
            size: 52,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            ll.noStandingsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ll.noStandingsYetHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Selector de vista (global / jornada) con menú opaco (sin IndexedStack transparente).
class _StandingsViewPicker extends StatelessWidget {
  const _StandingsViewPicker({
    required this.label,
    required this.selectedLabel,
    required this.selectedId,
    required this.options,
    required this.onSelected,
    required this.enabled,
  });

  final String label;
  final String selectedLabel;
  final int? selectedId;
  final List<(int?, String)> options;
  final ValueChanged<int?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // scheme.surface es transparente en Fantasy (fondo estadio); el sheet debe ser opaco.
    const sheetBg = XiColors.surfaceElevated;

    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              await showModalBottomSheet<void>(
                context: context,
                backgroundColor: sheetBg,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (sheetContext) {
                  final optionStyle = XiTypography.lumiare(
                    fontSize: 16,
                    height: 1.35,
                    letterSpacing: 0.2,
                    color: XiColors.warmWhite,
                  );
                  return Material(
                    color: sheetBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              label,
                              style: XiTypography.lumiare(
                                fontSize: 18,
                                letterSpacing: 0.3,
                                color: XiColors.warmWhite,
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final option in options)
                                  Builder(
                                    builder: (_) {
                                      final selected =
                                          option.$1 == selectedId;
                                      return ListTile(
                                        selected: selected,
                                        selectedTileColor: XiColors.royalBlue
                                            .withValues(alpha: 0.28),
                                        title: Text(
                                          option.$2,
                                          style: optionStyle.copyWith(
                                            color: selected
                                                ? XiColors.iceBlue
                                                : XiColors.warmWhite,
                                          ),
                                        ),
                                        trailing: selected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: XiColors.iceBlue,
                                              )
                                            : null,
                                        onTap: () {
                                          Navigator.of(sheetContext).pop();
                                          onSelected(option.$1);
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: Icon(
            Icons.expand_more_rounded,
            color: scheme.onSurfaceVariant,
          ),
        ),
        child: Text(
          selectedLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}


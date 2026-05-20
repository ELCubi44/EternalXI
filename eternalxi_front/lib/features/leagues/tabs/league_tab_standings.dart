import 'package:eternal_xi/data/models/league_standing_row.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_squad.dart';
import 'package:eternal_xi/features/leagues/widgets/league_standing_row_card.dart';
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

  List<LeagueStandingRow>? _rows;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final shell = LeagueShellData.maybeOf(context);
    if (shell == null) {
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el contexto de la liga.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<LeaguesApiService>();
      final list = await api.getStandings(
        idLiga: shell.leagueId,
        idUsuario: shell.idUsuario,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = list;
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shell = LeagueShellData.maybeOf(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        key: const PageStorageKey<String>('league_tab_standings'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Clasificación',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StandingsError(
                message: _error!,
                onRetry: _load,
                colorScheme: colorScheme,
                theme: theme,
              ),
            )
          else if (_rows == null || _rows!.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StandingsEmpty(colorScheme: colorScheme, theme: theme),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final row = _rows![index];
                  final isFirst = row.posicion == 1;
                  final isMe =
                      shell != null && row.idUsuario == shell.idUsuario;
                  return LeagueStandingRowCard(
                    row: row,
                    isFirstPlace: isFirst,
                    isCurrentUser: isMe,
                    onPeerTap: shell == null || row.idUsuario <= 0
                        ? null
                        : () {
                            if (row.idUsuario == shell.idUsuario) {
                              LeagueTabSquad.externalSegmentRequest.value = 0;
                              shell.selectTab(2);
                              return;
                            }
                            LeagueInnerNavigation.openParticipantSquad(
                              context: context,
                              leagueId: shell.leagueId,
                              idUsuarioViewer: shell.idUsuario,
                              idUsuarioTarget: row.idUsuario,
                              idLigaParticipante: row.idLigaParticipante,
                              nickname: row.nickname,
                            );
                          },
                  );
                }, childCount: _rows!.length),
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
            label: const Text('Reintentar'),
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
            'Sin clasificación todavía',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando haya participantes y puntos, aparecerán aquí en el orden que envíe el servidor.',
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

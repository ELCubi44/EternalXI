import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_team_standing_row.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueTeamStandingsScreen extends StatefulWidget {
  const LeagueTeamStandingsScreen({
    super.key,
    required this.leagueId,
    required this.idUsuario,
  });

  final int leagueId;
  final int idUsuario;

  @override
  State<LeagueTeamStandingsScreen> createState() => _LeagueTeamStandingsScreenState();
}

class _LeagueTeamStandingsScreenState extends State<LeagueTeamStandingsScreen> {
  List<LeagueTeamStandingRow> _rows = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<LeaguesApiService>();
      final rows = await api.getTeamStandings(
        idLiga: widget.leagueId,
        idUsuario: widget.idUsuario,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = rows;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ll = context.leagueL10n;
    return Scaffold(
      appBar: AppBar(title: Text(ll.teamStandingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                Card(
                  elevation: 0,
                  color: colorScheme.errorContainer.withValues(alpha: 0.25),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 42),
                  child: Text(
                    ll.noTeamStandingsYet,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: RefreshIndicator(
                onRefresh: _load,
                child: _TeamStandingsTable(
                  rows: _rows,
                  onOpenTeamPlayers: (row) =>
                      LeagueInnerNavigation.openCatalogTeamSquad(
                    context: context,
                    idEquipo: row.idEquipo,
                    nombreEquipo: row.nombreEquipo.trim().isEmpty
                        ? null
                        : row.nombreEquipo.trim(),
                    fotoEquipo: row.resolvedFotoEquipoUrl(),
                    idLiga: widget.leagueId,
                    idUsuario: widget.idUsuario,
                  ),
                ),
              ),
            ),
    );
  }
}

class _TeamStandingsTable extends StatelessWidget {
  const _TeamStandingsTable({
    required this.rows,
    required this.onOpenTeamPlayers,
  });

  final List<LeagueTeamStandingRow> rows;
  final void Function(LeagueTeamStandingRow row) onOpenTeamPlayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: [
                  _TeamStandingsHeader(colorScheme: colorScheme, theme: theme),
                  const SizedBox(height: 8),
                  for (final row in rows)
                    _TeamStandingsRow(
                      row: row,
                      onOpenTeamPlayers: onOpenTeamPlayers,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamStandingsHeader extends StatelessWidget {
  const _TeamStandingsHeader({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _th('#', 30),
            _th(ll.teamColumn, 212, alignLeft: true),
            _th('PJ', 34),
            _th('G', 28),
            _th('E', 28),
            _th('P', 28),
            _th('GF', 34),
            _th('GC', 34),
            _th('DG', 36),
            _th('PTS', 40, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _th(
    String label,
    double width, {
    bool bold = false,
    bool alignLeft = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: alignLeft ? TextAlign.left : TextAlign.right,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _TeamStandingsRow extends StatelessWidget {
  const _TeamStandingsRow({
    required this.row,
    required this.onOpenTeamPlayers,
  });

  final LeagueTeamStandingRow row;
  final void Function(LeagueTeamStandingRow row) onOpenTeamPlayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamName = row.nombreEquipo.trim();
    final ll = context.leagueL10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        children: [
          _td('${row.posicion}', 30, theme: theme),
          SizedBox(
            width: 212,
            child: Row(
              children: [
                if (row.idEquipo > 0)
                  Semantics(
                    button: true,
                    label: teamName.isEmpty
                        ? ll.seeTeam
                        : ll.seeTeamColon(teamName),
                    child: Tooltip(
                      message: teamName.isEmpty
                          ? ll.seeTeam
                          : ll.seeTeamNamed(teamName),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onOpenTeamPlayers(row),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: LeagueTeamLogo(
                                idEquipo: row.idEquipo,
                                size: 20,
                                networkImageUrl: row.resolvedFotoEquipoUrl(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  LeagueTeamLogo(
                    idEquipo: row.idEquipo,
                    size: 20,
                    networkImageUrl: row.resolvedFotoEquipoUrl(),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    row.nombreEquipo.trim().isEmpty ? '—' : row.nombreEquipo.trim(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      ),
                  ),
                ),
              ],
            ),
          ),
          _td('${row.partidosJugados}', 34, theme: theme),
          _td('${row.partidosGanados}', 28, theme: theme),
          _td('${row.partidosEmpatados}', 28, theme: theme),
          _td('${row.partidosPerdidos}', 28, theme: theme),
          _td('${row.golesFavor}', 34, theme: theme),
          _td('${row.golesContra}', 34, theme: theme),
          _td(_dg(row.diferenciaGoles), 36, theme: theme),
          _td('${row.puntos}', 40, theme: theme, bold: true),
        ],
      ),
    );
  }

  String _dg(int value) => value > 0 ? '+$value' : '$value';

  Widget _td(
    String text,
    double width, {
    required ThemeData theme,
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

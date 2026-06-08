import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_listed_player.dart';
import 'package:eternal_xi/data/models/league_market_team_summary.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/screens/league_market_team_detail_screen.dart';
import 'package:eternal_xi/features/leagues/utils/league_nav_refresh.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Listado de equipos a partir del endpoint global de mercado de la liga.
class LeagueMarketTeamListScreen extends StatefulWidget {
  const LeagueMarketTeamListScreen({
    super.key,
    required this.idLiga,
    required this.idUsuarioViewer,
  });

  final int idLiga;
  final int idUsuarioViewer;

  @override
  State<LeagueMarketTeamListScreen> createState() =>
      _LeagueMarketTeamListScreenState();
}

class _LeagueMarketTeamListScreenState
    extends State<LeagueMarketTeamListScreen> {
  List<LeagueMarketTeamSummary>? _teams;
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
      final rows = await api.getLeagueMarketPlayers(
        idLiga: widget.idLiga,
        idUsuario: widget.idUsuarioViewer,
      );
      if (!mounted) {
        return;
      }
      final flat = rows
          .map((LeagueSquadPlayer r) => LeagueListedPlayer(squadPlayer: r))
          .toList();
      setState(() {
        _teams = buildLeagueMarketTeamSummaries(flat);
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

  static String _formatMedia(double v) {
    if (v.isNaN || v.isInfinite) {
      return '—';
    }
    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ll = context.leagueL10n;
    return Scaffold(
      appBar: AppBar(title: Text(ll.teamListTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
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
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                  ),
                ],
              )
            : (_teams == null || _teams!.isEmpty)
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: 52,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ll.noPlayersInLeague,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ll.emptyGlobalMarketList,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _teams!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = _teams![i];
                  return _TeamListTile(
                    summary: t,
                    mediaLabel: _formatMedia(t.averageValoracion),
                    onTap: () async {
                      await leagueAfterPush(
                        context,
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (ctx) => LeagueMarketTeamDetailScreen(
                              summary: t,
                              leagueId: widget.idLiga,
                              idUsuarioViewer: widget.idUsuarioViewer,
                            ),
                          ),
                        ),
                        _load,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _TeamListTile extends StatelessWidget {
  const _TeamListTile({
    required this.summary,
    required this.mediaLabel,
    required this.onTap,
  });

  final LeagueMarketTeamSummary summary;
  final String mediaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              LeagueTeamLogo(
                idEquipo: summary.idEquipo,
                size: 44,
                networkImageUrl: summary.resolvedTeamBadgeUrl(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.nombreEquipo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.players.length} jugadores en la liga',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Media',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mediaLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

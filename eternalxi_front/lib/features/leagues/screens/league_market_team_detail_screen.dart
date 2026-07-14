import 'package:eternal_xi/data/models/league_listed_player.dart';
import 'package:eternal_xi/data/models/league_market_team_summary.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_market_sort.dart';
import 'package:eternal_xi/features/leagues/widgets/league_market_player_buy_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Detalle de un equipo en el mercado: compra directa por jugador (datos siempre frescos).
class LeagueMarketTeamDetailScreen extends StatefulWidget {
  const LeagueMarketTeamDetailScreen({
    super.key,
    required this.summary,
    required this.leagueId,
    required this.idUsuarioViewer,
  });

  final LeagueMarketTeamSummary summary;
  final int leagueId;
  final int idUsuarioViewer;

  @override
  State<LeagueMarketTeamDetailScreen> createState() =>
      _LeagueMarketTeamDetailScreenState();
}

class _LeagueMarketTeamDetailScreenState
    extends State<LeagueMarketTeamDetailScreen> {
  List<LeagueListedPlayer> _players = const [];
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
        idLiga: widget.leagueId,
        idUsuario: widget.idUsuarioViewer,
      );
      if (!mounted) {
        return;
      }
      final teamPlayers = rows
          .where((LeagueSquadPlayer p) => p.idEquipo == widget.summary.idEquipo)
          .map((LeagueSquadPlayer r) => LeagueListedPlayer(squadPlayer: r))
          .toList()
        ..sort(compareLeagueListedPlayersMarketOrder);
      setState(() {
        _players = teamPlayers;
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
    final summary = widget.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          summary.nombreEquipo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      LeagueTeamLogo(
                        idEquipo: summary.idEquipo,
                        size: 48,
                        networkImageUrl: summary.resolvedTeamBadgeUrl(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.nombreEquipo,
                              style: theme.textTheme.titleLarge?.copyWith(
                                ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_players.length} jugadores',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Compra directa',
                    style: theme.textTheme.titleSmall?.copyWith(
                      ),
                  ),
                  const SizedBox(height: 10),
                  if (_players.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No hay jugadores disponibles de este equipo en el mercado.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._players.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LeagueMarketPlayerBuyCard(
                          player: e.squadPlayer,
                          idLiga: widget.leagueId,
                          idUsuario: widget.idUsuarioViewer,
                          onAfterAction: _load,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

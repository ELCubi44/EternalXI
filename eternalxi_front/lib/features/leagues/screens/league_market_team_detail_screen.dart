import 'package:eternal_xi/data/models/league_market_team_summary.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_market_sort.dart';
import 'package:eternal_xi/features/leagues/widgets/league_market_player_buy_card.dart';
import 'package:eternal_xi/features/leagues/widgets/league_team_logo.dart';
import 'package:flutter/material.dart';

/// Detalle de un equipo en el mercado: compra directa por jugador.
class LeagueMarketTeamDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sorted = [...summary.players]
      ..sort(compareLeagueListedPlayersMarketOrder);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          summary.nombreEquipo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sorted.length} jugadores',
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...sorted.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LeagueMarketPlayerBuyCard(
                player: e.squadPlayer,
                idLiga: leagueId,
                idUsuario: idUsuarioViewer,
                onAfterAction: () async {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

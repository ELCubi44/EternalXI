import 'package:eternal_xi/data/models/league_listed_player.dart';

/// Resumen de un club real dentro de la liga (agrupación por `idEquipo`).
class LeagueMarketTeamSummary {
  const LeagueMarketTeamSummary({
    required this.idEquipo,
    required this.nombreEquipo,
    required this.averageValoracion,
    required this.players,
  });

  final int idEquipo;
  final String nombreEquipo;

  /// Media aritmética de [LeagueSquadPlayer.valoracion] de los jugadores del equipo
  /// en el conjunto agregado (solo valores finitos).
  final double averageValoracion;
  final List<LeagueListedPlayer> players;

  /// Primera URL de escudo devuelta por el API (`fotoEquipo`), si existe.
  String? resolvedTeamBadgeUrl() {
    for (final e in players) {
      final u = e.squadPlayer.resolvedFotoEquipoUrl();
      if (u != null) {
        return u;
      }
    }
    return null;
  }
}

String _nombreEquipoPreferido(List<LeagueListedPlayer> list) {
  for (final e in list) {
    final n = e.squadPlayer.nombreEquipo.trim();
    if (n.isNotEmpty) {
      return n;
    }
  }
  return 'Equipo';
}

/// Agrupa jugadores del listado global por `idEquipo`, calcula media de valoración y ordena por nombre.
List<LeagueMarketTeamSummary> buildLeagueMarketTeamSummaries(
  List<LeagueListedPlayer> all,
) {
  final map = <int, List<LeagueListedPlayer>>{};
  for (final e in all) {
    final id = e.squadPlayer.idEquipo;
    map.putIfAbsent(id, () => []).add(e);
  }
  final out = <LeagueMarketTeamSummary>[];
  for (final entry in map.entries) {
    final list = [...entry.value];
    var sum = 0.0;
    var n = 0;
    for (final e in list) {
      final v = e.squadPlayer.valoracion;
      if (!v.isNaN && !v.isInfinite) {
        sum += v;
        n++;
      }
    }
    final avg = n == 0 ? 0.0 : sum / n;
    list.sort((a, b) => b.squadPlayer.valor.compareTo(a.squadPlayer.valor));
    out.add(
      LeagueMarketTeamSummary(
        idEquipo: entry.key,
        nombreEquipo: _nombreEquipoPreferido(list),
        averageValoracion: avg,
        players: list,
      ),
    );
  }
  out.sort((a, b) => a.nombreEquipo.compareTo(b.nombreEquipo));
  return out;
}

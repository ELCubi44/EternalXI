import 'package:eternal_xi/data/models/league_squad_player.dart';

/// Jugador en un listado de liga (mercado / listado global) con datos de plantilla.
class LeagueListedPlayer {
  const LeagueListedPlayer({required this.squadPlayer});

  final LeagueSquadPlayer squadPlayer;

  /// Propietario según backend (`nombreDuenoVisible`). Sin inferencias en cliente.
  String ownerDisplayLabel() {
    final v = squadPlayer.nombreDuenoVisible.trim();
    if (v.isNotEmpty) {
      return v;
    }
    return '—';
  }
}

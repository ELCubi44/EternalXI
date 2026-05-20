import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:flutter/material.dart';

/// Ranura de un jugador en la plantilla.
///
/// Hoy solo envuelve [child] para mantener un punto único donde enlazar
/// `ReorderableDragStartListener`, `LongPressDraggable` o lógica de banquillo
/// sin reescribir toda la lista.
class LeagueSquadPlayerSlot extends StatelessWidget {
  const LeagueSquadPlayerSlot({
    super.key,
    required this.player,
    required this.child,
  });

  final LeagueSquadPlayer player;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: ValueKey<int>(player.idLigaJugador), child: child);
  }
}

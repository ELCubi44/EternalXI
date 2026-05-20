import 'package:eternal_xi/data/models/league_listed_player.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/squad/league_squad_position_bucket.dart';

/// Orden de mercado / detalle de equipo: POR → DEF → MED → DEL → otros;
/// dentro de cada bloque: valoración desc., luego valor económico desc.
int _positionBucketOrder(LeagueSquadPlayer p) {
  final line = LeagueSquadPositionBucket.forPosition(p.posicion);
  switch (line) {
    case LeagueSquadLine.porteros:
      return 0;
    case LeagueSquadLine.defensas:
      return 1;
    case LeagueSquadLine.mediocentros:
      return 2;
    case LeagueSquadLine.delanteros:
      return 3;
    case LeagueSquadLine.otros:
      return 4;
  }
}

int compareLeagueSquadPlayersMarketOrder(
  LeagueSquadPlayer a,
  LeagueSquadPlayer b,
) {
  final oa = _positionBucketOrder(a);
  final ob = _positionBucketOrder(b);
  if (oa != ob) {
    return oa.compareTo(ob);
  }
  final ra = a.valoracion;
  final rb = b.valoracion;
  if (ra != rb) {
    return rb.compareTo(ra);
  }
  return b.valor.compareTo(a.valor);
}

int compareLeagueListedPlayersMarketOrder(
  LeagueListedPlayer a,
  LeagueListedPlayer b,
) {
  return compareLeagueSquadPlayersMarketOrder(a.squadPlayer, b.squadPlayer);
}

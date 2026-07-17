import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_estado_titularidad.dart';
import 'package:eternal_xi/features/leagues/utils/league_player_visible_estado.dart';

/// Ranking inteligente para Completar alineacin Fantasy.
///
/// Prioridad:
/// 1. Disponibles / duda antes que lesionados o sancionados.
/// 2. Jugadores del club del entrenador activo (bonus).
/// 3. Mayor % de titularidad (un 7% activo gana a un lesionado).
/// 4. Valoracin y valor de mercado.
abstract final class LeagueLineupAutofillRank {
  /// 0 = puede jugar (DISPONIBLE u otro no bloqueado).
  /// 1 = DUDA.
  /// 2 = LESIONADO / SANCIONADO (ltimo recurso).
  static int availabilityTier(LeagueSquadPlayer player) {
    final estado = leaguePlayerEffectiveEstado(
      estado: player.estado,
      estadoVisible: player.estadoVisible,
    );
    if (leaguePlayerEstadoIsLesionado(estado) ||
        leaguePlayerEstadoIsSancionado(estado)) {
      return 2;
    }
    if (leaguePlayerEstadoNormalized(estado) == 'DUDA') {
      return 1;
    }
    return 0;
  }

  static bool isUnavailable(LeagueSquadPlayer player) =>
      availabilityTier(player) >= 2;

  static bool isCoachClubPlayer(
    LeagueSquadPlayer player, {
    required bool coachActive,
    int? coachTeamId,
  }) {
    if (!coachActive || coachTeamId == null || coachTeamId <= 0) {
      return false;
    }
    return player.idEquipo == coachTeamId;
  }

  /// % efectivo para ordenar: null ? 0. Los no disponibles ya van en tier peor.
  static int playProbabilityScore(LeagueSquadPlayer player) {
    if (isUnavailable(player)) {
      return player.probabilidadTitular ?? 0;
    }
    return player.probabilidadTitular ?? 0;
  }

  static int compare(
    LeagueSquadPlayer a,
    LeagueSquadPlayer b, {
    required bool coachActive,
    int? coachTeamId,
  }) {
    final tierA = availabilityTier(a);
    final tierB = availabilityTier(b);
    if (tierA != tierB) {
      return tierA.compareTo(tierB);
    }

    final coachA = isCoachClubPlayer(
      a,
      coachActive: coachActive,
      coachTeamId: coachTeamId,
    );
    final coachB = isCoachClubPlayer(
      b,
      coachActive: coachActive,
      coachTeamId: coachTeamId,
    );
    if (coachA != coachB) {
      return coachA ? -1 : 1;
    }

    final pa = playProbabilityScore(a);
    final pb = playProbabilityScore(b);
    if (pa != pb) {
      return pb.compareTo(pa);
    }

    final va = a.valoracion;
    final vb = b.valoracion;
    if (va != vb) {
      return vb.compareTo(va);
    }

    return b.valor.compareTo(a.valor);
  }

  /// Elige hasta [needed] jugadores: primero activos (y duda), y solo si faltan
  /// huecos y [allowUnavailable] rellena con lesionados/sancionados.
  static List<LeagueSquadPlayer> pickBest({
    required Iterable<LeagueSquadPlayer> pool,
    required int needed,
    required bool coachActive,
    int? coachTeamId,
    Set<int> excludeIds = const {},
    bool allowUnavailable = true,
  }) {
    if (needed <= 0) {
      return const [];
    }
    int cmp(LeagueSquadPlayer a, LeagueSquadPlayer b) => compare(
      a,
      b,
      coachActive: coachActive,
      coachTeamId: coachTeamId,
    );

    final available = <LeagueSquadPlayer>[];
    final unavailable = <LeagueSquadPlayer>[];
    for (final p in pool) {
      if (excludeIds.contains(p.idLigaJugador)) {
        continue;
      }
      if (isUnavailable(p)) {
        unavailable.add(p);
      } else {
        available.add(p);
      }
    }
    available.sort(cmp);
    unavailable.sort(cmp);

    final out = <LeagueSquadPlayer>[];
    for (final p in available) {
      if (out.length >= needed) {
        break;
      }
      out.add(p);
    }
    if (allowUnavailable && out.length < needed) {
      for (final p in unavailable) {
        if (out.length >= needed) {
          break;
        }
        out.add(p);
      }
    }
    return out;
  }
}

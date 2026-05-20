import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';

class CoachRouletteSpinResult {
  const CoachRouletteSpinResult({
    required this.alreadyUsed,
    required this.entrenadorGanador,
    required this.itemsRuleta,
    required this.costeRuleta,
    required this.puntosRestantes,
  });

  final bool alreadyUsed;
  final RewardCoachItem? entrenadorGanador;
  final List<RewardCoachItem> itemsRuleta;
  final int costeRuleta;
  final int? puntosRestantes;

  factory CoachRouletteSpinResult.fromJson(Map<String, dynamic> json) {
    final winnerRaw = json['entrenadorGanador'] ?? json['entrenador_ganador'];
    RewardCoachItem? winner;
    if (winnerRaw is Map) {
      final m = winnerRaw is Map<String, dynamic>
          ? winnerRaw
          : Map<String, dynamic>.from(winnerRaw);
      if (readLeagueInt(m, const ['idEntrenador', 'id_entrenador']) > 0) {
        winner = RewardCoachItem.fromJson(m);
      }
    }

    final items = <RewardCoachItem>[];
    final listRaw = json['itemsRuleta'] ?? json['items_ruleta'];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is! Map) {
          continue;
        }
        final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        if (readLeagueInt(m, const ['idEntrenador', 'id_entrenador']) > 0) {
          items.add(RewardCoachItem.fromJson(m));
        }
      }
    }

    int? puntosRest;
    if (json.containsKey('puntosRestantes') && json['puntosRestantes'] != null) {
      puntosRest = readLeagueInt(json, const ['puntosRestantes', 'puntos_restantes']);
    } else if (json.containsKey('puntos_restantes') &&
        json['puntos_restantes'] != null) {
      puntosRest = readLeagueInt(json, const ['puntos_restantes']);
    }

    return CoachRouletteSpinResult(
      alreadyUsed: readLeagueBool(json, const ['alreadyUsed', 'already_used']),
      entrenadorGanador: winner,
      itemsRuleta: items,
      costeRuleta: readLeagueInt(json, const ['costeRuleta', 'coste_ruleta']),
      puntosRestantes: puntosRest,
    );
  }
}

import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';

class RewardPackOpenResult {
  const RewardPackOpenResult({
    required this.packType,
    required this.puntosGastados,
    required this.puntosRestantes,
    required this.dineroGanado,
    required this.nuevoDineroLiga,
    required this.cartaObtenida,
  });

  final String packType;
  final int puntosGastados;
  final int puntosRestantes;
  final int dineroGanado;
  final int nuevoDineroLiga;
  final RewardCardModel cartaObtenida;

  factory RewardPackOpenResult.fromJson(Map<String, dynamic> json) {
    final cardRaw = json['cartaObtenida'] ?? json['carta_obtenida'];
    if (cardRaw is! Map) {
      throw const FormatException('cartaObtenida inválida');
    }
    final cardMap = cardRaw is Map<String, dynamic>
        ? cardRaw
        : Map<String, dynamic>.from(cardRaw);
    return RewardPackOpenResult(
      packType: readLeagueString(json, const ['packType', 'pack_type']),
      puntosGastados: readLeagueInt(json, const [
        'puntosGastados',
        'puntos_gastados',
      ]),
      puntosRestantes: readLeagueInt(json, const [
        'puntosRestantes',
        'puntos_restantes',
      ]),
      dineroGanado: readLeagueInt(json, const ['dineroGanado', 'dinero_ganado']),
      nuevoDineroLiga: readLeagueInt(json, const [
        'nuevoDineroLiga',
        'nuevo_dinero_liga',
      ]),
      cartaObtenida: RewardCardModel.fromJson(cardMap),
    );
  }
}

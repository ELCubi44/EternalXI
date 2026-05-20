import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_pack_model.dart';

class RewardSummaryModel {
  const RewardSummaryModel({
    required this.idLiga,
    required this.idLigaParticipante,
    required this.puntosRecompensaUsuario,
    required this.dineroLiga,
    required this.ruletaEntrenadorUsada,
    required this.costeRuletaEntrenador,
    required this.entrenadorActual,
    required this.cartasDisponibles,
    required this.cartasUsadas,
    required this.sobres,
  });

  final int idLiga;
  final int idLigaParticipante;
  final int puntosRecompensaUsuario;
  final int dineroLiga;
  final bool ruletaEntrenadorUsada;
  final int costeRuletaEntrenador;
  final RewardCoachItem? entrenadorActual;
  final int cartasDisponibles;
  final int cartasUsadas;
  final List<RewardPackModel> sobres;

  bool get showCartasTab => cartasDisponibles > 0 || cartasUsadas > 0;

  factory RewardSummaryModel.fromJson(Map<String, dynamic> json) {
    final coachRaw = json['entrenadorActual'] ?? json['entrenador_actual'];
    RewardCoachItem? coach;
    if (coachRaw is Map) {
      final m = coachRaw is Map<String, dynamic>
          ? coachRaw
          : Map<String, dynamic>.from(coachRaw);
      if (readLeagueInt(m, const ['idEntrenador', 'id_entrenador']) > 0) {
        coach = RewardCoachItem.fromJson(m);
      }
    }

    final packsRaw = json['sobres'] ?? json['packs'];
    final packs = <RewardPackModel>[];
    if (packsRaw is List) {
      for (final e in packsRaw) {
        if (e is! Map) {
          continue;
        }
        final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        packs.add(RewardPackModel.fromJson(m));
      }
    }

    return RewardSummaryModel(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      puntosRecompensaUsuario: readLeagueInt(json, const [
        'puntosRecompensaUsuario',
        'puntos_recompensa_usuario',
      ]),
      dineroLiga: readLeagueInt(json, const ['dineroLiga', 'dinero_liga']),
      ruletaEntrenadorUsada: readLeagueBool(json, const [
        'ruletaEntrenadorUsada',
        'ruleta_entrenador_usada',
      ]),
      costeRuletaEntrenador: readLeagueInt(json, const [
        'costeRuletaEntrenador',
        'coste_ruleta_entrenador',
      ]),
      entrenadorActual: coach,
      cartasDisponibles: readLeagueInt(json, const [
        'cartasDisponibles',
        'cartas_disponibles',
      ]),
      cartasUsadas: readLeagueInt(json, const ['cartasUsadas', 'cartas_usadas']),
      sobres: packs,
    );
  }
}

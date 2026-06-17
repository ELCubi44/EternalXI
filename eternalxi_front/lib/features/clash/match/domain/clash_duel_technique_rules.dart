import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';

/// Reglas de compatibilidad de supertécnicas en duelos (Fase 11).
class ClashDuelTechniqueRules {
  const ClashDuelTechniqueRules._();

  static ClashTechniqueType attackerTechniqueType(ClashDuelType duel) =>
      switch (duel) {
        ClashDuelType.dribbleVsDefense => ClashTechniqueType.dribble,
        ClashDuelType.shotVsSave => ClashTechniqueType.shot,
      };

  static ClashTechniqueType defenderTechniqueType(ClashDuelType duel) =>
      switch (duel) {
        ClashDuelType.dribbleVsDefense => ClashTechniqueType.defense,
        ClashDuelType.shotVsSave => ClashTechniqueType.save,
      };

  static List<ClashSuperTechnique> compatibleForAttacker(
    MatchSquadPlayer player,
    ClashDuelType duel,
  ) {
    final type = attackerTechniqueType(duel);
    return player.superTechniques.where((t) => t.type == type).toList();
  }

  static List<ClashSuperTechnique> compatibleForDefender(
    MatchSquadPlayer player,
    ClashDuelType duel,
  ) {
    final type = defenderTechniqueType(duel);
    return player.superTechniques.where((t) => t.type == type).toList();
  }

  static ClashSuperTechnique? findTechnique(
    MatchSquadPlayer player,
    String? techniqueId,
  ) {
    if (techniqueId == null) {
      return null;
    }
    for (final technique in player.superTechniques) {
      if (technique.id == techniqueId) {
        return technique;
      }
    }
    return null;
  }
}

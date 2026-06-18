import 'clash_card.dart';
import 'clash_card_progress.dart';
import 'clash_position.dart';
import 'clash_skill_tree_definition.dart';
import 'clash_skill_tree_stat.dart';
import 'clash_stats.dart';

/// Bonus planos del árbol de habilidades (Fase 21).
///
/// Se aplican **después** del bonus de rareza evolucionada y del escalado por nivel.
class ClashSkillTreeBonusResolver {
  const ClashSkillTreeBonusResolver._();

  static ClashStats flatBonuses({
    required ClashPosition position,
    required Set<String> unlockedSkillNodeIds,
  }) {
    var save = 0;
    var defense = 0;
    var pass = 0;
    var dribble = 0;
    var shot = 0;
    var techniquePoints = 0;
    var stamina = 0;

    for (final node in ClashSkillTreeDefinition.nodesFor(position)) {
      if (!unlockedSkillNodeIds.contains(node.id)) {
        continue;
      }
      switch (node.stat) {
        case ClashSkillTreeStat.save:
          save += node.boostValue;
        case ClashSkillTreeStat.defense:
          defense += node.boostValue;
        case ClashSkillTreeStat.pass:
          pass += node.boostValue;
        case ClashSkillTreeStat.dribble:
          dribble += node.boostValue;
        case ClashSkillTreeStat.shot:
          shot += node.boostValue;
        case ClashSkillTreeStat.techniquePoints:
          techniquePoints += node.boostValue;
        case ClashSkillTreeStat.stamina:
          stamina += node.boostValue;
      }
    }

    return ClashStats(
      save: save,
      defense: defense,
      pass: pass,
      dribble: dribble,
      shot: shot,
      techniquePoints: techniquePoints,
      stamina: stamina,
    );
  }

  static ClashStats applyTreeBonuses(
    ClashStats scaledStats,
    ClashCard card,
    ClashCardProgress? progress,
  ) {
    final unlocked = progress?.unlockedSkillNodeIds ?? const {};
    if (unlocked.isEmpty) {
      return scaledStats;
    }
    final bonus = flatBonuses(
      position: card.position,
      unlockedSkillNodeIds: unlocked,
    );
    return ClashStats(
      save: scaledStats.save + bonus.save,
      defense: scaledStats.defense + bonus.defense,
      pass: scaledStats.pass + bonus.pass,
      dribble: scaledStats.dribble + bonus.dribble,
      shot: scaledStats.shot + bonus.shot,
      techniquePoints: scaledStats.techniquePoints + bonus.techniquePoints,
      stamina: scaledStats.stamina + bonus.stamina,
    );
  }
}

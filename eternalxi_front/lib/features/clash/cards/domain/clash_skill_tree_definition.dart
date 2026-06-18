import 'clash_position.dart';
import 'clash_skill_tree_node.dart';
import 'clash_skill_tree_node_type.dart';
import 'clash_skill_tree_stat.dart';

/// Definición provisional del árbol lineal (5 nodos).
class ClashSkillTreeDefinition {
  const ClashSkillTreeDefinition._();

  static const int nodeCount = 5;

  static List<ClashSkillTreeNode> nodesFor(ClashPosition position) {
    final isGoalkeeper = position == ClashPosition.goalkeeper;
    final specs = isGoalkeeper
        ? const [
            (
              ClashSkillTreeStat.save,
              5,
              'Parada reforzada',
              'Mejora la parada.',
            ),
            (
              ClashSkillTreeStat.defense,
              5,
              'Defensa sólida',
              'Refuerza la defensa.',
            ),
            (
              ClashSkillTreeStat.techniquePoints,
              5,
              'Reserva PT',
              'Aumenta PT.',
            ),
            (
              ClashSkillTreeStat.stamina,
              8,
              'Resistencia extra',
              'Aguanta más en partido.',
            ),
            (
              ClashSkillTreeStat.save,
              5,
              'Muralla final',
              'Segunda mejora de parada.',
            ),
          ]
        : const [
            (
              ClashSkillTreeStat.defense,
              5,
              'Defensa sólida',
              'Refuerza la defensa.',
            ),
            (ClashSkillTreeStat.dribble, 5, 'Regate ágil', 'Mejora el regate.'),
            (ClashSkillTreeStat.shot, 5, 'Tiro potente', 'Mejora el tiro.'),
            (
              ClashSkillTreeStat.techniquePoints,
              5,
              'Reserva PT',
              'Aumenta PT.',
            ),
            (
              ClashSkillTreeStat.stamina,
              8,
              'Resistencia extra',
              'Aguanta más en partido.',
            ),
          ];

    return [
      for (var i = 0; i < specs.length; i++)
        ClashSkillTreeNode(
          id: 'skill-${i + 1}',
          order: i + 1,
          type: ClashSkillTreeNodeType.statBoost,
          stat: specs[i].$1,
          boostValue: specs[i].$2,
          requiredDuplicateIndex: i + 1,
          title: specs[i].$3,
          description: specs[i].$4,
        ),
    ];
  }

  static ClashSkillTreeNode? findNode(ClashPosition position, String nodeId) {
    for (final node in nodesFor(position)) {
      if (node.id == nodeId) {
        return node;
      }
    }
    return null;
  }
}

import 'clash_skill_tree_node_type.dart';
import 'clash_skill_tree_stat.dart';

/// Nodo lineal del árbol de habilidades (Fase 21).
class ClashSkillTreeNode {
  const ClashSkillTreeNode({
    required this.id,
    required this.order,
    required this.type,
    required this.stat,
    required this.boostValue,
    required this.requiredDuplicateIndex,
    required this.title,
    required this.description,
  });

  final String id;
  final int order;
  final ClashSkillTreeNodeType type;
  final ClashSkillTreeStat stat;
  final int boostValue;

  /// Índice de duplicado requerido (1–5).
  final int requiredDuplicateIndex;
  final String title;
  final String description;

  String get boostLabel => '+$boostValue ${stat.displayNameEs}';
}

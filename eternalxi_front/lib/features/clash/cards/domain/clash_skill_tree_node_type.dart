/// Tipo de nodo del árbol de habilidades Clash (Fase 21).
enum ClashSkillTreeNodeType {
  statBoost;

  String toJson() => name;

  static ClashSkillTreeNodeType fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'statboost' || 'stat_boost' => ClashSkillTreeNodeType.statBoost,
      _ => throw FormatException('Tipo de nodo de árbol desconocido: $value'),
    };
  }
}

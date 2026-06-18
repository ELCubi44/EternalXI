/// Stat afectada por un nodo del árbol de habilidades.
enum ClashSkillTreeStat {
  save,
  defense,
  pass,
  dribble,
  shot,
  techniquePoints,
  stamina;

  String get displayNameEs => switch (this) {
    ClashSkillTreeStat.save => 'Parada',
    ClashSkillTreeStat.defense => 'Defensa',
    ClashSkillTreeStat.pass => 'Pase',
    ClashSkillTreeStat.dribble => 'Regate',
    ClashSkillTreeStat.shot => 'Tiro',
    ClashSkillTreeStat.techniquePoints => 'PT',
    ClashSkillTreeStat.stamina => 'Resistencia',
  };

  String toJson() => name;

  static ClashSkillTreeStat fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'save' || 'parada' => ClashSkillTreeStat.save,
      'defense' || 'defensa' => ClashSkillTreeStat.defense,
      'pass' || 'pase' => ClashSkillTreeStat.pass,
      'dribble' || 'regate' => ClashSkillTreeStat.dribble,
      'shot' || 'tiro' => ClashSkillTreeStat.shot,
      'techniquepoints' || 'pt' => ClashSkillTreeStat.techniquePoints,
      'stamina' || 'resistencia' => ClashSkillTreeStat.stamina,
      _ => throw FormatException('Stat de árbol desconocida: $value'),
    };
  }
}

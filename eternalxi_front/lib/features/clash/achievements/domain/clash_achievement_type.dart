/// Tipo de logro permanente Clash (Fase 29).
enum ClashAchievementType {
  playMatch,
  winMatch,
  summon,
  collectCards,
  levelUpCard,
  upgradeTechnique,
  evolveCard,
  unlockSkillNode;

  static ClashAchievementType? fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'playMatch' => ClashAchievementType.playMatch,
      'winMatch' => ClashAchievementType.winMatch,
      'summon' => ClashAchievementType.summon,
      'collectCards' => ClashAchievementType.collectCards,
      'levelUpCard' => ClashAchievementType.levelUpCard,
      'upgradeTechnique' => ClashAchievementType.upgradeTechnique,
      'evolveCard' => ClashAchievementType.evolveCard,
      'unlockSkillNode' => ClashAchievementType.unlockSkillNode,
      _ => null,
    };
  }

  bool get usesAbsoluteProgress => this == ClashAchievementType.collectCards;
}

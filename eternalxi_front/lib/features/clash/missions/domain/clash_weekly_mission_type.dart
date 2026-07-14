/// Tipo de misión semanal Clash (Fase 30).
enum ClashWeeklyMissionType {
  playMatch,
  winMatch,
  summon,
  shopPurchase,
  levelUpCard,
  upgradeTechnique,
  evolveCard,
  unlockSkillNode,
  playChainTrial;

  static ClashWeeklyMissionType? fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'playMatch' => ClashWeeklyMissionType.playMatch,
      'winMatch' => ClashWeeklyMissionType.winMatch,
      'summon' => ClashWeeklyMissionType.summon,
      'shopPurchase' => ClashWeeklyMissionType.shopPurchase,
      'levelUpCard' => ClashWeeklyMissionType.levelUpCard,
      'upgradeTechnique' => ClashWeeklyMissionType.upgradeTechnique,
      'evolveCard' => ClashWeeklyMissionType.evolveCard,
      'unlockSkillNode' => ClashWeeklyMissionType.unlockSkillNode,
      'playChainTrial' => ClashWeeklyMissionType.playChainTrial,
      _ => null,
    };
  }

  String toJson() => name;
}

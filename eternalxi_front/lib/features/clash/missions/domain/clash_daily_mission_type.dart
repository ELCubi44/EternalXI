/// Tipo de misión diaria Clash (Fase 28).
enum ClashDailyMissionType {
  playMatch,
  winMatch,
  summon,
  shopPurchase,
  useExpMaterial,
  upgradeTechnique,
  playChainTrial;

  static ClashDailyMissionType? fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'playMatch' => ClashDailyMissionType.playMatch,
      'winMatch' => ClashDailyMissionType.winMatch,
      'summon' => ClashDailyMissionType.summon,
      'shopPurchase' => ClashDailyMissionType.shopPurchase,
      'useExpMaterial' => ClashDailyMissionType.useExpMaterial,
      'upgradeTechnique' => ClashDailyMissionType.upgradeTechnique,
      'playChainTrial' => ClashDailyMissionType.playChainTrial,
      _ => null,
    };
  }

  String toJson() => name;
}

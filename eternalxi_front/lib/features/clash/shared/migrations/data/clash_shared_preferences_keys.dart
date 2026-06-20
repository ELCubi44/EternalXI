/// Claves SharedPreferences de Clash (Fase 56).
///
/// Los valores string deben coincidir con los usados históricamente en cada
/// backend; no cambiar sin migración.
abstract final class ClashSharedPreferencesKeys {
  static const schemaVersion = 'clash_schema_version';
  static const lastMigratedAt = 'clash_last_migrated_at';

  static const lineups7v7 = 'clash_lineups_7v7_v1';
  static const playerCollectionV1 = 'clash_player_collection_v1';
  static const playerCollectionV2 = 'clash_player_collection_v2';
  static const expMaterialInventory = 'clash_exp_material_inventory_v1';
  static const techniqueBookInventory = 'clash_technique_book_inventory_v1';
  static const evolutionMaterialInventory =
      'clash_evolution_material_inventory_v1';
  static const gachaTicketInventory = 'clash_gacha_ticket_inventory_v1';
  static const dailyMissions = 'clash_daily_missions_v1';
  static const weeklyMissions = 'clash_weekly_missions_v1';
  static const achievements = 'clash_achievements_v1';
  static const newsRead = 'clash_news_read_v1';
  static const gifts = 'clash_gifts_v1';
  static const characterEvents = 'clash_character_events_v1';
  static const gachaHistory = 'clash_gacha_history_v1';
  static const gachaPity = 'clash_gacha_pity_v1';
  static const gachaDaily = 'clash_gacha_daily_v1';
  static const storyProgress = 'clash_story_progress_v1';
  static const rewardHistory = 'clash_reward_history_v1';

  /// Último backup local antes de aplicar snapshot remoto (Fase 73).
  static const lastLocalBackup = 'clash_last_local_backup_v1';

  /// Metadatos locales de sync online (Fase 76).
  static const syncMetadata = 'clash_sync_metadata_v1';

  /// Auto-check remoto al abrir Clash, off por defecto (Fase 79).
  static const syncAutoCheckEnabled = 'clash_sync_auto_check_enabled_v1';

  /// Claves de datos de progreso/inventario (excluye metadata de schema).
  static const dataKeys = <String>{
    lineups7v7,
    playerCollectionV1,
    playerCollectionV2,
    expMaterialInventory,
    techniqueBookInventory,
    evolutionMaterialInventory,
    gachaTicketInventory,
    dailyMissions,
    weeklyMissions,
    achievements,
    newsRead,
    gifts,
    characterEvents,
    gachaHistory,
    gachaPity,
    gachaDaily,
    storyProgress,
    rewardHistory,
  };
}

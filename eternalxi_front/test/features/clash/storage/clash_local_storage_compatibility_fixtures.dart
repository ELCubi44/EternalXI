import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Payloads mínimos representativos de instalaciones Clash antiguas (Fase 64).
abstract final class ClashLocalStorageCompatibilityFixtures {
  static const collectionV1 = '["card-a","card-b"]';

  static const collectionV2Minimal =
      '{"ownedCardIds":["card-a","card-b"],'
      '"cardProgress":{"card-a":{"cardId":"card-a","currentLevel":3,'
      '"currentExperience":12,"duplicateCopies":2,"unlockedDuplicateNodes":1}}}';

  static const collectionV2SparseOwnedOnly = '{"ownedCardIds":["card-a"]}';

  static const expMaterialsV1 = '{"quantities":{"basic-training-manual":9}}';

  static const techniqueBooksV1 = '{"quantities":{"basic-technique-book":2}}';

  static const evolutionMaterialsV1 = '{"quantities":{"insignia-r":1}}';

  static const ticketsV1 = '{"starter-single-ticket":5,"event-ticket":1}';

  static const lineupsV1 =
      '{"lineups":[{"id":"lineup-1","name":"Alineación 1","isActive":true,'
      '"slots":{"striker":"st-1","goalkeeper":"gk-1"},'
      '"lastModifiedAt":"2026-01-01T00:00:00.000Z"}]}';

  static const giftsV1 =
      '{"claimedGiftIds":["gift-welcome","gift-daily"],'
      '"lastOpenedAt":"2026-06-11T10:00:00.000Z"}';

  static const dailyMissionsV1 =
      '{"localDate":"2026-06-20","progress":{"daily-play-match":2},'
      '"claimedMissionIds":["daily-play-match"]}';

  static const weeklyMissionsV1 =
      '{"weekKey":"2026-W25","progress":{"weekly-win-matches":3},'
      '"claimedMissionIds":["weekly-win-matches"]}';

  static const achievementsV1 =
      '{"progress":{"ach-first-match":1},"claimedAchievementIds":["ach-first-match"],'
      '"updatedAt":"2026-06-01T08:00:00.000Z"}';

  static const characterEventsV1 =
      '{"completedStageIds":["event-mika-stage-01"],'
      '"claimedFirstClearRewardKeys":["event-mika-speed:event-mika-stage-01"],'
      '"clearCounts":{"event-mika-stage-01":2},'
      '"lastPlayedAt":"2026-06-10T18:00:00.000Z"}';

  static const gachaHistoryV1 =
      '{"entries":[{"id":"gacha-entry-1","bannerId":"starter-banner-001",'
      '"bannerName":"Invocación inicial","pullType":"single","spentGems":10,'
      '"createdAt":"2026-06-11T12:00:00.000Z","results":[{"cardId":"card-a",'
      '"cardName":"Jugador A","rarity":"sr","isNew":true,"isDuplicate":false,'
      '"upgradedRarity":false,"duplicateCopiesAfter":0,"wasPity":false,'
      '"wasMultiGuarantee":false}]}]}';

  static const gachaPityV1 =
      '{"banners":{"starter-banner-001":{"bannerId":"starter-banner-001",'
      '"pullsSinceLastPity":12,"pityThreshold":30,"totalPulls":40,"pityHits":1}}}';

  static const gachaDailyV1 = '{"starter-banner-001":"2026-06-20"}';

  static const storyProgressV1 =
      '{"completedLevelIds":["prologue-lvl-01"],'
      '"claimedRewardLevelIds":["prologue-lvl-01"],'
      '"claimedObjectiveRewardKeys":["prologue-lvl-02:score-win"],'
      '"currentSagaId":"saga-01","currentChapterId":"chapter-01",'
      '"unlocks":{"clashTeamUnlocked":true},'
      '"eternalXiCardsGranted":true,"walletGems":12,"walletCoins":1500}';

  static const rewardHistoryV1 =
      '{"entries":[{"id":"crh_legacy_1","sourceType":"gift","sourceId":"gift-a",'
      '"title":"Recompensa recibida","createdAt":"2026-06-11T10:00:00.000Z",'
      '"rewards":[{"kind":"coins","amount":100}],'
      '"failedRewards":[{"reward":{"kind":"gems","amount":1},'
      '"error":"grant_failed"}],"isPartial":true,"isFailure":false,'
      '"newlyGrantedCardIds":["card-a"],"duplicateCardIds":[]}]}';

  static const rewardHistoryFailureV1 =
      '{"entries":[{"id":"crh_fail_1","sourceType":"shop","sourceId":"shop-item",'
      '"title":"Compra fallida","createdAt":"2026-06-11T11:00:00.000Z",'
      '"rewards":[],"failedRewards":[],"isPartial":false,"isFailure":true}]}';

  /// Instalación legacy sin metadata de schema (versión 0 implícita).
  static Map<String, Object> legacyInstallWithoutSchemaVersion() => {
    ClashSharedPreferencesKeys.playerCollectionV2: collectionV2Minimal,
    ClashSharedPreferencesKeys.expMaterialInventory: expMaterialsV1,
    ClashSharedPreferencesKeys.techniqueBookInventory: techniqueBooksV1,
    ClashSharedPreferencesKeys.evolutionMaterialInventory: evolutionMaterialsV1,
    ClashSharedPreferencesKeys.gachaTicketInventory: ticketsV1,
    ClashSharedPreferencesKeys.lineups7v7: lineupsV1,
    ClashSharedPreferencesKeys.gifts: giftsV1,
    ClashSharedPreferencesKeys.dailyMissions: dailyMissionsV1,
    ClashSharedPreferencesKeys.weeklyMissions: weeklyMissionsV1,
    ClashSharedPreferencesKeys.achievements: achievementsV1,
    ClashSharedPreferencesKeys.characterEvents: characterEventsV1,
    ClashSharedPreferencesKeys.gachaHistory: gachaHistoryV1,
    ClashSharedPreferencesKeys.gachaPity: gachaPityV1,
    ClashSharedPreferencesKeys.gachaDaily: gachaDailyV1,
    ClashSharedPreferencesKeys.storyProgress: storyProgressV1,
    ClashSharedPreferencesKeys.rewardHistory: rewardHistoryV1,
  };

  static Future<SharedPreferences> mountPrefs(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }
}

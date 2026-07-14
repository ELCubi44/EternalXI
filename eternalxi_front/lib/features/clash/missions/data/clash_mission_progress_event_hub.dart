import 'package:eternal_xi/features/clash/achievements/data/clash_achievement_event_sink.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_type.dart';

/// Distribuye eventos de progreso a misiones diarias, semanales y logros (Fase 30).
class ClashMissionProgressEventHub {
  ClashMissionProgressEventHub({
    required ClashDailyMissionEventSink daily,
    required ClashWeeklyMissionEventSink weekly,
    required ClashAchievementEventSink achievements,
  }) : _daily = daily,
       _weekly = weekly,
       _achievements = achievements;

  final ClashDailyMissionEventSink _daily;
  final ClashWeeklyMissionEventSink _weekly;
  final ClashAchievementEventSink _achievements;

  Future<void> recordPlayMatch({int amount = 1}) async {
    await _daily.record(ClashDailyMissionType.playMatch, amount: amount);
    await _weekly.record(ClashWeeklyMissionType.playMatch, amount: amount);
    await _achievements.record(ClashAchievementType.playMatch, amount: amount);
  }

  Future<void> recordWinMatch({int amount = 1}) async {
    await _daily.record(ClashDailyMissionType.winMatch, amount: amount);
    await _weekly.record(ClashWeeklyMissionType.winMatch, amount: amount);
    await _achievements.record(ClashAchievementType.winMatch, amount: amount);
  }

  Future<void> recordSummon({
    int dailyWeeklyAmount = 1,
    required int achievementCards,
  }) async {
    await _daily.record(
      ClashDailyMissionType.summon,
      amount: dailyWeeklyAmount,
    );
    await _weekly.record(
      ClashWeeklyMissionType.summon,
      amount: dailyWeeklyAmount,
    );
    if (achievementCards > 0) {
      await _achievements.record(
        ClashAchievementType.summon,
        amount: achievementCards,
      );
    }
  }

  Future<void> recordShopPurchase({int amount = 1}) async {
    await _daily.record(ClashDailyMissionType.shopPurchase, amount: amount);
    await _weekly.record(ClashWeeklyMissionType.shopPurchase, amount: amount);
  }

  Future<void> recordUseExpMaterial({required bool didLevelUp}) async {
    await _daily.record(ClashDailyMissionType.useExpMaterial);
    if (didLevelUp) {
      await recordLevelUpCard();
    }
  }

  Future<void> recordLevelUpCard({int amount = 1}) async {
    if (amount <= 0) {
      return;
    }
    await _weekly.record(ClashWeeklyMissionType.levelUpCard, amount: amount);
    await _achievements.record(
      ClashAchievementType.levelUpCard,
      amount: amount,
    );
  }

  Future<void> recordUpgradeTechnique({required bool didLevelUp}) async {
    await _daily.record(ClashDailyMissionType.upgradeTechnique);
    if (didLevelUp) {
      await _weekly.record(ClashWeeklyMissionType.upgradeTechnique);
      await _achievements.record(ClashAchievementType.upgradeTechnique);
    }
  }

  Future<void> recordEvolveCard({int amount = 1}) async {
    if (amount <= 0) {
      return;
    }
    await _weekly.record(ClashWeeklyMissionType.evolveCard, amount: amount);
    await _achievements.record(ClashAchievementType.evolveCard, amount: amount);
  }

  Future<void> recordUnlockSkillNode({int amount = 1}) async {
    if (amount <= 0) {
      return;
    }
    await _weekly.record(
      ClashWeeklyMissionType.unlockSkillNode,
      amount: amount,
    );
    await _achievements.record(
      ClashAchievementType.unlockSkillNode,
      amount: amount,
    );
  }

  Future<void> recordPlayChainTrial({int amount = 1}) async {
    await _daily.record(ClashDailyMissionType.playChainTrial, amount: amount);
    await _weekly.record(ClashWeeklyMissionType.playChainTrial, amount: amount);
  }

  Future<void> syncCollectCards(int uniqueOwnedCount) async {
    if (uniqueOwnedCount <= 0) {
      return;
    }
    await _achievements.record(
      ClashAchievementType.collectCards,
      amount: uniqueOwnedCount,
      absolute: true,
    );
  }
}

/// Resumen de progreso por evento para diagnóstico local (Fase 61).
class ClashDebugEventProgress {
  const ClashDebugEventProgress({
    required this.eventId,
    required this.eventTitle,
    required this.completedStages,
    required this.totalStages,
  });

  final String eventId;
  final String eventTitle;
  final int completedStages;
  final int totalStages;
}

/// Resumen de pity por banner para diagnóstico local (Fase 61).
class ClashDebugGachaPitySummary {
  const ClashDebugGachaPitySummary({
    required this.bannerId,
    required this.pullsSinceLastPity,
    required this.threshold,
    required this.totalPulls,
  });

  final String bannerId;
  final int pullsSinceLastPity;
  final int threshold;
  final int totalPulls;
}

/// Snapshot de solo lectura del estado local Clash (Fase 61).
class ClashDebugSnapshot {
  const ClashDebugSnapshot({
    required this.schemaVersion,
    this.lastMigratedAt,
    required this.rewardHistoryCount,
    required this.collectionTotalCards,
    required this.collectionUniqueCards,
    required this.collectionDuplicateCopies,
    required this.walletCoins,
    required this.walletGems,
    required this.expMaterialQuantity,
    required this.techniqueBookQuantity,
    required this.evolutionMaterialQuantity,
    required this.ticketQuantity,
    required this.totalEvents,
    required this.eventsWithProgress,
    required this.eventProgress,
    required this.gachaHistoryCount,
    required this.gachaPitySummaries,
    required this.gachaDailyAvailableCount,
    required this.gachaDailyUsedCount,
    required this.giftsClaimed,
    required this.giftsPending,
    required this.giftsTotal,
    required this.dailyMissionsCompleted,
    required this.dailyMissionsClaimed,
    required this.dailyMissionsTotal,
    required this.weeklyMissionsCompleted,
    required this.weeklyMissionsClaimed,
    required this.weeklyMissionsTotal,
    required this.achievementsCompleted,
    required this.achievementsClaimed,
    required this.achievementsTotal,
  });

  final int schemaVersion;
  final String? lastMigratedAt;
  final int rewardHistoryCount;
  final int collectionTotalCards;
  final int collectionUniqueCards;
  final int collectionDuplicateCopies;
  final int walletCoins;
  final int walletGems;
  final int expMaterialQuantity;
  final int techniqueBookQuantity;
  final int evolutionMaterialQuantity;
  final int ticketQuantity;
  final int totalEvents;
  final int eventsWithProgress;
  final List<ClashDebugEventProgress> eventProgress;
  final int gachaHistoryCount;
  final List<ClashDebugGachaPitySummary> gachaPitySummaries;
  final int gachaDailyAvailableCount;
  final int gachaDailyUsedCount;
  final int giftsClaimed;
  final int giftsPending;
  final int giftsTotal;
  final int dailyMissionsCompleted;
  final int dailyMissionsClaimed;
  final int dailyMissionsTotal;
  final int weeklyMissionsCompleted;
  final int weeklyMissionsClaimed;
  final int weeklyMissionsTotal;
  final int achievementsCompleted;
  final int achievementsClaimed;
  final int achievementsTotal;
}

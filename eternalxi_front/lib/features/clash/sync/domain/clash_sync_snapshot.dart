import 'clash_sync_contract_version.dart';
import 'clash_sync_device_info.dart';

/// Wallet Clash incluida en el snapshot de sync.
class ClashSyncWallet {
  const ClashSyncWallet({this.coins = 0, this.gems = 0});

  final int coins;
  final int gems;

  Map<String, dynamic> toJson() => {'coins': coins, 'gems': gems};

  factory ClashSyncWallet.fromJson(Map<String, dynamic> json) {
    return ClashSyncWallet(
      coins: _readInt(json['coins']),
      gems: _readInt(json['gems']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncWallet &&
        other.coins == coins &&
        other.gems == gems;
  }

  @override
  int get hashCode => Object.hash(coins, gems);
}

/// Resumen de colección para sync (sin detalle completo de progreso por carta).
class ClashSyncCollection {
  const ClashSyncCollection({
    this.ownedCardIds = const [],
    this.uniqueCount = 0,
    this.totalCopies = 0,
    this.duplicateCopies = 0,
  });

  final List<String> ownedCardIds;
  final int uniqueCount;
  final int totalCopies;
  final int duplicateCopies;

  Map<String, dynamic> toJson() => {
    'ownedCardIds': ownedCardIds,
    'uniqueCount': uniqueCount,
    'totalCopies': totalCopies,
    'duplicateCopies': duplicateCopies,
  };

  factory ClashSyncCollection.fromJson(Map<String, dynamic> json) {
    final ownedRaw = json['ownedCardIds'] as List? ?? const [];
    return ClashSyncCollection(
      ownedCardIds: ownedRaw.map((id) => id.toString()).toList(growable: false),
      uniqueCount: _readInt(json['uniqueCount']),
      totalCopies: _readInt(json['totalCopies']),
      duplicateCopies: _readInt(json['duplicateCopies']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncCollection &&
        _listEquals(other.ownedCardIds, ownedCardIds) &&
        other.uniqueCount == uniqueCount &&
        other.totalCopies == totalCopies &&
        other.duplicateCopies == duplicateCopies;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(ownedCardIds),
    uniqueCount,
    totalCopies,
    duplicateCopies,
  );
}

/// Inventarios locales agregados para sync.
class ClashSyncInventories {
  const ClashSyncInventories({
    this.expMaterials = const {},
    this.techniqueBooks = const {},
    this.evolutionMaterials = const {},
    this.tickets = const {},
  });

  final Map<String, int> expMaterials;
  final Map<String, int> techniqueBooks;
  final Map<String, int> evolutionMaterials;
  final Map<String, int> tickets;

  Map<String, dynamic> toJson() => {
    'expMaterials': expMaterials,
    'techniqueBooks': techniqueBooks,
    'evolutionMaterials': evolutionMaterials,
    'tickets': tickets,
  };

  factory ClashSyncInventories.fromJson(Map<String, dynamic> json) {
    return ClashSyncInventories(
      expMaterials: _readIntMap(json['expMaterials']),
      techniqueBooks: _readIntMap(json['techniqueBooks']),
      evolutionMaterials: _readIntMap(json['evolutionMaterials']),
      tickets: _readIntMap(json['tickets']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncInventories &&
        _mapEquals(other.expMaterials, expMaterials) &&
        _mapEquals(other.techniqueBooks, techniqueBooks) &&
        _mapEquals(other.evolutionMaterials, evolutionMaterials) &&
        _mapEquals(other.tickets, tickets);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(expMaterials.entries),
    Object.hashAll(techniqueBooks.entries),
    Object.hashAll(evolutionMaterials.entries),
    Object.hashAll(tickets.entries),
  );
}

/// Resumen de alineaciones 7v7 para sync.
class ClashSyncLineups {
  const ClashSyncLineups({
    this.lineupCount = 0,
    this.activeLineupId,
    this.completeLineupCount = 0,
  });

  final int lineupCount;
  final String? activeLineupId;
  final int completeLineupCount;

  Map<String, dynamic> toJson() => {
    'lineupCount': lineupCount,
    if (activeLineupId != null) 'activeLineupId': activeLineupId,
    'completeLineupCount': completeLineupCount,
  };

  factory ClashSyncLineups.fromJson(Map<String, dynamic> json) {
    return ClashSyncLineups(
      lineupCount: _readInt(json['lineupCount']),
      activeLineupId: json['activeLineupId']?.toString(),
      completeLineupCount: _readInt(json['completeLineupCount']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncLineups &&
        other.lineupCount == lineupCount &&
        other.activeLineupId == activeLineupId &&
        other.completeLineupCount == completeLineupCount;
  }

  @override
  int get hashCode =>
      Object.hash(lineupCount, activeLineupId, completeLineupCount);
}

/// Progreso de historia relevante para sync (sin duplicar wallet).
class ClashSyncStoryProgress {
  const ClashSyncStoryProgress({
    this.completedLevelIds = const [],
    this.claimedRewardLevelIds = const [],
    this.claimedObjectiveRewardKeys = const [],
    this.currentSagaId = 'saga-01',
    this.currentChapterId = 'chapter-01',
    this.clashTeamUnlocked = false,
    this.eternalXiCardsGranted = false,
  });

  final List<String> completedLevelIds;
  final List<String> claimedRewardLevelIds;
  final List<String> claimedObjectiveRewardKeys;
  final String currentSagaId;
  final String currentChapterId;
  final bool clashTeamUnlocked;
  final bool eternalXiCardsGranted;

  Map<String, dynamic> toJson() => {
    'completedLevelIds': completedLevelIds,
    'claimedRewardLevelIds': claimedRewardLevelIds,
    'claimedObjectiveRewardKeys': claimedObjectiveRewardKeys,
    'currentSagaId': currentSagaId,
    'currentChapterId': currentChapterId,
    'clashTeamUnlocked': clashTeamUnlocked,
    'eternalXiCardsGranted': eternalXiCardsGranted,
  };

  factory ClashSyncStoryProgress.fromJson(Map<String, dynamic> json) {
    return ClashSyncStoryProgress(
      completedLevelIds: _readStringList(json['completedLevelIds']),
      claimedRewardLevelIds: _readStringList(json['claimedRewardLevelIds']),
      claimedObjectiveRewardKeys: _readStringList(
        json['claimedObjectiveRewardKeys'],
      ),
      currentSagaId: json['currentSagaId']?.toString() ?? 'saga-01',
      currentChapterId: json['currentChapterId']?.toString() ?? 'chapter-01',
      clashTeamUnlocked: json['clashTeamUnlocked'] == true,
      eternalXiCardsGranted: json['eternalXiCardsGranted'] == true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncStoryProgress &&
        _listEquals(other.completedLevelIds, completedLevelIds) &&
        _listEquals(other.claimedRewardLevelIds, claimedRewardLevelIds) &&
        _listEquals(
          other.claimedObjectiveRewardKeys,
          claimedObjectiveRewardKeys,
        ) &&
        other.currentSagaId == currentSagaId &&
        other.currentChapterId == currentChapterId &&
        other.clashTeamUnlocked == clashTeamUnlocked &&
        other.eternalXiCardsGranted == eternalXiCardsGranted;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(completedLevelIds),
    Object.hashAll(claimedRewardLevelIds),
    Object.hashAll(claimedObjectiveRewardKeys),
    currentSagaId,
    currentChapterId,
    clashTeamUnlocked,
    eternalXiCardsGranted,
  );
}

/// Progreso persistido de eventos de personaje.
class ClashSyncCharacterEventsProgress {
  const ClashSyncCharacterEventsProgress({
    this.completedStageIds = const [],
    this.claimedFirstClearRewardKeys = const [],
    this.clearCounts = const {},
    this.lastPlayedAt,
  });

  final List<String> completedStageIds;
  final List<String> claimedFirstClearRewardKeys;
  final Map<String, int> clearCounts;
  final String? lastPlayedAt;

  Map<String, dynamic> toJson() => {
    'completedStageIds': completedStageIds,
    'claimedFirstClearRewardKeys': claimedFirstClearRewardKeys,
    'clearCounts': clearCounts,
    if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt,
  };

  factory ClashSyncCharacterEventsProgress.fromJson(Map<String, dynamic> json) {
    return ClashSyncCharacterEventsProgress(
      completedStageIds: _readStringList(json['completedStageIds']),
      claimedFirstClearRewardKeys: _readStringList(
        json['claimedFirstClearRewardKeys'],
      ),
      clearCounts: _readIntMap(json['clearCounts']),
      lastPlayedAt: json['lastPlayedAt']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncCharacterEventsProgress &&
        _listEquals(other.completedStageIds, completedStageIds) &&
        _listEquals(
          other.claimedFirstClearRewardKeys,
          claimedFirstClearRewardKeys,
        ) &&
        _mapEquals(other.clearCounts, clearCounts) &&
        other.lastPlayedAt == lastPlayedAt;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(completedStageIds),
    Object.hashAll(claimedFirstClearRewardKeys),
    Object.hashAll(clearCounts.entries),
    lastPlayedAt,
  );
}

/// Progreso diario/semanal de misiones.
class ClashSyncMissionsProgress {
  const ClashSyncMissionsProgress({
    this.dailyLocalDate = '',
    this.dailyProgress = const {},
    this.dailyClaimedMissionIds = const [],
    this.weeklyWeekKey = '',
    this.weeklyProgress = const {},
    this.weeklyClaimedMissionIds = const [],
  });

  final String dailyLocalDate;
  final Map<String, int> dailyProgress;
  final List<String> dailyClaimedMissionIds;
  final String weeklyWeekKey;
  final Map<String, int> weeklyProgress;
  final List<String> weeklyClaimedMissionIds;

  Map<String, dynamic> toJson() => {
    'dailyLocalDate': dailyLocalDate,
    'dailyProgress': dailyProgress,
    'dailyClaimedMissionIds': dailyClaimedMissionIds,
    'weeklyWeekKey': weeklyWeekKey,
    'weeklyProgress': weeklyProgress,
    'weeklyClaimedMissionIds': weeklyClaimedMissionIds,
  };

  factory ClashSyncMissionsProgress.fromJson(Map<String, dynamic> json) {
    return ClashSyncMissionsProgress(
      dailyLocalDate: json['dailyLocalDate']?.toString() ?? '',
      dailyProgress: _readIntMap(json['dailyProgress']),
      dailyClaimedMissionIds: _readStringList(json['dailyClaimedMissionIds']),
      weeklyWeekKey: json['weeklyWeekKey']?.toString() ?? '',
      weeklyProgress: _readIntMap(json['weeklyProgress']),
      weeklyClaimedMissionIds: _readStringList(json['weeklyClaimedMissionIds']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncMissionsProgress &&
        other.dailyLocalDate == dailyLocalDate &&
        _mapEquals(other.dailyProgress, dailyProgress) &&
        _listEquals(other.dailyClaimedMissionIds, dailyClaimedMissionIds) &&
        other.weeklyWeekKey == weeklyWeekKey &&
        _mapEquals(other.weeklyProgress, weeklyProgress) &&
        _listEquals(other.weeklyClaimedMissionIds, weeklyClaimedMissionIds);
  }

  @override
  int get hashCode => Object.hash(
    dailyLocalDate,
    Object.hashAll(dailyProgress.entries),
    Object.hashAll(dailyClaimedMissionIds),
    weeklyWeekKey,
    Object.hashAll(weeklyProgress.entries),
    Object.hashAll(weeklyClaimedMissionIds),
  );
}

/// Progreso de logros Clash.
class ClashSyncAchievementsProgress {
  const ClashSyncAchievementsProgress({
    this.progress = const {},
    this.claimedAchievementIds = const [],
    this.updatedAt,
  });

  final Map<String, int> progress;
  final List<String> claimedAchievementIds;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'claimedAchievementIds': claimedAchievementIds,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  factory ClashSyncAchievementsProgress.fromJson(Map<String, dynamic> json) {
    return ClashSyncAchievementsProgress(
      progress: _readIntMap(json['progress']),
      claimedAchievementIds: _readStringList(json['claimedAchievementIds']),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncAchievementsProgress &&
        _mapEquals(other.progress, progress) &&
        _listEquals(other.claimedAchievementIds, claimedAchievementIds) &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(progress.entries),
    Object.hashAll(claimedAchievementIds),
    updatedAt,
  );
}

/// Progreso del buzón de regalos.
class ClashSyncGiftsProgress {
  const ClashSyncGiftsProgress({
    this.claimedGiftIds = const [],
    this.lastOpenedAt,
  });

  final List<String> claimedGiftIds;
  final String? lastOpenedAt;

  Map<String, dynamic> toJson() => {
    'claimedGiftIds': claimedGiftIds,
    if (lastOpenedAt != null) 'lastOpenedAt': lastOpenedAt,
  };

  factory ClashSyncGiftsProgress.fromJson(Map<String, dynamic> json) {
    return ClashSyncGiftsProgress(
      claimedGiftIds: _readStringList(json['claimedGiftIds']),
      lastOpenedAt: json['lastOpenedAt']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncGiftsProgress &&
        _listEquals(other.claimedGiftIds, claimedGiftIds) &&
        other.lastOpenedAt == lastOpenedAt;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(claimedGiftIds), lastOpenedAt);
}

/// Pity por banner para sync.
class ClashSyncGachaPityState {
  const ClashSyncGachaPityState({
    required this.bannerId,
    this.pullsSinceLastPity = 0,
    this.pityThreshold = 30,
    this.totalPulls = 0,
    this.pityHits = 0,
  });

  final String bannerId;
  final int pullsSinceLastPity;
  final int pityThreshold;
  final int totalPulls;
  final int pityHits;

  Map<String, dynamic> toJson() => {
    'bannerId': bannerId,
    'pullsSinceLastPity': pullsSinceLastPity,
    'pityThreshold': pityThreshold,
    'totalPulls': totalPulls,
    'pityHits': pityHits,
  };

  factory ClashSyncGachaPityState.fromJson(Map<String, dynamic> json) {
    return ClashSyncGachaPityState(
      bannerId: json['bannerId']?.toString() ?? '',
      pullsSinceLastPity: _readInt(json['pullsSinceLastPity']),
      pityThreshold: _readInt(json['pityThreshold'], fallback: 30),
      totalPulls: _readInt(json['totalPulls']),
      pityHits: _readInt(json['pityHits']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncGachaPityState &&
        other.bannerId == bannerId &&
        other.pullsSinceLastPity == pullsSinceLastPity &&
        other.pityThreshold == pityThreshold &&
        other.totalPulls == totalPulls &&
        other.pityHits == pityHits;
  }

  @override
  int get hashCode => Object.hash(
    bannerId,
    pullsSinceLastPity,
    pityThreshold,
    totalPulls,
    pityHits,
  );
}

/// Estado agregado de gacha para sync.
class ClashSyncGachaState {
  const ClashSyncGachaState({
    this.historyEntryCount = 0,
    this.pityByBanner = const [],
    this.dailyLastUsedByBanner = const {},
  });

  final int historyEntryCount;
  final List<ClashSyncGachaPityState> pityByBanner;
  final Map<String, String> dailyLastUsedByBanner;

  Map<String, dynamic> toJson() => {
    'historyEntryCount': historyEntryCount,
    'pityByBanner': pityByBanner.map((item) => item.toJson()).toList(),
    'dailyLastUsedByBanner': dailyLastUsedByBanner,
  };

  factory ClashSyncGachaState.fromJson(Map<String, dynamic> json) {
    final pityRaw = json['pityByBanner'] as List? ?? const [];
    return ClashSyncGachaState(
      historyEntryCount: _readInt(json['historyEntryCount']),
      pityByBanner: pityRaw
          .map(
            (item) => ClashSyncGachaPityState.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      dailyLastUsedByBanner: _readStringMap(json['dailyLastUsedByBanner']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncGachaState &&
        other.historyEntryCount == historyEntryCount &&
        _listEquals(other.pityByBanner, pityByBanner) &&
        _mapEquals(other.dailyLastUsedByBanner, dailyLastUsedByBanner);
  }

  @override
  int get hashCode => Object.hash(
    historyEntryCount,
    Object.hashAll(pityByBanner),
    Object.hashAll(dailyLastUsedByBanner.entries),
  );
}

/// Resumen del historial de recompensas (sin entradas completas).
class ClashSyncRewardHistorySummary {
  const ClashSyncRewardHistorySummary({
    this.entryCount = 0,
    this.latestEntryAt,
    this.partialCount = 0,
    this.failureCount = 0,
  });

  final int entryCount;
  final String? latestEntryAt;
  final int partialCount;
  final int failureCount;

  Map<String, dynamic> toJson() => {
    'entryCount': entryCount,
    if (latestEntryAt != null) 'latestEntryAt': latestEntryAt,
    'partialCount': partialCount,
    'failureCount': failureCount,
  };

  factory ClashSyncRewardHistorySummary.fromJson(Map<String, dynamic> json) {
    return ClashSyncRewardHistorySummary(
      entryCount: _readInt(json['entryCount']),
      latestEntryAt: json['latestEntryAt']?.toString(),
      partialCount: _readInt(json['partialCount']),
      failureCount: _readInt(json['failureCount']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncRewardHistorySummary &&
        other.entryCount == entryCount &&
        other.latestEntryAt == latestEntryAt &&
        other.partialCount == partialCount &&
        other.failureCount == failureCount;
  }

  @override
  int get hashCode =>
      Object.hash(entryCount, latestEntryAt, partialCount, failureCount);
}

/// Snapshot principal del contrato de sync Clash (Fase 65).
class ClashSyncSnapshot {
  const ClashSyncSnapshot({
    this.contractVersion = ClashSyncContractVersion.current,
    required this.generatedAt,
    this.schemaVersion = 0,
    this.lastMigratedAt,
    this.deviceInfo,
    this.wallet = const ClashSyncWallet(),
    this.collection = const ClashSyncCollection(),
    this.inventories = const ClashSyncInventories(),
    this.lineups = const ClashSyncLineups(),
    this.storyProgress = const ClashSyncStoryProgress(),
    this.characterEventsProgress = const ClashSyncCharacterEventsProgress(),
    this.missionsProgress = const ClashSyncMissionsProgress(),
    this.achievementsProgress = const ClashSyncAchievementsProgress(),
    this.giftsProgress = const ClashSyncGiftsProgress(),
    this.gachaState = const ClashSyncGachaState(),
    this.rewardHistorySummary = const ClashSyncRewardHistorySummary(),
  });

  final int contractVersion;
  final DateTime generatedAt;
  final int schemaVersion;
  final String? lastMigratedAt;
  final ClashSyncDeviceInfo? deviceInfo;
  final ClashSyncWallet wallet;
  final ClashSyncCollection collection;
  final ClashSyncInventories inventories;
  final ClashSyncLineups lineups;
  final ClashSyncStoryProgress storyProgress;
  final ClashSyncCharacterEventsProgress characterEventsProgress;
  final ClashSyncMissionsProgress missionsProgress;
  final ClashSyncAchievementsProgress achievementsProgress;
  final ClashSyncGiftsProgress giftsProgress;
  final ClashSyncGachaState gachaState;
  final ClashSyncRewardHistorySummary rewardHistorySummary;

  ClashSyncSnapshot copyWith({
    int? contractVersion,
    DateTime? generatedAt,
    int? schemaVersion,
    String? lastMigratedAt,
    ClashSyncDeviceInfo? deviceInfo,
    ClashSyncWallet? wallet,
    ClashSyncCollection? collection,
    ClashSyncInventories? inventories,
    ClashSyncLineups? lineups,
    ClashSyncStoryProgress? storyProgress,
    ClashSyncCharacterEventsProgress? characterEventsProgress,
    ClashSyncMissionsProgress? missionsProgress,
    ClashSyncAchievementsProgress? achievementsProgress,
    ClashSyncGiftsProgress? giftsProgress,
    ClashSyncGachaState? gachaState,
    ClashSyncRewardHistorySummary? rewardHistorySummary,
  }) {
    return ClashSyncSnapshot(
      contractVersion: contractVersion ?? this.contractVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lastMigratedAt: lastMigratedAt ?? this.lastMigratedAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      wallet: wallet ?? this.wallet,
      collection: collection ?? this.collection,
      inventories: inventories ?? this.inventories,
      lineups: lineups ?? this.lineups,
      storyProgress: storyProgress ?? this.storyProgress,
      characterEventsProgress:
          characterEventsProgress ?? this.characterEventsProgress,
      missionsProgress: missionsProgress ?? this.missionsProgress,
      achievementsProgress: achievementsProgress ?? this.achievementsProgress,
      giftsProgress: giftsProgress ?? this.giftsProgress,
      gachaState: gachaState ?? this.gachaState,
      rewardHistorySummary: rewardHistorySummary ?? this.rewardHistorySummary,
    );
  }

  Map<String, dynamic> toJson() => {
    'contractVersion': contractVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'schemaVersion': schemaVersion,
    if (lastMigratedAt != null) 'lastMigratedAt': lastMigratedAt,
    if (deviceInfo != null) 'deviceInfo': deviceInfo!.toJson(),
    'wallet': wallet.toJson(),
    'collection': collection.toJson(),
    'inventories': inventories.toJson(),
    'lineups': lineups.toJson(),
    'storyProgress': storyProgress.toJson(),
    'characterEventsProgress': characterEventsProgress.toJson(),
    'missionsProgress': missionsProgress.toJson(),
    'achievementsProgress': achievementsProgress.toJson(),
    'giftsProgress': giftsProgress.toJson(),
    'gachaState': gachaState.toJson(),
    'rewardHistorySummary': rewardHistorySummary.toJson(),
  };

  factory ClashSyncSnapshot.fromJson(Map<String, dynamic> json) {
    final deviceRaw = json['deviceInfo'];
    return ClashSyncSnapshot(
      contractVersion: _readInt(
        json['contractVersion'],
        fallback: ClashSyncContractVersion.current,
      ),
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      schemaVersion: _readInt(json['schemaVersion']),
      lastMigratedAt: json['lastMigratedAt']?.toString(),
      deviceInfo: deviceRaw is Map
          ? ClashSyncDeviceInfo.fromJson(Map<String, dynamic>.from(deviceRaw))
          : null,
      wallet: ClashSyncWallet.fromJson(
        Map<String, dynamic>.from(json['wallet'] as Map? ?? const {}),
      ),
      collection: ClashSyncCollection.fromJson(
        Map<String, dynamic>.from(json['collection'] as Map? ?? const {}),
      ),
      inventories: ClashSyncInventories.fromJson(
        Map<String, dynamic>.from(json['inventories'] as Map? ?? const {}),
      ),
      lineups: ClashSyncLineups.fromJson(
        Map<String, dynamic>.from(json['lineups'] as Map? ?? const {}),
      ),
      storyProgress: ClashSyncStoryProgress.fromJson(
        Map<String, dynamic>.from(json['storyProgress'] as Map? ?? const {}),
      ),
      characterEventsProgress: ClashSyncCharacterEventsProgress.fromJson(
        Map<String, dynamic>.from(
          json['characterEventsProgress'] as Map? ?? const {},
        ),
      ),
      missionsProgress: ClashSyncMissionsProgress.fromJson(
        Map<String, dynamic>.from(json['missionsProgress'] as Map? ?? const {}),
      ),
      achievementsProgress: ClashSyncAchievementsProgress.fromJson(
        Map<String, dynamic>.from(
          json['achievementsProgress'] as Map? ?? const {},
        ),
      ),
      giftsProgress: ClashSyncGiftsProgress.fromJson(
        Map<String, dynamic>.from(json['giftsProgress'] as Map? ?? const {}),
      ),
      gachaState: ClashSyncGachaState.fromJson(
        Map<String, dynamic>.from(json['gachaState'] as Map? ?? const {}),
      ),
      rewardHistorySummary: ClashSyncRewardHistorySummary.fromJson(
        Map<String, dynamic>.from(
          json['rewardHistorySummary'] as Map? ?? const {},
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncSnapshot &&
        other.contractVersion == contractVersion &&
        other.generatedAt == generatedAt &&
        other.schemaVersion == schemaVersion &&
        other.lastMigratedAt == lastMigratedAt &&
        other.deviceInfo == deviceInfo &&
        other.wallet == wallet &&
        other.collection == collection &&
        other.inventories == inventories &&
        other.lineups == lineups &&
        other.storyProgress == storyProgress &&
        other.characterEventsProgress == characterEventsProgress &&
        other.missionsProgress == missionsProgress &&
        other.achievementsProgress == achievementsProgress &&
        other.giftsProgress == giftsProgress &&
        other.gachaState == gachaState &&
        other.rewardHistorySummary == rewardHistorySummary;
  }

  @override
  int get hashCode => Object.hash(
    contractVersion,
    generatedAt,
    schemaVersion,
    lastMigratedAt,
    deviceInfo,
    wallet,
    collection,
    inventories,
    lineups,
    storyProgress,
    characterEventsProgress,
    missionsProgress,
    achievementsProgress,
    giftsProgress,
    gachaState,
    rewardHistorySummary,
  );
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

Map<String, int> _readIntMap(Object? raw) {
  if (raw is! Map) {
    return const {};
  }
  final result = <String, int>{};
  for (final entry in raw.entries) {
    result[entry.key.toString()] = _readInt(entry.value);
  }
  return result;
}

Map<String, String> _readStringMap(Object? raw) {
  if (raw is! Map) {
    return const {};
  }
  return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
}

List<String> _readStringList(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw.map((item) => item.toString()).toList(growable: false);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_progress.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_completion_unlocks.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Progreso local del jugador en la historia Clash.
class ClashStoryProgress {
  const ClashStoryProgress({
    this.completedLevelIds = const {},
    this.claimedRewardLevelIds = const {},
    this.claimedObjectiveRewardKeys = const {},
    this.currentSagaId = 'saga-01',
    this.currentChapterId = 'chapter-01',
    this.unlocks = const ClashStoryCompletionUnlocks(),
    this.eternalXiCardsGranted = false,
    this.walletGems = 0,
    this.walletCoins = 0,
  });

  final Set<String> completedLevelIds;
  final Set<String> claimedRewardLevelIds;
  final Set<String> claimedObjectiveRewardKeys;
  final String currentSagaId;
  final String currentChapterId;
  final ClashStoryCompletionUnlocks unlocks;
  final bool eternalXiCardsGranted;
  final int walletGems;
  final int walletCoins;

  bool get clashTeamUnlocked => unlocks.clashTeamUnlocked;

  bool isLevelCompleted(String levelId) => completedLevelIds.contains(levelId);

  bool areRewardsClaimed(String levelId) =>
      claimedRewardLevelIds.contains(levelId);

  bool isObjectiveRewardClaimed(String levelId, String objectiveId) =>
      claimedObjectiveRewardKeys.contains('$levelId:$objectiveId');

  ClashStoryProgress copyWith({
    Set<String>? completedLevelIds,
    Set<String>? claimedRewardLevelIds,
    Set<String>? claimedObjectiveRewardKeys,
    String? currentSagaId,
    String? currentChapterId,
    ClashStoryCompletionUnlocks? unlocks,
    bool? eternalXiCardsGranted,
    int? walletGems,
    int? walletCoins,
  }) {
    return ClashStoryProgress(
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      claimedRewardLevelIds:
          claimedRewardLevelIds ?? this.claimedRewardLevelIds,
      claimedObjectiveRewardKeys:
          claimedObjectiveRewardKeys ?? this.claimedObjectiveRewardKeys,
      currentSagaId: currentSagaId ?? this.currentSagaId,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      unlocks: unlocks ?? this.unlocks,
      eternalXiCardsGranted:
          eternalXiCardsGranted ?? this.eternalXiCardsGranted,
      walletGems: walletGems ?? this.walletGems,
      walletCoins: walletCoins ?? this.walletCoins,
    );
  }

  Map<String, dynamic> toJson() => {
    'completedLevelIds': completedLevelIds.toList(),
    'claimedRewardLevelIds': claimedRewardLevelIds.toList(),
    'claimedObjectiveRewardKeys': claimedObjectiveRewardKeys.toList(),
    'currentSagaId': currentSagaId,
    'currentChapterId': currentChapterId,
    'unlocks': unlocks.toJson(),
    'eternalXiCardsGranted': eternalXiCardsGranted,
    'walletGems': walletGems,
    'walletCoins': walletCoins,
  };

  factory ClashStoryProgress.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completedLevelIds'] as List? ?? const [];
    final claimedRaw = json['claimedRewardLevelIds'] as List? ?? const [];
    final objectiveClaimedRaw =
        json['claimedObjectiveRewardKeys'] as List? ?? const [];
    return ClashStoryProgress(
      completedLevelIds: completedRaw.map((id) => id.toString()).toSet(),
      claimedRewardLevelIds: claimedRaw.map((id) => id.toString()).toSet(),
      claimedObjectiveRewardKeys: objectiveClaimedRaw
          .map((id) => id.toString())
          .toSet(),
      currentSagaId: json['currentSagaId']?.toString() ?? 'saga-01',
      currentChapterId: json['currentChapterId']?.toString() ?? 'chapter-01',
      unlocks: ClashStoryCompletionUnlocks.fromJson(
        json['unlocks'] as Map<String, dynamic>?,
      ),
      eternalXiCardsGranted: json['eternalXiCardsGranted'] == true,
      walletGems: json['walletGems'] as int? ?? 0,
      walletCoins: json['walletCoins'] as int? ?? 0,
    );
  }
}

/// Resultado de completar un nivel de historia.
class ClashStoryCompletionResult {
  const ClashStoryCompletionResult({
    required this.levelId,
    required this.rewardsGranted,
    required this.newlyGrantedCardIds,
    required this.unlocks,
    required this.firstCompletion,
    this.objectiveResults = const [],
  });

  final String levelId;
  final ClashStoryReward rewardsGranted;
  final List<String> newlyGrantedCardIds;
  final ClashStoryCompletionUnlocks unlocks;
  final bool firstCompletion;
  final List<ClashMatchObjectiveProgress> objectiveResults;
}

import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_local_datasource.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_claim_result.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Logros permanentes locales Clash (Fase 29).
class ClashAchievementsRepository {
  ClashAchievementsRepository({
    required ClashAchievementsLocalDataSource dataSource,
    required ClashAchievementsStorageBackend storage,
    required ClashStoryRepository storyRepository,
    required ClashLocalRewardGranter rewardGranter,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _storyRepository = storyRepository,
       _rewardGranter = rewardGranter,
       _now = now ?? DateTime.now;

  final ClashAchievementsLocalDataSource _dataSource;
  final ClashAchievementsStorageBackend _storage;
  final ClashStoryRepository _storyRepository;
  final ClashLocalRewardGranter _rewardGranter;
  final DateTime Function() _now;

  List<ClashAchievement>? _achievementsCache;
  ClashAchievementsState? _stateCache;

  Future<List<ClashAchievement>> _loadAchievementCatalog() async {
    _achievementsCache ??= await _dataSource.loadAchievements();
    return _achievementsCache!;
  }

  Future<ClashAchievementsState> loadState() async {
    if (_stateCache != null) {
      return _stateCache!;
    }
    final stored = _storage.readState();
    _stateCache = stored ?? const ClashAchievementsState();
    if (stored == null) {
      await _storage.writeState(_stateCache!);
    }
    return _stateCache!;
  }

  Future<List<ClashAchievementProgress>> fetchAchievementProgress() async {
    final achievements = await _loadAchievementCatalog();
    final state = await loadState();
    return achievements
        .map(
          (achievement) => ClashAchievementProgress(
            achievement: achievement,
            current: state.progress[achievement.id] ?? 0,
            claimed: state.claimedAchievementIds.contains(achievement.id),
          ),
        )
        .toList(growable: false);
  }

  Future<ClashAchievementsSummary> fetchSummary() async {
    final progress = await fetchAchievementProgress();
    final completed = progress.where((item) => item.isCompleted).length;
    final claimed = progress.where((item) => item.claimed).length;
    final claimable = progress.where((item) => item.canClaim).length;
    return ClashAchievementsSummary(
      totalAchievements: progress.length,
      completedCount: completed,
      claimedCount: claimed,
      claimableCount: claimable,
    );
  }

  Future<List<ClashAchievementProgress>> recordAchievementEvent(
    ClashAchievementType type, {
    int amount = 1,
    bool absolute = false,
  }) async {
    if (amount <= 0) {
      return fetchAchievementProgress();
    }
    final achievements = await _loadAchievementCatalog();
    final state = await loadState();
    final progressMap = Map<String, int>.from(state.progress);

    for (final achievement in achievements) {
      if (achievement.type != type) {
        continue;
      }
      final current = progressMap[achievement.id] ?? 0;
      if (current >= achievement.target) {
        continue;
      }
      final next = absolute
          ? amount.clamp(0, achievement.target)
          : (current + amount).clamp(0, achievement.target);
      progressMap[achievement.id] = next;
    }

    final updated = state.copyWith(
      progress: progressMap,
      updatedAt: _now().toIso8601String(),
    );
    _stateCache = updated;
    await _storage.writeState(updated);
    return fetchAchievementProgress();
  }

  Future<ClashAchievementClaimResult> claimAchievement(
    String achievementId,
  ) async {
    final achievements = await _loadAchievementCatalog();
    ClashAchievement? achievement;
    for (final item in achievements) {
      if (item.id == achievementId) {
        achievement = item;
        break;
      }
    }
    if (achievement == null) {
      return ClashAchievementClaimResult.failure(
        achievementId: achievementId,
        error: ClashAchievementClaimError.achievementNotFound,
      );
    }

    final state = await loadState();
    final current = state.progress[achievementId] ?? 0;
    if (current < achievement.target) {
      return ClashAchievementClaimResult.failure(
        achievementId: achievementId,
        error: ClashAchievementClaimError.notCompleted,
      );
    }
    if (state.claimedAchievementIds.contains(achievementId)) {
      return ClashAchievementClaimResult.failure(
        achievementId: achievementId,
        error: ClashAchievementClaimError.alreadyClaimed,
      );
    }

    final granted = await _grantReward(achievement.reward);
    if (!granted) {
      return ClashAchievementClaimResult.failure(
        achievementId: achievementId,
        error: ClashAchievementClaimError.grantFailed,
      );
    }

    final claimed = Set<String>.from(state.claimedAchievementIds)
      ..add(achievementId);
    final updated = state.copyWith(
      claimedAchievementIds: claimed,
      updatedAt: _now().toIso8601String(),
    );
    _stateCache = updated;
    await _storage.writeState(updated);

    return ClashAchievementClaimResult(
      success: true,
      achievementId: achievementId,
      reward: achievement.reward,
    );
  }

  Future<List<ClashAchievementClaimResult>> claimAllCompleted() async {
    final progress = await fetchAchievementProgress();
    final results = <ClashAchievementClaimResult>[];
    for (final item in progress) {
      if (!item.canClaim) {
        continue;
      }
      results.add(await claimAchievement(item.achievement.id));
    }
    return results;
  }

  Future<bool> _grantReward(ClashAchievementReward reward) async {
    if (reward.isEmpty) {
      return true;
    }
    final result = await _rewardGranter.grantAll(
      ClashRewardConverters.fromAchievementReward(reward),
    );
    return result.isFullyGranted;
  }

  void clearCacheForTests() {
    _achievementsCache = null;
    _stateCache = null;
    _dataSource.clearCacheForTests();
  }

  Future<void> resetForTests() async {
    clearCacheForTests();
    await _storage.clear();
  }
}

import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Misiones diarias locales Clash (Fase 28).
class ClashDailyMissionsRepository {
  ClashDailyMissionsRepository({
    required ClashDailyMissionsLocalDataSource dataSource,
    required ClashDailyMissionsStorageBackend storage,
    required ClashStoryRepository storyRepository,
    required ClashLocalRewardGranter rewardGranter,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _storyRepository = storyRepository,
       _rewardGranter = rewardGranter,
       _now = now ?? DateTime.now;

  final ClashDailyMissionsLocalDataSource _dataSource;
  final ClashDailyMissionsStorageBackend _storage;
  final ClashStoryRepository _storyRepository;
  final ClashLocalRewardGranter _rewardGranter;
  final DateTime Function() _now;

  List<ClashDailyMission>? _missionsCache;
  ClashDailyMissionsDayState? _dayCache;

  String localDateKey() {
    final now = _now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<ClashDailyMission>> _loadMissionCatalog() async {
    _missionsCache ??= await _dataSource.loadMissions();
    return _missionsCache!;
  }

  Future<ClashDailyMissionsDayState> loadDayState() async {
    if (_dayCache != null) {
      return _dayCache!;
    }
    final today = localDateKey();
    final stored = _storage.readState();
    if (stored == null || stored.localDate != today) {
      _dayCache = ClashDailyMissionsDayState(localDate: today);
      await _storage.writeState(_dayCache!);
      return _dayCache!;
    }
    _dayCache = stored;
    return _dayCache!;
  }

  Future<List<ClashDailyMissionProgress>> fetchMissionProgress() async {
    final missions = await _loadMissionCatalog();
    final day = await loadDayState();
    return missions
        .map(
          (mission) => ClashDailyMissionProgress(
            mission: mission,
            current: day.progress[mission.id] ?? 0,
            claimed: day.claimedMissionIds.contains(mission.id),
          ),
        )
        .toList(growable: false);
  }

  Future<ClashDailyMissionsSummary> fetchSummary() async {
    final progress = await fetchMissionProgress();
    final completed = progress.where((item) => item.isCompleted).length;
    final claimed = progress.where((item) => item.claimed).length;
    final claimable = progress.where((item) => item.canClaim).length;
    return ClashDailyMissionsSummary(
      totalMissions: progress.length,
      completedCount: completed,
      claimedCount: claimed,
      claimableCount: claimable,
    );
  }

  Future<List<ClashDailyMissionProgress>> recordDailyMissionEvent(
    ClashDailyMissionType type, {
    int amount = 1,
  }) async {
    if (amount <= 0) {
      return fetchMissionProgress();
    }
    final missions = await _loadMissionCatalog();
    final day = await loadDayState();
    final progressMap = Map<String, int>.from(day.progress);

    for (final mission in missions) {
      if (mission.type != type) {
        continue;
      }
      final current = progressMap[mission.id] ?? 0;
      if (current >= mission.target) {
        continue;
      }
      final next = (current + amount).clamp(0, mission.target);
      progressMap[mission.id] = next;
    }

    final updated = day.copyWith(progress: progressMap);
    _dayCache = updated;
    await _storage.writeState(updated);
    return fetchMissionProgress();
  }

  Future<ClashDailyMissionClaimResult> claimMission(String missionId) async {
    final missions = await _loadMissionCatalog();
    ClashDailyMission? mission;
    for (final item in missions) {
      if (item.id == missionId) {
        mission = item;
        break;
      }
    }
    if (mission == null) {
      return ClashDailyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashDailyMissionClaimError.missionNotFound,
      );
    }

    final day = await loadDayState();
    final current = day.progress[missionId] ?? 0;
    if (current < mission.target) {
      return ClashDailyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashDailyMissionClaimError.notCompleted,
      );
    }
    if (day.claimedMissionIds.contains(missionId)) {
      return ClashDailyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashDailyMissionClaimError.alreadyClaimed,
      );
    }

    final granted = await _grantReward(mission.reward);
    if (!granted) {
      return ClashDailyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashDailyMissionClaimError.grantFailed,
      );
    }

    final claimed = Set<String>.from(day.claimedMissionIds)..add(missionId);
    final updated = day.copyWith(claimedMissionIds: claimed);
    _dayCache = updated;
    await _storage.writeState(updated);

    return ClashDailyMissionClaimResult(
      success: true,
      missionId: missionId,
      reward: mission.reward,
    );
  }

  Future<List<ClashDailyMissionClaimResult>> claimAllCompleted() async {
    final progress = await fetchMissionProgress();
    final results = <ClashDailyMissionClaimResult>[];
    for (final item in progress) {
      if (!item.canClaim) {
        continue;
      }
      results.add(await claimMission(item.mission.id));
    }
    return results;
  }

  Future<bool> _grantReward(ClashDailyMissionReward reward) async {
    if (reward.isEmpty) {
      return true;
    }
    final result = await _rewardGranter.grantAll(
      ClashRewardConverters.fromDailyMissionReward(reward),
    );
    return result.isFullyGranted;
  }

  void clearCacheForTests() {
    _missionsCache = null;
    _dayCache = null;
    _dataSource.clearCacheForTests();
  }

  Future<void> resetForTests() async {
    clearCacheForTests();
    await _storage.clear();
  }
}

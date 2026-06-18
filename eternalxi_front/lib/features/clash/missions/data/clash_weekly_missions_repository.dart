import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_claim_result.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_reward.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_type.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Misiones semanales locales Clash (Fase 30).
class ClashWeeklyMissionsRepository {
  ClashWeeklyMissionsRepository({
    required ClashWeeklyMissionsLocalDataSource dataSource,
    required ClashWeeklyMissionsStorageBackend storage,
    required ClashStoryRepository storyRepository,
    required ClashShopGrantService grantService,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _storyRepository = storyRepository,
       _grantService = grantService,
       _now = now ?? DateTime.now;

  final ClashWeeklyMissionsLocalDataSource _dataSource;
  final ClashWeeklyMissionsStorageBackend _storage;
  final ClashStoryRepository _storyRepository;
  final ClashShopGrantService _grantService;
  final DateTime Function() _now;

  List<ClashWeeklyMission>? _missionsCache;
  ClashWeeklyMissionsWeekState? _weekCache;

  /// Lunes local de la semana actual en formato yyyy-MM-dd.
  String localWeekKey() {
    final now = _now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final y = monday.year.toString().padLeft(4, '0');
    final m = monday.month.toString().padLeft(2, '0');
    final d = monday.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<ClashWeeklyMission>> _loadMissionCatalog() async {
    _missionsCache ??= await _dataSource.loadMissions();
    return _missionsCache!;
  }

  Future<ClashWeeklyMissionsWeekState> loadWeekState() async {
    if (_weekCache != null) {
      return _weekCache!;
    }
    final currentWeek = localWeekKey();
    final stored = _storage.readState();
    if (stored == null || stored.weekKey != currentWeek) {
      _weekCache = ClashWeeklyMissionsWeekState(weekKey: currentWeek);
      await _storage.writeState(_weekCache!);
      return _weekCache!;
    }
    _weekCache = stored;
    return _weekCache!;
  }

  Future<List<ClashWeeklyMissionProgress>> fetchMissionProgress() async {
    final missions = await _loadMissionCatalog();
    final week = await loadWeekState();
    return missions
        .map(
          (mission) => ClashWeeklyMissionProgress(
            mission: mission,
            current: week.progress[mission.id] ?? 0,
            claimed: week.claimedMissionIds.contains(mission.id),
          ),
        )
        .toList(growable: false);
  }

  Future<ClashWeeklyMissionsSummary> fetchSummary() async {
    final progress = await fetchMissionProgress();
    final week = await loadWeekState();
    final completed = progress.where((item) => item.isCompleted).length;
    final claimed = progress.where((item) => item.claimed).length;
    final claimable = progress.where((item) => item.canClaim).length;
    return ClashWeeklyMissionsSummary(
      totalMissions: progress.length,
      completedCount: completed,
      claimedCount: claimed,
      claimableCount: claimable,
      weekKey: week.weekKey,
    );
  }

  Future<List<ClashWeeklyMissionProgress>> recordWeeklyMissionEvent(
    ClashWeeklyMissionType type, {
    int amount = 1,
  }) async {
    if (amount <= 0) {
      return fetchMissionProgress();
    }
    final missions = await _loadMissionCatalog();
    final week = await loadWeekState();
    final progressMap = Map<String, int>.from(week.progress);

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

    final updated = week.copyWith(progress: progressMap);
    _weekCache = updated;
    await _storage.writeState(updated);
    return fetchMissionProgress();
  }

  Future<ClashWeeklyMissionClaimResult> claimMission(String missionId) async {
    final missions = await _loadMissionCatalog();
    ClashWeeklyMission? mission;
    for (final item in missions) {
      if (item.id == missionId) {
        mission = item;
        break;
      }
    }
    if (mission == null) {
      return ClashWeeklyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashWeeklyMissionClaimError.missionNotFound,
      );
    }

    final week = await loadWeekState();
    final current = week.progress[missionId] ?? 0;
    if (current < mission.target) {
      return ClashWeeklyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashWeeklyMissionClaimError.notCompleted,
      );
    }
    if (week.claimedMissionIds.contains(missionId)) {
      return ClashWeeklyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashWeeklyMissionClaimError.alreadyClaimed,
      );
    }

    final granted = await _grantReward(mission.reward);
    if (!granted) {
      return ClashWeeklyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashWeeklyMissionClaimError.grantFailed,
      );
    }

    final claimed = Set<String>.from(week.claimedMissionIds)..add(missionId);
    final updated = week.copyWith(claimedMissionIds: claimed);
    _weekCache = updated;
    await _storage.writeState(updated);

    return ClashWeeklyMissionClaimResult(
      success: true,
      missionId: missionId,
      reward: mission.reward,
    );
  }

  Future<List<ClashWeeklyMissionClaimResult>> claimAllCompleted() async {
    final progress = await fetchMissionProgress();
    final results = <ClashWeeklyMissionClaimResult>[];
    for (final item in progress) {
      if (!item.canClaim) {
        continue;
      }
      results.add(await claimMission(item.mission.id));
    }
    return results;
  }

  Future<bool> _grantReward(ClashWeeklyMissionReward reward) async {
    if (reward.isEmpty) {
      return true;
    }
    try {
      if (reward.coins > 0) {
        await _storyRepository.addCoins(reward.coins);
      }
      if (reward.gems > 0) {
        await _storyRepository.addGems(reward.gems);
      }
      final itemGrants = reward.toProductGrants();
      if (itemGrants.isNotEmpty) {
        final granted = await _grantService.grantProductGrants(itemGrants);
        if (!granted) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearCacheForTests() {
    _missionsCache = null;
    _weekCache = null;
    _dataSource.clearCacheForTests();
  }

  Future<void> resetForTests() async {
    clearCacheForTests();
    await _storage.clear();
  }
}

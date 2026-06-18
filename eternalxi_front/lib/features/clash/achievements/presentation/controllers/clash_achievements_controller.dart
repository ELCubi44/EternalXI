import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_claim_result.dart';
import 'package:flutter/foundation.dart';

enum ClashAchievementsLoadState { idle, loading, ready, claiming }

class ClashAchievementsController extends ChangeNotifier {
  ClashAchievementsController({required ClashAchievementsRepository repository})
    : _repository = repository;

  final ClashAchievementsRepository _repository;

  ClashAchievementsLoadState _state = ClashAchievementsLoadState.idle;
  List<ClashAchievementProgress> _achievements = const [];
  ClashAchievementsSummary _summary = const ClashAchievementsSummary(
    totalAchievements: 0,
    completedCount: 0,
    claimedCount: 0,
    claimableCount: 0,
  );
  ClashAchievementFilter _filter = ClashAchievementFilter.all;
  String? _errorMessage;

  ClashAchievementsLoadState get state => _state;
  List<ClashAchievementProgress> get achievements => _achievements;
  ClashAchievementsSummary get summary => _summary;
  ClashAchievementFilter get filter => _filter;
  String? get errorMessage => _errorMessage;

  List<ClashAchievementProgress> get filteredAchievements {
    return _achievements
        .where((item) {
          return switch (_filter) {
            ClashAchievementFilter.all => true,
            ClashAchievementFilter.inProgress =>
              !item.isCompleted && !item.claimed,
            ClashAchievementFilter.completed =>
              item.isCompleted && !item.claimed,
            ClashAchievementFilter.claimed => item.claimed,
          };
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _state = ClashAchievementsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _achievements = await _repository.fetchAchievementProgress();
      _summary = await _repository.fetchSummary();
      _state = ClashAchievementsLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashAchievementsLoadState.ready;
    }
    notifyListeners();
  }

  void setFilter(ClashAchievementFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }

  Future<ClashAchievementClaimResult> claimAchievement(
    String achievementId,
  ) async {
    if (_state == ClashAchievementsLoadState.claiming) {
      return ClashAchievementClaimResult.failure(
        achievementId: achievementId,
        error: ClashAchievementClaimError.alreadyClaimed,
      );
    }
    _state = ClashAchievementsLoadState.claiming;
    notifyListeners();

    final result = await _repository.claimAchievement(achievementId);
    _achievements = await _repository.fetchAchievementProgress();
    _summary = await _repository.fetchSummary();
    _state = ClashAchievementsLoadState.ready;
    notifyListeners();
    return result;
  }

  Future<List<ClashAchievementClaimResult>> claimAll() async {
    if (_state == ClashAchievementsLoadState.claiming) {
      return const [];
    }
    _state = ClashAchievementsLoadState.claiming;
    notifyListeners();

    final results = await _repository.claimAllCompleted();
    _achievements = await _repository.fetchAchievementProgress();
    _summary = await _repository.fetchSummary();
    _state = ClashAchievementsLoadState.ready;
    notifyListeners();
    return results;
  }
}

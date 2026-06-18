import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_claim_result.dart';
import 'package:flutter/foundation.dart';

enum ClashWeeklyMissionsLoadState { idle, loading, ready, claiming }

class ClashWeeklyMissionsController extends ChangeNotifier {
  ClashWeeklyMissionsController({
    required ClashWeeklyMissionsRepository repository,
  }) : _repository = repository;

  final ClashWeeklyMissionsRepository _repository;

  ClashWeeklyMissionsLoadState _state = ClashWeeklyMissionsLoadState.idle;
  List<ClashWeeklyMissionProgress> _missions = const [];
  ClashWeeklyMissionsSummary _summary = const ClashWeeklyMissionsSummary(
    totalMissions: 0,
    completedCount: 0,
    claimedCount: 0,
    claimableCount: 0,
    weekKey: '',
  );
  String? _errorMessage;

  ClashWeeklyMissionsLoadState get state => _state;
  List<ClashWeeklyMissionProgress> get missions => _missions;
  ClashWeeklyMissionsSummary get summary => _summary;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = ClashWeeklyMissionsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _missions = await _repository.fetchMissionProgress();
      _summary = await _repository.fetchSummary();
      _state = ClashWeeklyMissionsLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashWeeklyMissionsLoadState.ready;
    }
    notifyListeners();
  }

  Future<ClashWeeklyMissionClaimResult> claimMission(String missionId) async {
    if (_state == ClashWeeklyMissionsLoadState.claiming) {
      return ClashWeeklyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashWeeklyMissionClaimError.alreadyClaimed,
      );
    }
    _state = ClashWeeklyMissionsLoadState.claiming;
    notifyListeners();

    final result = await _repository.claimMission(missionId);
    _missions = await _repository.fetchMissionProgress();
    _summary = await _repository.fetchSummary();
    _state = ClashWeeklyMissionsLoadState.ready;
    notifyListeners();
    return result;
  }

  Future<List<ClashWeeklyMissionClaimResult>> claimAll() async {
    if (_state == ClashWeeklyMissionsLoadState.claiming) {
      return const [];
    }
    _state = ClashWeeklyMissionsLoadState.claiming;
    notifyListeners();

    final results = await _repository.claimAllCompleted();
    _missions = await _repository.fetchMissionProgress();
    _summary = await _repository.fetchSummary();
    _state = ClashWeeklyMissionsLoadState.ready;
    notifyListeners();
    return results;
  }
}

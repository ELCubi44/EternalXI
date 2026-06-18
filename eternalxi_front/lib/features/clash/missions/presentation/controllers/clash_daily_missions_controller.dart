import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_claim_result.dart';
import 'package:flutter/foundation.dart';

enum ClashDailyMissionsLoadState { idle, loading, ready, claiming }

class ClashDailyMissionsController extends ChangeNotifier {
  ClashDailyMissionsController({
    required ClashDailyMissionsRepository repository,
  }) : _repository = repository;

  final ClashDailyMissionsRepository _repository;

  ClashDailyMissionsLoadState _state = ClashDailyMissionsLoadState.idle;
  List<ClashDailyMissionProgress> _missions = const [];
  ClashDailyMissionsSummary _summary = const ClashDailyMissionsSummary(
    totalMissions: 0,
    completedCount: 0,
    claimedCount: 0,
    claimableCount: 0,
  );
  String? _errorMessage;

  ClashDailyMissionsLoadState get state => _state;
  List<ClashDailyMissionProgress> get missions => _missions;
  ClashDailyMissionsSummary get summary => _summary;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = ClashDailyMissionsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _missions = await _repository.fetchMissionProgress();
      _summary = await _repository.fetchSummary();
      _state = ClashDailyMissionsLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashDailyMissionsLoadState.ready;
    }
    notifyListeners();
  }

  Future<ClashDailyMissionClaimResult> claimMission(String missionId) async {
    if (_state == ClashDailyMissionsLoadState.claiming) {
      return ClashDailyMissionClaimResult.failure(
        missionId: missionId,
        error: ClashDailyMissionClaimError.alreadyClaimed,
      );
    }
    _state = ClashDailyMissionsLoadState.claiming;
    notifyListeners();

    final result = await _repository.claimMission(missionId);
    _missions = await _repository.fetchMissionProgress();
    _summary = await _repository.fetchSummary();
    _state = ClashDailyMissionsLoadState.ready;
    notifyListeners();
    return result;
  }

  Future<List<ClashDailyMissionClaimResult>> claimAll() async {
    if (_state == ClashDailyMissionsLoadState.claiming) {
      return const [];
    }
    _state = ClashDailyMissionsLoadState.claiming;
    notifyListeners();

    final results = await _repository.claimAllCompleted();
    _missions = await _repository.fetchMissionProgress();
    _summary = await _repository.fetchSummary();
    _state = ClashDailyMissionsLoadState.ready;
    notifyListeners();
    return results;
  }
}

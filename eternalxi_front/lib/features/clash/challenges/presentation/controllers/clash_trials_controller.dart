import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_storage.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:flutter/foundation.dart';

enum ClashTrialsLoadState { idle, loading, ready, error }

class ClashTrialsController extends ChangeNotifier {
  ClashTrialsController({required ClashTrialsRepository repository})
    : _repository = repository;

  final ClashTrialsRepository _repository;

  ClashTrialsLoadState state = ClashTrialsLoadState.idle;
  List<ClashTrialSummary> summaries = const [];
  List<ClashTrialFloorProgress> floorProgress = const [];
  ClashTrial? activeTrial;
  int remainingAttempts = ClashTrialsProgressState.dailyAttemptLimit;
  String? errorMessage;

  Future<void> loadTrials() async {
    state = ClashTrialsLoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final progress = await _repository.loadState();
      summaries = await _repository.fetchTrialSummaries();
      remainingAttempts = _repository.remainingDailyAttempts(progress);
      state = ClashTrialsLoadState.ready;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      errorMessage = error.toString();
      state = ClashTrialsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> openTrial(String trialId) async {
    activeTrial = await _repository.findTrialById(trialId);
    floorProgress = await _repository.fetchFloorProgress(trialId);
    final progress = await _repository.loadState();
    remainingAttempts = _repository.remainingDailyAttempts(progress);
    notifyListeners();
  }

  void clearActiveTrial() {
    activeTrial = null;
    floorProgress = const [];
    notifyListeners();
  }
}

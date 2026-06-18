import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';

/// Puente opcional para registrar eventos sin dependencia circular (Fase 28).
class ClashDailyMissionEventSink {
  ClashDailyMissionsRepository? _repository;

  void bind(ClashDailyMissionsRepository repository) {
    _repository = repository;
  }

  void unbindForTests() {
    _repository = null;
  }

  Future<void> record(ClashDailyMissionType type, {int amount = 1}) async {
    try {
      await _repository?.recordDailyMissionEvent(type, amount: amount);
    } catch (_) {}
  }
}

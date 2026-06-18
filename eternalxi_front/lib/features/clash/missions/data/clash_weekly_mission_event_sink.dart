import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission_type.dart';

/// Puente opcional para registrar misiones semanales (Fase 30).
class ClashWeeklyMissionEventSink {
  ClashWeeklyMissionsRepository? _repository;

  void bind(ClashWeeklyMissionsRepository repository) {
    _repository = repository;
  }

  void unbindForTests() {
    _repository = null;
  }

  Future<void> record(ClashWeeklyMissionType type, {int amount = 1}) async {
    try {
      await _repository?.recordWeeklyMissionEvent(type, amount: amount);
    } catch (_) {}
  }
}

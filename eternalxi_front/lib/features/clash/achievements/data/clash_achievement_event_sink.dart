import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_type.dart';

/// Puente opcional para registrar logros sin dependencia circular (Fase 29).
class ClashAchievementEventSink {
  ClashAchievementsRepository? _repository;

  void bind(ClashAchievementsRepository repository) {
    _repository = repository;
  }

  void unbindForTests() {
    _repository = null;
  }

  Future<void> record(
    ClashAchievementType type, {
    int amount = 1,
    bool absolute = false,
  }) async {
    try {
      await _repository?.recordAchievementEvent(
        type,
        amount: amount,
        absolute: absolute,
      );
    } catch (_) {}
  }
}

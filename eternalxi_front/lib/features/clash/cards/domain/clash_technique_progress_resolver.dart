import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';

/// Resuelve niveles de supertécnica desde progreso persistido (Fase 19).
class ClashTechniqueProgressResolver {
  const ClashTechniqueProgressResolver._();

  static ClashTechniqueLevel resolvedLevel({
    required ClashSuperTechnique technique,
    ClashCardProgress? progress,
  }) {
    final stored = progress?.techniqueLevels[technique.id];
    if (stored != null) {
      return stored;
    }
    return technique.level;
  }

  static ClashSuperTechnique withResolvedLevel({
    required ClashSuperTechnique technique,
    ClashCardProgress? progress,
  }) {
    final level = resolvedLevel(technique: technique, progress: progress);
    return technique.withLevel(level);
  }

  static List<ClashSuperTechnique> resolvedTechniques({
    required Iterable<ClashSuperTechnique> techniques,
    ClashCardProgress? progress,
  }) {
    return techniques
        .map(
          (technique) =>
              withResolvedLevel(technique: technique, progress: progress),
        )
        .toList(growable: false);
  }

  static int effectivePower({
    required ClashSuperTechnique technique,
    ClashCardProgress? progress,
  }) {
    final level = resolvedLevel(technique: technique, progress: progress);
    return (technique.basePower * level.powerMultiplier).round();
  }
}

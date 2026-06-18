import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Adapta recompensas de historia (strings/items) a IDs de materiales EXP.
class ClashExpMaterialRewardAdapter {
  const ClashExpMaterialRewardAdapter._();

  /// Recompensa del objetivo Nivel 4 (libro básico) → manual básico.
  static const rewardItemToMaterialId = <String, String>{
    'basic-book': 'basic-training-manual',
  };

  static String? mapRewardItemId(String itemId) {
    return rewardItemToMaterialId[itemId];
  }

  static Map<String, int> quantitiesFromStoryReward(ClashStoryReward reward) {
    final quantities = <String, int>{};

    for (final item in reward.items) {
      final materialId = mapRewardItemId(item.id);
      if (materialId == null) {
        continue;
      }
      quantities[materialId] = (quantities[materialId] ?? 0) + item.quantity;
    }

    for (final material in reward.materials) {
      quantities[material.id] =
          (quantities[material.id] ?? 0) + material.quantity;
    }

    return quantities;
  }
}

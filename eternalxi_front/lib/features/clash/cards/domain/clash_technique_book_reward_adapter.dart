import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Adapta recompensas de historia a libros de técnica.
class ClashTechniqueBookRewardAdapter {
  const ClashTechniqueBookRewardAdapter._();

  static const rewardItemToBookId = <String, String>{
    'technique-basic-book': 'basic-technique-book',
    'technique-advanced-book': 'advanced-technique-book',
    'technique-master-book': 'master-technique-book',
  };

  static String? mapRewardItemId(String itemId) {
    return rewardItemToBookId[itemId];
  }

  static Map<String, int> quantitiesFromStoryReward(ClashStoryReward reward) {
    final quantities = <String, int>{};

    for (final item in reward.items) {
      final bookId = mapRewardItemId(item.id);
      if (bookId == null) {
        continue;
      }
      quantities[bookId] = (quantities[bookId] ?? 0) + item.quantity;
    }

    for (final material in reward.materials) {
      final bookId = mapRewardItemId(material.id);
      if (bookId == null) {
        continue;
      }
      quantities[bookId] = (quantities[bookId] ?? 0) + material.quantity;
    }

    return quantities;
  }
}

import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Adapta recompensas de historia a tickets de gacha (Fase 26).
class ClashGachaTicketRewardAdapter {
  const ClashGachaTicketRewardAdapter._();

  static const rewardItemToTicketId = <String, String>{
    'starter-single-ticket': 'starter-single-ticket',
  };

  static String? mapRewardItemId(String itemId) {
    return rewardItemToTicketId[itemId];
  }

  static Map<String, int> quantitiesFromStoryReward(ClashStoryReward reward) {
    final quantities = <String, int>{};
    for (final item in reward.items) {
      final ticketId = mapRewardItemId(item.id);
      if (ticketId == null) {
        continue;
      }
      quantities[ticketId] = (quantities[ticketId] ?? 0) + item.quantity;
    }
    return quantities;
  }
}

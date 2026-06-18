import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Recompensas de fase de evento (firstClear o repeat).
class ClashCharacterEventReward {
  const ClashCharacterEventReward({
    this.coins = 0,
    this.gems = 0,
    this.expMaterial,
    this.techniqueBook,
    this.evolutionMaterial,
    this.ticket,
    this.featuredCardId,
    this.featuredCardAsDuplicate = false,
  });

  final int coins;
  final int gems;
  final ClashAchievementItemReward? expMaterial;
  final ClashAchievementItemReward? techniqueBook;
  final ClashAchievementItemReward? evolutionMaterial;
  final ClashAchievementItemReward? ticket;
  final String? featuredCardId;
  final bool featuredCardAsDuplicate;

  bool get isEmpty =>
      coins <= 0 &&
      gems <= 0 &&
      expMaterial == null &&
      techniqueBook == null &&
      evolutionMaterial == null &&
      ticket == null &&
      featuredCardId == null;

  ClashAchievementReward toAchievementReward() {
    return ClashAchievementReward(
      coins: coins,
      gems: gems,
      expMaterial: expMaterial,
      techniqueBook: techniqueBook,
      evolutionMaterial: evolutionMaterial,
      ticket: ticket,
    );
  }

  factory ClashCharacterEventReward.fromJson(Map<String, dynamic> json) {
    ClashAchievementItemReward? item(Map<String, dynamic>? raw) {
      if (raw == null) {
        return null;
      }
      return ClashAchievementItemReward.fromJson(raw);
    }

    return ClashCharacterEventReward(
      coins: clashAsInt(json['coins']),
      gems: clashAsInt(json['gems']),
      expMaterial: item(json['expMaterial'] as Map<String, dynamic>?),
      techniqueBook: item(json['techniqueBook'] as Map<String, dynamic>?),
      evolutionMaterial: item(
        json['evolutionMaterial'] as Map<String, dynamic>?,
      ),
      ticket: item(json['ticket'] as Map<String, dynamic>?),
      featuredCardId: clashOptionalString(json['featuredCardId']),
      featuredCardAsDuplicate: json['featuredCardAsDuplicate'] == true,
    );
  }
}

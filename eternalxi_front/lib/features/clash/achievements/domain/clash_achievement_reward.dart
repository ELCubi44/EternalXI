import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';

class ClashAchievementItemReward {
  const ClashAchievementItemReward({required this.id, required this.quantity});

  final String id;
  final int quantity;

  factory ClashAchievementItemReward.fromJson(Map<String, dynamic> json) {
    return ClashAchievementItemReward(
      id: clashRequireString(json['id'], 'id'),
      quantity: clashAsInt(json['quantity'], fallback: 1),
    );
  }
}

/// Recompensa local de un logro Clash (Fase 29).
class ClashAchievementReward {
  const ClashAchievementReward({
    this.coins = 0,
    this.gems = 0,
    this.expMaterial,
    this.techniqueBook,
    this.evolutionMaterial,
    this.ticket,
  });

  final int coins;
  final int gems;
  final ClashAchievementItemReward? expMaterial;
  final ClashAchievementItemReward? techniqueBook;
  final ClashAchievementItemReward? evolutionMaterial;
  final ClashAchievementItemReward? ticket;

  bool get isEmpty =>
      coins <= 0 &&
      gems <= 0 &&
      expMaterial == null &&
      techniqueBook == null &&
      evolutionMaterial == null &&
      ticket == null;

  factory ClashAchievementReward.fromJson(Map<String, dynamic> json) {
    ClashAchievementItemReward? item(Map<String, dynamic>? raw) {
      if (raw == null) {
        return null;
      }
      return ClashAchievementItemReward.fromJson(raw);
    }

    return ClashAchievementReward(
      coins: clashAsInt(json['coins']),
      gems: clashAsInt(json['gems']),
      expMaterial: item(json['expMaterial'] as Map<String, dynamic>?),
      techniqueBook: item(json['techniqueBook'] as Map<String, dynamic>?),
      evolutionMaterial: item(
        json['evolutionMaterial'] as Map<String, dynamic>?,
      ),
      ticket: item(json['ticket'] as Map<String, dynamic>?),
    );
  }

  List<ClashShopProductGrant> toProductGrants() {
    final grants = <ClashShopProductGrant>[];
    void addItem(
      ClashShopProductType type,
      ClashAchievementItemReward? reward,
    ) {
      if (reward == null || reward.quantity <= 0) {
        return;
      }
      grants.add(
        ClashShopProductGrant(
          type: type,
          id: reward.id,
          quantity: reward.quantity,
          label: reward.id,
        ),
      );
    }

    addItem(ClashShopProductType.expMaterial, expMaterial);
    addItem(ClashShopProductType.techniqueBook, techniqueBook);
    addItem(ClashShopProductType.evolutionMaterial, evolutionMaterial);
    addItem(ClashShopProductType.ticket, ticket);
    return grants;
  }
}

import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';

class ClashWeeklyMissionItemReward {
  const ClashWeeklyMissionItemReward({
    required this.id,
    required this.quantity,
  });

  final String id;
  final int quantity;

  factory ClashWeeklyMissionItemReward.fromJson(Map<String, dynamic> json) {
    return ClashWeeklyMissionItemReward(
      id: clashRequireString(json['id'], 'id'),
      quantity: clashAsInt(json['quantity'], fallback: 1),
    );
  }
}

/// Recompensa local de una misión semanal (Fase 30).
class ClashWeeklyMissionReward {
  const ClashWeeklyMissionReward({
    this.coins = 0,
    this.gems = 0,
    this.expMaterial,
    this.techniqueBook,
    this.evolutionMaterial,
    this.ticket,
  });

  final int coins;
  final int gems;
  final ClashWeeklyMissionItemReward? expMaterial;
  final ClashWeeklyMissionItemReward? techniqueBook;
  final ClashWeeklyMissionItemReward? evolutionMaterial;
  final ClashWeeklyMissionItemReward? ticket;

  bool get isEmpty =>
      coins <= 0 &&
      gems <= 0 &&
      expMaterial == null &&
      techniqueBook == null &&
      evolutionMaterial == null &&
      ticket == null;

  factory ClashWeeklyMissionReward.fromJson(Map<String, dynamic> json) {
    ClashWeeklyMissionItemReward? item(Map<String, dynamic>? raw) {
      if (raw == null) {
        return null;
      }
      return ClashWeeklyMissionItemReward.fromJson(raw);
    }

    return ClashWeeklyMissionReward(
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
      ClashWeeklyMissionItemReward? reward,
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

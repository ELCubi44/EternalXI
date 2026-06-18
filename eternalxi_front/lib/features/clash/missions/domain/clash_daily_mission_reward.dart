import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';

class ClashDailyMissionItemReward {
  const ClashDailyMissionItemReward({required this.id, required this.quantity});

  final String id;
  final int quantity;

  factory ClashDailyMissionItemReward.fromJson(Map<String, dynamic> json) {
    return ClashDailyMissionItemReward(
      id: clashRequireString(json['id'], 'id'),
      quantity: clashAsInt(json['quantity'], fallback: 1),
    );
  }
}

/// Recompensa local de una misión diaria (Fase 28).
class ClashDailyMissionReward {
  const ClashDailyMissionReward({
    this.coins = 0,
    this.gems = 0,
    this.expMaterial,
    this.techniqueBook,
  });

  final int coins;
  final int gems;
  final ClashDailyMissionItemReward? expMaterial;
  final ClashDailyMissionItemReward? techniqueBook;

  bool get isEmpty =>
      coins <= 0 && gems <= 0 && expMaterial == null && techniqueBook == null;

  factory ClashDailyMissionReward.fromJson(Map<String, dynamic> json) {
    final expRaw = json['expMaterial'];
    final bookRaw = json['techniqueBook'];
    return ClashDailyMissionReward(
      coins: clashAsInt(json['coins']),
      gems: clashAsInt(json['gems']),
      expMaterial: expRaw is Map
          ? ClashDailyMissionItemReward.fromJson(
              Map<String, dynamic>.from(expRaw),
            )
          : null,
      techniqueBook: bookRaw is Map
          ? ClashDailyMissionItemReward.fromJson(
              Map<String, dynamic>.from(bookRaw),
            )
          : null,
    );
  }

  List<ClashShopProductGrant> toProductGrants() {
    final grants = <ClashShopProductGrant>[];
    if (expMaterial != null && expMaterial!.quantity > 0) {
      grants.add(
        ClashShopProductGrant(
          type: ClashShopProductType.expMaterial,
          id: expMaterial!.id,
          quantity: expMaterial!.quantity,
          label: expMaterial!.id,
        ),
      );
    }
    if (techniqueBook != null && techniqueBook!.quantity > 0) {
      grants.add(
        ClashShopProductGrant(
          type: ClashShopProductType.techniqueBook,
          id: techniqueBook!.id,
          quantity: techniqueBook!.quantity,
          label: techniqueBook!.id,
        ),
      );
    }
    return grants;
  }
}

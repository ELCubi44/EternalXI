import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';

class ClashShopProductGrant {
  const ClashShopProductGrant({
    required this.type,
    required this.id,
    required this.quantity,
    required this.label,
  });

  final ClashShopProductType type;
  final String id;
  final int quantity;
  final String label;

  factory ClashShopProductGrant.fromJson(Map<String, dynamic> json) {
    final type = ClashShopProductType.fromJson(json['type']);
    if (type == null) {
      throw FormatException('Tipo de grant desconocido: ${json['type']}');
    }
    return ClashShopProductGrant(
      type: type,
      id: clashRequireString(json['id'], 'id'),
      quantity: clashAsInt(json['quantity'], fallback: 1),
      label: clashRequireString(json['label'], 'label'),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'id': id,
    'quantity': quantity,
    'label': label,
  };
}

/// Producto local de la tienda Clash (Fase 27).
class ClashShopProduct {
  const ClashShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.costCoins,
    required this.grants,
  });

  final String id;
  final String name;
  final String description;
  final int costCoins;
  final List<ClashShopProductGrant> grants;

  factory ClashShopProduct.fromJson(Map<String, dynamic> json) {
    final grantsRaw = json['grants'] as List? ?? const [];
    return ClashShopProduct(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      costCoins: clashRequireInt(json['costCoins'], 'costCoins'),
      grants: grantsRaw
          .map(
            (item) => ClashShopProductGrant.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

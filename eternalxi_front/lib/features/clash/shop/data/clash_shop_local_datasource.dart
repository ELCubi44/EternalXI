import 'dart:convert';

import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:flutter/services.dart';

class ClashShopLocalDataSource {
  ClashShopLocalDataSource({
    this.assetPath = 'assets/data/clash/shop_products.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashShopProduct>> loadProducts() async {
    final raw = await _bundle.loadString(assetPath);
    return parseProductsJson(raw);
  }

  List<ClashShopProduct> parseProductsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de tienda Clash debe ser un objeto');
    }
    final productsRaw = decoded['products'];
    if (productsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: products');
    }
    return productsRaw
        .map(
          (item) =>
              ClashShopProduct.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }
}

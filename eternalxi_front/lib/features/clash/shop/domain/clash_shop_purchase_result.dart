import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_error.dart';

class ClashShopPurchaseResult {
  const ClashShopPurchaseResult({
    required this.success,
    required this.productId,
    required this.spentCoins,
    required this.grants,
    required this.newCoinBalance,
    this.error,
  });

  final bool success;
  final String productId;
  final int spentCoins;
  final List<ClashShopProductGrant> grants;
  final int newCoinBalance;
  final ClashShopPurchaseError? error;

  factory ClashShopPurchaseResult.failure({
    required String productId,
    required ClashShopPurchaseError error,
    required int newCoinBalance,
  }) {
    return ClashShopPurchaseResult(
      success: false,
      productId: productId,
      spentCoins: 0,
      grants: const [],
      newCoinBalance: newCoinBalance,
      error: error,
    );
  }
}

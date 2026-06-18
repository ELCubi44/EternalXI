import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_error.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_result.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_section.dart';
import 'package:flutter/foundation.dart';

enum ClashShopLoadState { idle, loading, ready, purchasing }

class ClashShopController extends ChangeNotifier {
  ClashShopController({required ClashShopRepository repository})
    : _repository = repository;

  final ClashShopRepository _repository;

  ClashShopLoadState _state = ClashShopLoadState.idle;
  List<ClashShopProduct> _products = const [];
  int _walletCoins = 0;
  int _walletGems = 0;
  String? _errorMessage;
  String? _purchasingProductId;

  ClashShopLoadState get state => _state;
  List<ClashShopProduct> get products => _products;
  int get walletCoins => _walletCoins;
  int get walletGems => _walletGems;
  String? get errorMessage => _errorMessage;
  String? get purchasingProductId => _purchasingProductId;

  Map<ClashShopSection, List<ClashShopProduct>> get productsBySection {
    final grouped = <ClashShopSection, List<ClashShopProduct>>{};
    for (final product in _products) {
      final section = ClashShopSection.forProduct(product);
      grouped.putIfAbsent(section, () => []).add(product);
    }
    return grouped;
  }

  bool isPurchasing(String productId) => _purchasingProductId == productId;

  Future<void> load() async {
    _state = ClashShopLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _products = await _repository.fetchProducts();
      _walletCoins = _repository.walletCoins();
      _walletGems = _repository.walletGems();
      _state = ClashShopLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashShopLoadState.ready;
    }
    notifyListeners();
  }

  bool canAfford(ClashShopProduct product) => _repository.canAfford(product);

  Future<ClashShopPurchaseResult> purchase(String productId) async {
    if (_state == ClashShopLoadState.purchasing) {
      return ClashShopPurchaseResult.failure(
        productId: productId,
        error: ClashShopPurchaseError.insufficientCoins,
        newCoinBalance: _walletCoins,
      );
    }
    _state = ClashShopLoadState.purchasing;
    _purchasingProductId = productId;
    notifyListeners();

    final result = await _repository.purchase(productId);
    _walletCoins = _repository.walletCoins();
    _walletGems = _repository.walletGems();
    _state = ClashShopLoadState.ready;
    _purchasingProductId = null;
    notifyListeners();
    return result;
  }
}

import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_local_datasource.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_error.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_purchase_result.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Tienda local con monedas Clash (Fase 27).
class ClashShopRepository {
  ClashShopRepository({
    required ClashShopLocalDataSource dataSource,
    required ClashStoryRepository storyRepository,
    required ClashShopGrantService grantService,
    ClashDailyMissionEventSink? missionEventSink,
  }) : _dataSource = dataSource,
       _storyRepository = storyRepository,
       _grantService = grantService,
       _missionEventSink = missionEventSink;

  final ClashShopLocalDataSource _dataSource;
  final ClashStoryRepository _storyRepository;
  final ClashShopGrantService _grantService;
  final ClashDailyMissionEventSink? _missionEventSink;

  List<ClashShopProduct>? _productsCache;

  Future<List<ClashShopProduct>> fetchProducts() async {
    _productsCache ??= await _dataSource.loadProducts();
    return _productsCache!;
  }

  Future<ClashShopProduct?> findProduct(String productId) async {
    final products = await fetchProducts();
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  int walletCoins() => _storyRepository.walletCoins();

  int walletGems() => _storyRepository.walletGems();

  bool canAfford(ClashShopProduct product) {
    return walletCoins() >= product.costCoins;
  }

  Future<ClashShopPurchaseResult> purchase(String productId) async {
    final product = await findProduct(productId);
    if (product == null) {
      return ClashShopPurchaseResult.failure(
        productId: productId,
        error: ClashShopPurchaseError.productNotFound,
        newCoinBalance: walletCoins(),
      );
    }

    if (!canAfford(product)) {
      return ClashShopPurchaseResult.failure(
        productId: productId,
        error: ClashShopPurchaseError.insufficientCoins,
        newCoinBalance: walletCoins(),
      );
    }

    final spent = await _storyRepository.spendCoins(product.costCoins);
    if (!spent) {
      return ClashShopPurchaseResult.failure(
        productId: productId,
        error: ClashShopPurchaseError.insufficientCoins,
        newCoinBalance: walletCoins(),
      );
    }

    final granted = await _grantService.grantProductGrants(product.grants);
    if (!granted) {
      await _storyRepository.addCoins(product.costCoins);
      return ClashShopPurchaseResult.failure(
        productId: productId,
        error: ClashShopPurchaseError.grantFailed,
        newCoinBalance: walletCoins(),
      );
    }

    await _missionEventSink?.record(ClashDailyMissionType.shopPurchase);

    return ClashShopPurchaseResult(
      success: true,
      productId: product.id,
      spentCoins: product.costCoins,
      grants: product.grants,
      newCoinBalance: walletCoins(),
    );
  }

  void clearCacheForTests() {
    _productsCache = null;
  }
}

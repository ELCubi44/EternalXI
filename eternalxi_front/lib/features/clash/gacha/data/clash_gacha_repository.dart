import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_banner.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Orquesta tiradas gacha locales (Fase 23).
class ClashGachaRepository {
  ClashGachaRepository({
    required ClashGachaLocalDataSource dataSource,
    required ClashGachaDailyStorageBackend dailyStorage,
    required ClashStoryRepository storyRepository,
    required ClashPlayerCollectionRepository collectionRepository,
    required ClashCardsRepository cardsRepository,
    ClashGachaEngine? engine,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _dailyStorage = dailyStorage,
       _storyRepository = storyRepository,
       _collectionRepository = collectionRepository,
       _cardsRepository = cardsRepository,
       _engine = engine ?? ClashGachaEngine(),
       _now = now ?? DateTime.now;

  final ClashGachaLocalDataSource _dataSource;
  final ClashGachaDailyStorageBackend _dailyStorage;
  final ClashStoryRepository _storyRepository;
  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashCardsRepository _cardsRepository;
  final ClashGachaEngine _engine;
  final DateTime Function() _now;

  ClashGachaCatalog? _catalogCache;
  List<String>? _defaultPoolCache;

  Future<ClashGachaCatalog> fetchCatalog() async {
    _catalogCache ??= await _dataSource.loadCatalog();
    return _catalogCache!;
  }

  Future<ClashGachaBanner?> findBanner(String bannerId) async {
    final catalog = await fetchCatalog();
    for (final banner in catalog.banners) {
      if (banner.id == bannerId) {
        return banner;
      }
    }
    return null;
  }

  ClashGachaRarityRates rates() =>
      _catalogCache?.rates ?? ClashGachaRarityRates.provisional;

  int walletGems() => _storyRepository.walletGems();

  bool isDailyAvailable(String bannerId) {
    final today = _todayKey();
    return _dailyStorage.readLastUsedDate(bannerId) != today;
  }

  int costFor(ClashGachaBanner banner, ClashGachaPullType type) {
    return switch (type) {
      ClashGachaPullType.single => banner.singleCost,
      ClashGachaPullType.multi => banner.multiCost,
      ClashGachaPullType.dailySingle => banner.dailyDiscountCost,
    };
  }

  Future<ClashGachaPullOutcome> pull({
    required String bannerId,
    required ClashGachaPullType type,
  }) async {
    final banner = await findBanner(bannerId);
    if (banner == null) {
      return const ClashGachaPullOutcome(
        error: ClashGachaPullError.bannerNotFound,
      );
    }

    if (type == ClashGachaPullType.dailySingle) {
      if (!banner.dailyDiscountAvailable) {
        return const ClashGachaPullOutcome(
          error: ClashGachaPullError.dailyAlreadyUsed,
        );
      }
      if (!isDailyAvailable(bannerId)) {
        return const ClashGachaPullOutcome(
          error: ClashGachaPullError.dailyAlreadyUsed,
        );
      }
    }

    final cost = costFor(banner, type);
    if (_storyRepository.walletGems() < cost) {
      return const ClashGachaPullOutcome(
        error: ClashGachaPullError.insufficientGems,
      );
    }

    final spent = await _storyRepository.spendGems(cost);
    if (!spent) {
      return const ClashGachaPullOutcome(
        error: ClashGachaPullError.insufficientGems,
      );
    }

    if (type == ClashGachaPullType.dailySingle) {
      await _dailyStorage.writeLastUsedDate(bannerId, _todayKey());
    }

    final catalog = await fetchCatalog();
    final pool = await _resolvePool(banner);
    final rarities = switch (type) {
      ClashGachaPullType.single => [_engine.rollRarity(catalog.rates)],
      ClashGachaPullType.dailySingle => [_engine.rollRarity(catalog.rates)],
      ClashGachaPullType.multi => _engine.rollMulti(
        rates: catalog.rates,
        count: banner.multiCount,
      ),
    };

    final items = <ClashGachaPullResultItem>[];
    for (final rarity in rarities) {
      final cardId = _engine.pickCardId(pool);
      final grant = await _collectionRepository.grantGachaCard(
        cardId: cardId,
        rarity: rarity,
      );
      final entry = await _cardsRepository.findById(cardId);
      items.add(
        ClashGachaPullResultItem(
          cardId: cardId,
          cardName: entry?.name ?? cardId,
          rarity: grant.grantedRarity,
          isNew: grant.isNew,
          isDuplicate: grant.isDuplicate,
          upgradedRarity: grant.upgradedRarity,
          duplicateCopiesAfter: grant.duplicateCopiesAfter,
        ),
      );
    }

    return ClashGachaPullOutcome(
      result: ClashGachaPullResult(
        bannerId: bannerId,
        pullType: type,
        spentGems: cost,
        results: items,
        createdAt: _now(),
        remainingGems: _storyRepository.walletGems(),
      ),
    );
  }

  Future<List<String>> _resolvePool(ClashGachaBanner banner) async {
    if (banner.poolCardIds.isNotEmpty) {
      return banner.poolCardIds;
    }
    _defaultPoolCache ??= (await _cardsRepository.fetchAllCards())
        .map((entry) => entry.id)
        .toList(growable: false);
    return _defaultPoolCache!;
  }

  String _todayKey() {
    final now = _now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void clearCacheForTests() {
    _catalogCache = null;
    _defaultPoolCache = null;
  }
}

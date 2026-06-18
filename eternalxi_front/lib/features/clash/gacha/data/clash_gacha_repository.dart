import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_banner.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_type.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Orquesta tiradas gacha locales (Fase 23), historial (Fase 24), pity (Fase 25)
/// y tickets (Fase 26).
class ClashGachaRepository {
  ClashGachaRepository({
    required ClashGachaLocalDataSource dataSource,
    required ClashGachaDailyStorageBackend dailyStorage,
    required ClashGachaHistoryStorageBackend historyStorage,
    required ClashGachaPityStorageBackend pityStorage,
    required ClashGachaTicketRepository ticketRepository,
    required ClashStoryRepository storyRepository,
    required ClashPlayerCollectionRepository collectionRepository,
    required ClashCardsRepository cardsRepository,
    ClashGachaEngine? engine,
    ClashDailyMissionEventSink? missionEventSink,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _dailyStorage = dailyStorage,
       _historyStorage = historyStorage,
       _pityStorage = pityStorage,
       _ticketRepository = ticketRepository,
       _storyRepository = storyRepository,
       _collectionRepository = collectionRepository,
       _cardsRepository = cardsRepository,
       _engine = engine ?? ClashGachaEngine(),
       _missionEventSink = missionEventSink,
       _now = now ?? DateTime.now;

  final ClashGachaLocalDataSource _dataSource;
  final ClashGachaDailyStorageBackend _dailyStorage;
  final ClashGachaHistoryStorageBackend _historyStorage;
  final ClashGachaPityStorageBackend _pityStorage;
  final ClashGachaTicketRepository _ticketRepository;
  final ClashStoryRepository _storyRepository;
  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashCardsRepository _cardsRepository;
  final ClashGachaEngine _engine;
  final ClashDailyMissionEventSink? _missionEventSink;
  final DateTime Function() _now;

  ClashGachaCatalog? _catalogCache;
  List<String>? _defaultPoolCache;

  ClashGachaTicketRepository get ticketRepository => _ticketRepository;

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

  ClashGachaPityState loadPityState(String bannerId) {
    return _pityStorage.readState(bannerId) ??
        ClashGachaPityState.initial(bannerId);
  }

  Future<void> clearPityForTests() => _pityStorage.clearAll();

  Future<List<ClashGachaHistoryEntry>> loadHistory() async {
    final entries = _historyStorage.readEntries()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<ClashGachaHistoryEntry>.unmodifiable(entries);
  }

  Future<void> clearHistory() => _historyStorage.clearHistory();

  bool isDailyAvailable(String bannerId) {
    final today = _todayKey();
    return _dailyStorage.readLastUsedDate(bannerId) != today;
  }

  Future<List<ClashGachaTicketInventoryEntry>> compatibleTicketsForBanner(
    String bannerId,
  ) {
    return _ticketRepository.compatibleTicketsForBanner(bannerId);
  }

  int costFor(ClashGachaBanner banner, ClashGachaPullType type) {
    return switch (type) {
      ClashGachaPullType.single => banner.singleCost,
      ClashGachaPullType.multi => banner.multiCost,
      ClashGachaPullType.dailySingle => banner.dailyDiscountCost,
      ClashGachaPullType.ticketSingle => 0,
    };
  }

  int _cardCountFor(ClashGachaPullType type, ClashGachaBanner banner) {
    return switch (type) {
      ClashGachaPullType.single => 1,
      ClashGachaPullType.dailySingle => 1,
      ClashGachaPullType.ticketSingle => 1,
      ClashGachaPullType.multi => banner.multiCount,
    };
  }

  Future<ClashGachaPullOutcome> pull({
    required String bannerId,
    required ClashGachaPullType type,
    String? ticketId,
  }) async {
    final banner = await findBanner(bannerId);
    if (banner == null) {
      return const ClashGachaPullOutcome(
        error: ClashGachaPullError.bannerNotFound,
      );
    }

    if (type == ClashGachaPullType.ticketSingle) {
      return _pullWithTicket(banner: banner, ticketId: ticketId);
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

    return _executePull(
      banner: banner,
      type: type,
      spentGems: cost,
      cardCount: _cardCountFor(type, banner),
      applyMultiGuarantee:
          type == ClashGachaPullType.multi && banner.multiCount > 1,
    );
  }

  Future<ClashGachaPullOutcome> _pullWithTicket({
    required ClashGachaBanner banner,
    required String? ticketId,
  }) async {
    if (ticketId == null || ticketId.isEmpty) {
      return const ClashGachaPullOutcome(error: ClashGachaPullError.noTickets);
    }

    final ticket = await _ticketRepository.findTicket(ticketId);
    if (ticket == null) {
      return const ClashGachaPullOutcome(error: ClashGachaPullError.noTickets);
    }

    if (!ticket.isCompatibleWith(banner.id)) {
      return const ClashGachaPullOutcome(
        error: ClashGachaPullError.ticketNotCompatible,
      );
    }

    if (_ticketRepository.quantityFor(ticketId) < 1) {
      return const ClashGachaPullOutcome(error: ClashGachaPullError.noTickets);
    }

    final consumed = await _ticketRepository.consume(ticketId);
    if (!consumed) {
      return const ClashGachaPullOutcome(error: ClashGachaPullError.noTickets);
    }

    return _executePull(
      banner: banner,
      type: ClashGachaPullType.ticketSingle,
      spentGems: 0,
      cardCount: ticket.pullCount,
      applyMultiGuarantee: false,
      ticketId: ticketId,
    );
  }

  Future<ClashGachaPullOutcome> _executePull({
    required ClashGachaBanner banner,
    required ClashGachaPullType type,
    required int spentGems,
    required int cardCount,
    required bool applyMultiGuarantee,
    String? ticketId,
  }) async {
    final catalog = await fetchCatalog();
    final pool = await _resolvePool(banner);
    final pityState = loadPityState(banner.id);

    final rollOutcome = _engine.rollWithPity(
      rates: catalog.rates,
      cardCount: cardCount,
      applyMultiGuarantee: applyMultiGuarantee,
      pityState: pityState,
    );

    await _pityStorage.writeState(rollOutcome.stateAfter);

    final items = <ClashGachaPullResultItem>[];
    for (final slot in rollOutcome.slots) {
      final cardId = _engine.pickCardId(pool);
      final grant = await _collectionRepository.grantGachaCard(
        cardId: cardId,
        rarity: slot.rarity,
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
          wasPity: slot.wasPity,
          wasMultiGuarantee: slot.wasMultiGuarantee,
        ),
      );
    }

    final result = ClashGachaPullResult(
      bannerId: banner.id,
      pullType: type,
      spentGems: spentGems,
      results: items,
      createdAt: _now(),
      remainingGems: _storyRepository.walletGems(),
      pityTriggered: rollOutcome.pityTriggered,
      ticketId: ticketId,
    );

    await _historyStorage.appendEntry(
      ClashGachaHistoryEntry.fromPullResult(
        id: '${result.createdAt.millisecondsSinceEpoch}-${type.name}',
        result: result,
        bannerName: banner.name,
      ),
    );

    await _missionEventSink?.record(ClashDailyMissionType.summon);

    return ClashGachaPullOutcome(result: result);
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

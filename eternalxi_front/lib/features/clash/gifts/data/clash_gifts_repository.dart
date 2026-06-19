import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_local_datasource.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_claim_result.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_status.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Buzón de regalos locales Clash (Fase 32).
class ClashGiftsRepository {
  ClashGiftsRepository({
    required ClashGiftsLocalDataSource dataSource,
    required ClashGiftsStorageBackend storage,
    required ClashStoryRepository storyRepository,
    required ClashLocalRewardGranter rewardGranter,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _storyRepository = storyRepository,
       _rewardGranter = rewardGranter,
       _now = now ?? DateTime.now;

  final ClashGiftsLocalDataSource _dataSource;
  final ClashGiftsStorageBackend _storage;
  final ClashStoryRepository _storyRepository;
  final ClashLocalRewardGranter _rewardGranter;
  final DateTime Function() _now;

  List<ClashGift>? _giftsCache;
  ClashGiftsState? _stateCache;

  Future<List<ClashGift>> _loadGiftCatalog() async {
    _giftsCache ??= await _dataSource.loadGifts();
    return _giftsCache!;
  }

  Future<ClashGiftsState> loadState() async {
    if (_stateCache != null) {
      return _stateCache!;
    }
    final stored = _storage.readState();
    _stateCache = stored ?? const ClashGiftsState();
    if (stored == null) {
      await _storage.writeState(_stateCache!);
    }
    return _stateCache!;
  }

  static List<ClashGift> sortGifts(List<ClashGift> gifts) {
    final indexed = gifts.asMap().entries.toList(growable: false);
    indexed.sort((a, b) {
      final giftA = a.value;
      final giftB = b.value;
      if (giftA.isPinned != giftB.isPinned) {
        return giftA.isPinned ? -1 : 1;
      }
      return a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  Future<List<ClashGiftEntry>> fetchGiftEntries() async {
    final gifts = sortGifts(await _loadGiftCatalog());
    final state = await loadState();
    final now = _now();
    return gifts
        .map((gift) {
          final claimed = state.claimedGiftIds.contains(gift.id);
          return ClashGiftEntry(
            gift: gift,
            status: gift.resolveStatus(claimed: claimed, now: now),
            canClaim: gift.isClaimableAt(now, claimed: claimed),
          );
        })
        .toList(growable: false);
  }

  Future<ClashGiftsSummary> fetchSummary() async {
    final entries = await fetchGiftEntries();
    final pending = entries.where((entry) => entry.canClaim).toList();
    final claimed = entries
        .where((entry) => entry.status == ClashGiftStatus.claimed)
        .length;
    return ClashGiftsSummary(
      totalGifts: entries.length,
      pendingCount: pending.length,
      claimedCount: claimed,
      latestPendingTitle: pending.isEmpty ? null : pending.first.gift.title,
    );
  }

  Future<ClashGiftClaimResult> claimGift(String giftId) async {
    final gifts = await _loadGiftCatalog();
    ClashGift? gift;
    for (final item in gifts) {
      if (item.id == giftId) {
        gift = item;
        break;
      }
    }
    if (gift == null) {
      return ClashGiftClaimResult.failure(
        giftId: giftId,
        error: ClashGiftClaimError.giftNotFound,
      );
    }

    final state = await loadState();
    if (state.claimedGiftIds.contains(giftId)) {
      return ClashGiftClaimResult.failure(
        giftId: giftId,
        error: ClashGiftClaimError.alreadyClaimed,
      );
    }

    final status = gift.resolveStatus(claimed: false, now: _now());
    if (!gift.isClaimableAt(
      _now(),
      claimed: state.claimedGiftIds.contains(giftId),
    )) {
      return ClashGiftClaimResult.failure(
        giftId: giftId,
        error: status == ClashGiftStatus.expired
            ? ClashGiftClaimError.expired
            : ClashGiftClaimError.alreadyClaimed,
      );
    }

    final granted = await _grantReward(gift.rewards);
    if (!granted) {
      return ClashGiftClaimResult.failure(
        giftId: giftId,
        error: ClashGiftClaimError.grantFailed,
      );
    }

    final claimed = Set<String>.from(state.claimedGiftIds)..add(giftId);
    final updated = state.copyWith(
      claimedGiftIds: claimed,
      lastOpenedAt: _now().toIso8601String(),
    );
    _stateCache = updated;
    await _storage.writeState(updated);

    return ClashGiftClaimResult(
      success: true,
      giftId: giftId,
      rewards: gift.rewards,
    );
  }

  Future<List<ClashGiftClaimResult>> claimAllPending() async {
    final entries = await fetchGiftEntries();
    final results = <ClashGiftClaimResult>[];
    for (final entry in entries) {
      if (!entry.canClaim) {
        continue;
      }
      results.add(await claimGift(entry.gift.id));
    }
    return results;
  }

  Future<void> recordOpened() async {
    final state = await loadState();
    final updated = state.copyWith(lastOpenedAt: _now().toIso8601String());
    _stateCache = updated;
    await _storage.writeState(updated);
  }

  Future<bool> _grantReward(ClashAchievementReward reward) async {
    if (reward.isEmpty) {
      return true;
    }
    final result = await _rewardGranter.grantAll(
      ClashRewardConverters.fromAchievementReward(reward),
    );
    return result.isFullyGranted;
  }

  void clearCacheForTests() {
    _giftsCache = null;
    _stateCache = null;
    _dataSource.clearCacheForTests();
  }

  Future<void> resetForTests() async {
    clearCacheForTests();
    await _storage.clear();
  }
}

import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
import 'package:eternal_xi/features/clash/gifts/domain/clash_gift_claim_result.dart';
import 'package:flutter/foundation.dart';

enum ClashGiftsLoadState { idle, loading, ready, claiming }

class ClashGiftsController extends ChangeNotifier {
  ClashGiftsController({required ClashGiftsRepository repository})
    : _repository = repository;

  final ClashGiftsRepository _repository;

  ClashGiftsLoadState _state = ClashGiftsLoadState.idle;
  List<ClashGiftEntry> _entries = const [];
  ClashGiftsSummary _summary = const ClashGiftsSummary(
    totalGifts: 0,
    pendingCount: 0,
    claimedCount: 0,
  );
  String? _errorMessage;

  ClashGiftsLoadState get state => _state;
  List<ClashGiftEntry> get entries => _entries;
  ClashGiftsSummary get summary => _summary;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = ClashGiftsLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _entries = await _repository.fetchGiftEntries();
      _summary = await _repository.fetchSummary();
      _state = ClashGiftsLoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = ClashGiftsLoadState.ready;
    }
    notifyListeners();
  }

  Future<void> openScreen() async {
    await _repository.recordOpened();
    await load();
  }

  Future<ClashGiftClaimResult> claimGift(String giftId) async {
    if (_state == ClashGiftsLoadState.claiming) {
      return ClashGiftClaimResult.failure(
        giftId: giftId,
        error: ClashGiftClaimError.alreadyClaimed,
      );
    }
    _state = ClashGiftsLoadState.claiming;
    notifyListeners();

    final result = await _repository.claimGift(giftId);
    _entries = await _repository.fetchGiftEntries();
    _summary = await _repository.fetchSummary();
    _state = ClashGiftsLoadState.ready;
    notifyListeners();
    return result;
  }

  Future<List<ClashGiftClaimResult>> claimAllPending() async {
    if (_state == ClashGiftsLoadState.claiming) {
      return const [];
    }
    _state = ClashGiftsLoadState.claiming;
    notifyListeners();

    final results = await _repository.claimAllPending();
    _entries = await _repository.fetchGiftEntries();
    _summary = await _repository.fetchSummary();
    _state = ClashGiftsLoadState.ready;
    notifyListeners();
    return results;
  }
}

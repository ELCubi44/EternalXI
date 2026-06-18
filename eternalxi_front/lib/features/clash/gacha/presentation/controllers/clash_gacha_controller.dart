import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_banner.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket.dart';
import 'package:flutter/foundation.dart';

enum ClashGachaLoadState { idle, loading, ready, pulling }

class ClashGachaController extends ChangeNotifier {
  ClashGachaController({required ClashGachaRepository repository})
    : _repository = repository;

  final ClashGachaRepository _repository;

  static const defaultBannerId = 'starter-banner-001';

  ClashGachaLoadState _state = ClashGachaLoadState.idle;
  ClashGachaBanner? _banner;
  ClashGachaRarityRates _rates = ClashGachaRarityRates.provisional;
  int _walletGems = 0;
  bool _dailyAvailable = true;
  ClashGachaPullResult? _lastResult;
  ClashGachaPullError? _lastError;
  ClashGachaPityState? _pityState;
  List<ClashGachaTicketInventoryEntry> _compatibleTickets = const [];

  ClashGachaLoadState get state => _state;
  ClashGachaBanner? get banner => _banner;
  ClashGachaRarityRates get rates => _rates;
  int get walletGems => _walletGems;
  bool get dailyAvailable => _dailyAvailable;
  ClashGachaPullResult? get lastResult => _lastResult;
  ClashGachaPullError? get lastError => _lastError;
  ClashGachaPityState? get pityState => _pityState;
  List<ClashGachaTicketInventoryEntry> get compatibleTickets =>
      _compatibleTickets;

  Future<void> load() async {
    _state = ClashGachaLoadState.loading;
    notifyListeners();
    final catalog = await _repository.fetchCatalog();
    _banner = catalog.banners.isNotEmpty ? catalog.banners.first : null;
    _rates = catalog.rates;
    _walletGems = _repository.walletGems();
    _dailyAvailable = _repository.isDailyAvailable(defaultBannerId);
    _pityState = _repository.loadPityState(defaultBannerId);
    _compatibleTickets = _banner == null
        ? const []
        : await _repository.compatibleTicketsForBanner(_banner!.id);
    _state = ClashGachaLoadState.ready;
    notifyListeners();
  }

  Future<ClashGachaPullOutcome> pull(ClashGachaPullType type) async {
    return _pull(type: type);
  }

  Future<ClashGachaPullOutcome> pullWithTicket(String ticketId) async {
    return _pull(type: ClashGachaPullType.ticketSingle, ticketId: ticketId);
  }

  Future<ClashGachaPullOutcome> _pull({
    required ClashGachaPullType type,
    String? ticketId,
  }) async {
    if (_state == ClashGachaLoadState.pulling || _banner == null) {
      return const ClashGachaPullOutcome();
    }
    _state = ClashGachaLoadState.pulling;
    _lastError = null;
    notifyListeners();

    final outcome = await _repository.pull(
      bannerId: _banner!.id,
      type: type,
      ticketId: ticketId,
    );

    _lastResult = outcome.result;
    _lastError = outcome.error;
    _walletGems = _repository.walletGems();
    _dailyAvailable = _repository.isDailyAvailable(_banner!.id);
    _pityState = _repository.loadPityState(_banner!.id);
    _compatibleTickets = await _repository.compatibleTicketsForBanner(
      _banner!.id,
    );
    _state = ClashGachaLoadState.ready;
    notifyListeners();
    return outcome;
  }

  void refreshWallet() {
    _walletGems = _repository.walletGems();
    notifyListeners();
  }
}

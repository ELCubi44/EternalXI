import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/rewards/data/models/coach_roulette_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_event_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_pack_open_result.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_redeem_result_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/features/rewards/utils/rewards_error_mapper.dart';
import 'package:flutter/foundation.dart';

class RewardsController extends ChangeNotifier {
  RewardsController({
    required RewardsApiService rewardsApi,
    required ApiClient apiClient,
    required LeaguesApiService leaguesApi,
    required this.idLiga,
    required this.idUsuario,
  }) : _rewardsApi = rewardsApi,
       _apiClient = apiClient,
       _leaguesApi = leaguesApi;

  final RewardsApiService _rewardsApi;
  final ApiClient _apiClient;
  final LeaguesApiService _leaguesApi;
  final int idLiga;
  final int idUsuario;

  RewardSummaryModel? summary;
  List<RewardCardModel> cards = [];
  List<RewardEventModel> events = [];
  List<LeagueActivityEvent> activity = [];
  int _activityOffset = 0;
  bool hasMoreActivity = true;

  bool loadingSummary = false;
  bool loadingCards = false;
  bool loadingEvents = false;
  bool loadingActivity = false;
  String? errorMessage;

  Future<void> loadSummary() async {
    loadingSummary = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _rewardsApi.getSummary(
        idLiga: idLiga,
        idUsuario: idUsuario,
      );
    } catch (e) {
      errorMessage = _apiClient.extractErrorMessage(e);
      summary = null;
    } finally {
      loadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadCards() async {
    loadingCards = true;
    notifyListeners();
    try {
      cards = await _rewardsApi.getCards(idLiga: idLiga, idUsuario: idUsuario);
    } catch (e) {
      cards = [];
      errorMessage = _apiClient.extractErrorMessage(e);
    } finally {
      loadingCards = false;
      notifyListeners();
    }
  }

  Future<void> loadEvents() async {
    loadingEvents = true;
    notifyListeners();
    try {
      events = await _rewardsApi.getRewardEvents(
        leagueId: idLiga,
        userId: idUsuario,
      );
    } catch (e) {
      events = [];
    } finally {
      loadingEvents = false;
      notifyListeners();
    }
  }

  Future<void> loadActivity({bool loadMore = false}) async {
    if (loadMore && !hasMoreActivity) return;
    loadingActivity = true;
    notifyListeners();
    try {
      final offset = loadMore ? _activityOffset : 0;
      final list = await _leaguesApi.getLeagueActivity(
        idLiga: idLiga,
        idUsuario: idUsuario,
        limit: 50,
        offset: offset,
      );
      if (loadMore) {
        activity = [...activity, ...list];
      } else {
        activity = list;
      }
      _activityOffset = activity.length;
      hasMoreActivity = list.length >= 50;
    } catch (_) {
      if (!loadMore) activity = [];
    } finally {
      loadingActivity = false;
      notifyListeners();
    }
  }

  Future<void> refreshAfterMutation() async {
    await loadSummary();
    if (summary?.showCartasTab == true) {
      await loadCards();
    } else {
      cards = [];
      notifyListeners();
    }
    await loadEvents();
    await loadActivity();
  }

  Future<RewardPackOpenResult?> openPack(String packType) async {
    try {
      final result = await _rewardsApi.openPack(
        idLiga: idLiga,
        packType: packType,
        idUsuario: idUsuario,
      );
      await refreshAfterMutation();
      return result;
    } catch (e) {
      errorMessage = mapRewardsActionError(e, _apiClient);
      notifyListeners();
      return null;
    }
  }

  Future<CoachRouletteSpinResult?> spinCoachRoulette() async {
    try {
      final result = await _rewardsApi.spinCoachRoulette(
        idLiga: idLiga,
        idUsuario: idUsuario,
      );
      await refreshAfterMutation();
      return result;
    } catch (e) {
      errorMessage = mapRewardsActionError(e, _apiClient);
      notifyListeners();
      return null;
    }
  }

  Future<RewardRedeemResultModel?> redeemCard({
    required int idCarta,
    int? idLigaJugadorObjetivo,
  }) async {
    try {
      final result = await _rewardsApi.redeemCard(
        idLiga: idLiga,
        idCarta: idCarta,
        idUsuario: idUsuario,
        idLigaJugadorObjetivo: idLigaJugadorObjetivo,
      );
      await refreshAfterMutation();
      return result;
    } catch (e) {
      errorMessage = mapRewardsActionError(e, _apiClient);
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}

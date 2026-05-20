import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/features/rewards/data/models/coach_roulette_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_target_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_event_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_pack_open_result.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_redeem_result_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_summary_model.dart';

/// Cliente HTTP de recompensas (`ApiConstants.baseUrl`).
class RewardsApiService {
  RewardsApiService(this._apiClient);

  final ApiClient _apiClient;

  String _basePath(int idLiga) => '${ApiConstants.leagues}/$idLiga/rewards';

  /// GET /leagues/{idLiga}/rewards/summary?idUsuario=
  Future<RewardSummaryModel> getSummary({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${_basePath(idLiga)}/summary',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía del resumen de recompensas.');
      }
      return RewardSummaryModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/rewards/packs/{packType}/open?idUsuario=
  Future<RewardPackOpenResult> openPack({
    required int idLiga,
    required String packType,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${_basePath(idLiga)}/packs/$packType/open',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return RewardPackOpenResult.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/rewards/coach-roulette/spin?idUsuario=
  Future<CoachRouletteSpinResult> spinCoachRoulette({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${_basePath(idLiga)}/coach-roulette/spin',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return CoachRouletteSpinResult.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/rewards/cards?idUsuario=
  Future<List<RewardCardModel>> getCards({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${_basePath(idLiga)}/cards',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      return RewardCardModel.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/rewards/cards/{idCarta}/valid-targets?idUsuario=
  /// GET /api/v1/leagues/{idLiga}/rewards/cards/{idCarta}/valid-targets?idUsuario=
  Future<RewardValidTargetsResponse> getValidTargets({
    required int idLiga,
    required int idCarta,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${_basePath(idLiga)}/cards/$idCarta/valid-targets',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return RewardValidTargetsResponse.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/rewards/cards/{idCarta}/redeem?idUsuario=
  Future<RewardRedeemResultModel> redeemCard({
    required int idLiga,
    required int idCarta,
    required int idUsuario,
    int? idLigaJugadorObjetivo,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (idLigaJugadorObjetivo != null && idLigaJugadorObjetivo > 0) {
        body['idLigaJugadorObjetivo'] = idLigaJugadorObjetivo;
      }
      final response = await _apiClient.dio.post(
        '${_basePath(idLiga)}/cards/$idCarta/redeem',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
        data: body.isEmpty ? <String, dynamic>{} : body,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );
      final map = readLeagueSingleMap(response.data);
      return RewardRedeemResultModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{leagueId}/rewards/events?idUsuario=
  ///
  /// Equivale a `GET /api/v1/leagues/{idLiga}/rewards/events?idUsuario={idUsuario}`.
  Future<List<RewardEventModel>> getRewardEvents({
    required int leagueId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${_basePath(leagueId)}/events',
        queryParameters: <String, dynamic>{'idUsuario': userId},
      );
      return RewardEventModel.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// Alias con nombres legacy (`idLiga` / `idUsuario`).
  Future<List<RewardEventModel>> getEvents({
    required int idLiga,
    required int idUsuario,
  }) =>
      getRewardEvents(leagueId: idLiga, userId: idUsuario);
}

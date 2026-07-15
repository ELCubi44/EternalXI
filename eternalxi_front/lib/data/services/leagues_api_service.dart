import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/network/api_exception.dart';
import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/data/models/league_chat_message.dart';
import 'package:eternal_xi/data/models/league_dm_message.dart';
import 'package:eternal_xi/data/models/league_dm_thread.dart';
import 'package:eternal_xi/data/models/league_calendar_models.dart';
import 'package:eternal_xi/data/models/catalog_team_player.dart';
import 'package:eternal_xi/data/models/catalog_team_squad.dart';
import 'package:eternal_xi/data/models/catalog_team_summary.dart';
import 'package:eternal_xi/data/models/league_squad_response.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:eternal_xi/data/models/league_editable_lineup.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_match_detail_payload.dart';
import 'package:eternal_xi/data/models/league_match_live_payload.dart';
import 'package:eternal_xi/data/models/league_participant.dart';
import 'package:eternal_xi/data/models/league_participant_lineup_history.dart';
import 'package:eternal_xi/data/models/league_participant_squad_payload.dart';
import 'package:eternal_xi/data/models/league_player_detail.dart';
import 'package:eternal_xi/data/models/league_market_history_entry.dart';
import 'package:eternal_xi/data/models/league_unavailable_player.dart';
import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_buy_now_result.dart';
import 'package:eternal_xi/data/models/league_sell_player_result.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/models/league_round_standing_row.dart';
import 'package:eternal_xi/data/models/league_season_wrap.dart';
import 'package:eternal_xi/data/models/league_standing_row.dart';
import 'package:eternal_xi/data/models/league_team_standing_row.dart';
import 'package:eternal_xi/data/models/create_league_request.dart';
import 'package:eternal_xi/data/models/create_league_response.dart';
import 'package:eternal_xi/data/models/join_league_response.dart';
import 'package:eternal_xi/data/models/league_home_feed.dart';
import 'package:eternal_xi/data/models/league_summary.dart';
import 'package:eternal_xi/data/models/api_message_model.dart';
import 'package:eternal_xi/data/models/night_market_models.dart';
import 'package:eternal_xi/data/models/season_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Cliente HTTP de ligas contra el backend real (`ApiConstants.baseUrl`).
class LeaguesApiService {
  LeaguesApiService(this._apiClient);

  final ApiClient _apiClient;

  /// Log explícito `GET {urlCompleta}` antes del request (solo debug).
  void _debugLogStarterProbGet(
    String tag,
    String path,
    Map<String, dynamic> qp,
  ) {
    if (!kDebugMode) {
      return;
    }
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    final rel = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse(
      '$base$rel',
    ).replace(queryParameters: qp.map((k, v) => MapEntry(k, '$v')));
    debugPrint('[starter-prob][$tag] GET $uri');
  }

  void _debugLogPlayerDetailTitularidadRaw(Map<String, dynamic> map) {
    if (!kDebugMode) {
      return;
    }
    String rawVal(List<String> keys) {
      for (final k in keys) {
        if (map.containsKey(k)) {
          return '${map[k]}';
        }
      }
      return '(ausente)';
    }

    debugPrint(
      '[starter-prob][player-detail-raw] '
      'probabilidadTitular=${rawVal(const ['probabilidadTitular', 'probabilidad_titular'])} '
      'motivoTitularidad=${rawVal(const ['motivoTitularidad', 'motivo_titularidad'])} '
      'idPartidoProbabilidad=${rawVal(const ['idPartidoProbabilidad', 'id_partido_probabilidad'])} '
      'calculadoEnProbabilidad=${rawVal(const ['calculadoEnProbabilidad', 'calculado_en_probabilidad'])}',
    );
  }

  void _debugLogSquadParsedPlayers(List<LeagueSquadPlayer> plantilla) {
    if (!kDebugMode) {
      return;
    }
    for (final p in plantilla) {
      debugPrint(
        '[starter-prob][squad-parsed-player] idLigaJugador=${p.idLigaJugador} '
        'probabilidadTitular=${p.probabilidadTitular}',
      );
    }
  }

  /// GET /catalog/seasons
  Future<List<SeasonSummary>> fetchSeasonCatalog() async {
    try {
      final response = await _apiClient.dio.get('/catalog/seasons');
      final rows = readLeagueListMap(response.data);
      return rows.map(SeasonSummary.fromJson).where((s) => s.id > 0).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /catalog/teams?seasonId=
  Future<List<CatalogTeamSummary>> fetchCatalogTeamsBySeason({
    required int seasonId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/catalog/teams',
        queryParameters: {'seasonId': seasonId},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(CatalogTeamSummary.fromJson).where((t) => t.id > 0).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /catalog/teams/{idEquipo}/players
  Future<List<CatalogTeamPlayer>> getCatalogTeamPlayers({
    required int idEquipo,
    int? seasonId,
  }) async {
    try {
      final qp = <String, dynamic>{};
      if (seasonId != null && seasonId > 0) {
        qp['seasonId'] = seasonId;
      }
      final response = await _apiClient.dio.get(
        '/catalog/teams/$idEquipo/players',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(CatalogTeamPlayer.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /catalog/teams/{idEquipo}/squad [&seasonId=]
  Future<CatalogTeamSquad> getCatalogTeamSquad({
    required int idEquipo,
    int? seasonId,
    int? idLiga,
  }) async {
    try {
      final qp = <String, dynamic>{};
      if (seasonId != null && seasonId > 0) {
        qp['seasonId'] = seasonId;
      }
      if (idLiga != null && idLiga > 0) {
        qp['idLiga'] = idLiga;
      }
      final response = await _apiClient.dio.get(
        '/catalog/teams/$idEquipo/squad',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía del squad de catálogo.');
      }
      return CatalogTeamSquad.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/market?idUsuario= [&ownerId=] [&teamId=]
  Future<List<LeagueSquadPlayer>> getLeagueMarketPlayers({
    required int idLiga,
    required int idUsuario,
    int? ownerId,
    int? teamId,
    String? position,
    String? search,
  }) async {
    try {
      final qp = <String, dynamic>{'idUsuario': idUsuario};
      if (ownerId != null && ownerId > 0) {
        qp['ownerId'] = ownerId;
      }
      if (teamId != null && teamId > 0) {
        qp['teamId'] = teamId;
      }
      final p = position?.trim() ?? '';
      if (p.isNotEmpty) {
        qp['position'] = p;
      }
      final q = search?.trim() ?? '';
      if (q.isNotEmpty) {
        qp['search'] = q;
      }
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/market',
        queryParameters: qp,
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueSquadPlayer.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// Plantilla de un usuario concreto: **solo** `GET .../market?ownerId=` filtrado en cliente por [ownerUserId].
  /// No se usa el listado global sin `ownerId` para evitar mezclar jugadores ajenos al propietario.
  Future<List<LeagueSquadPlayer>> getLeagueMarketPlayersForOwner({
    required int idLiga,
    required int idUsuario,
    required int ownerUserId,
  }) async {
    if (ownerUserId <= 0) {
      return const [];
    }
    final rows = await getLeagueMarketPlayers(
      idLiga: idLiga,
      idUsuario: idUsuario,
      ownerId: ownerUserId,
    );
    return rows.where((p) => p.idUsuarioDueno == ownerUserId).toList();
  }

  /// GET /leagues/{idLiga}/night-market?idUsuario=
  Future<NightMarketResponse> getNightMarket({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/night-market',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía del mercado nocturno.');
      }
      return NightMarketResponse.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/night-market/{idMercadoDiario}/bid
  Future<ApiMessageModel> upsertNightMarketBid({
    required int idLiga,
    required int idMercadoDiario,
    required int idUsuario,
    required int cantidad,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/night-market/$idMercadoDiario/bid',
        data: <String, dynamic>{'idUsuario': idUsuario, 'cantidad': cantidad},
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// DELETE /leagues/{idLiga}/night-market/{idMercadoDiario}/bid?idUsuario=
  Future<ApiMessageModel> deleteNightMarketBid({
    required int idLiga,
    required int idMercadoDiario,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.leagues}/$idLiga/night-market/$idMercadoDiario/bid',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/rounds?idUsuario=
  Future<List<LeagueRoundSummary>> getLeagueRounds({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/rounds',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      return parseLeagueRoundsResponse(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/rounds/{idJornada}?idUsuario=
  Future<LeagueRoundDetailData> getLeagueRoundDetail({
    required int idLiga,
    required int idJornada,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/rounds/$idJornada',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía de la jornada.');
      }
      return LeagueRoundDetailData.fromBackend(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/matches/{idPartido}?idUsuario=
  Future<LeagueMatchDetailPayload> getLeagueMatchDetail({
    required int idLiga,
    required int idPartido,
    required int idUsuario,
    required LeagueMatchSummary summaryFallback,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/matches/$idPartido',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty || readLeagueInt(map, const ['idPartido']) <= 0) {
        throw const ApiException('Respuesta inválida del detalle de partido.');
      }
      return LeagueMatchDetailPayload.fromMap(map, summaryFallback);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/matches/{idPartido}/live?idUsuario=
  Future<LeagueMatchLivePayload> getLeagueMatchLive({
    required int idLiga,
    required int idPartido,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/matches/$idPartido/live',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty || readLeagueInt(map, const ['idPartido']) <= 0) {
        throw const ApiException('Respuesta inválida del directo del partido.');
      }
      return LeagueMatchLivePayload.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/players/{idLigaJugador}?idUsuario= [&idJornada=]
  Future<LeaguePlayerDetail> getLeaguePlayerDetail({
    required int idLiga,
    required int idLigaJugador,
    required int idUsuario,
    int? idJornada,
  }) async {
    try {
      final qp = <String, dynamic>{'idUsuario': idUsuario};
      if (idJornada != null && idJornada > 0) {
        qp['idJornada'] = idJornada;
      }
      _debugLogStarterProbGet(
        'player-detail-url',
        '${ApiConstants.leagues}/$idLiga/players/$idLigaJugador',
        qp,
      );
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/players/$idLigaJugador',
        queryParameters: qp,
      );
      if (kDebugMode) {
        debugPrint(
          '[player-detail][response] idLiga=$idLiga idLigaJugador=$idLigaJugador body=${response.data}',
        );
      }
      final map = readLeagueSingleMap(response.data);
      _debugLogPlayerDetailTitularidadRaw(map);
      if (map.isEmpty ||
          readLeagueInt(map, const ['idLigaJugador', 'id_liga_jugador']) <= 0) {
        throw const ApiException('Respuesta inválida del detalle del jugador.');
      }
      return LeaguePlayerDetail.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/players/{idLigaJugador}/buy-now?idUsuario=
  Future<LeagueBuyNowResult> buyLeaguePlayerNow({
    required int idLiga,
    required int idLigaJugador,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/players/$idLigaJugador/buy-now',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty ||
          readLeagueInt(map, const ['idLigaJugador', 'id_liga_jugador']) <= 0) {
        throw const ApiException('Respuesta inválida de la compra directa.');
      }
      return LeagueBuyNowResult.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/players/{idLigaJugador}/sell?idUsuario=
  Future<LeagueSellPlayerResult> sellLeaguePlayer({
    required int idLiga,
    required int idLigaJugador,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/players/$idLigaJugador/sell',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty ||
          readLeagueInt(map, const ['idLigaJugador', 'id_liga_jugador']) <= 0) {
        throw const ApiException('Respuesta inválida de la venta de jugador.');
      }
      return LeagueSellPlayerResult.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/players/{idLigaJugador}/offers
  Future<ApiMessageModel> upsertOffer({
    required int idLiga,
    required int idLigaJugador,
    required int idUsuario,
    required int cantidad,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/players/$idLigaJugador/offers',
        data: <String, dynamic>{'idUsuario': idUsuario, 'cantidad': cantidad},
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/offers/sent?idUsuario=
  Future<List<LeagueOfferItem>> getSentOffers({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/offers/sent',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueOfferItem.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/offers/received?idUsuario=
  Future<List<LeagueOfferItem>> getReceivedOffers({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/offers/received',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueOfferItem.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/offers/{idOferta}/accept?idUsuario=
  Future<ApiMessageModel> acceptOffer({
    required int idLiga,
    required int idOferta,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/offers/$idOferta/accept',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/offers/{idOferta}/reject?idUsuario=
  Future<ApiMessageModel> rejectOffer({
    required int idLiga,
    required int idOferta,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/offers/$idOferta/reject',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// DELETE /leagues/{idLiga}/offers/{idOferta}?idUsuario=
  Future<ApiMessageModel> cancelOffer({
    required int idLiga,
    required int idOferta,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.leagues}/$idLiga/offers/$idOferta',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues — [CreateLeagueResponse] con `idLiga` y configuración aplicada.
  Future<CreateLeagueResponse> createLeague(CreateLeagueRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.leagues,
        data: request.toJson(),
      );
      final result = CreateLeagueResponse.fromJson(response.data);
      if (!result.isSuccess) {
        throw const ApiException(
          'Respuesta sin idLiga válido al crear la liga.',
        );
      }
      return result;
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/join — [JoinLeagueResponse] con `idLiga`, plantilla, etc.
  Future<JoinLeagueResponse> joinLeague({
    required String codigoInvitacion,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/join',
        data: <String, dynamic>{
          'codigoInvitacion': codigoInvitacion,
          'idUsuario': idUsuario,
        },
      );
      final result = JoinLeagueResponse.fromJson(response.data);
      if (!result.isSuccess) {
        final msg = result.mensaje?.trim();
        throw ApiException(
          msg != null && msg.isNotEmpty
              ? msg
              : 'No se pudo unir a la liga.',
        );
      }
      return result;
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> inviteFriendToLeague({
    required int idLiga,
    required int idUsuario,
    required int idAmigo,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/invite-friend',
        data: <String, dynamic>{
          'idUsuario': idUsuario,
          'idAmigo': idAmigo,
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/my?idUsuario=
  Future<List<LeagueSummary>> getMyLeagues({required int idUsuario}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/my',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueSummary.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}?idUsuario=
  Future<LeagueDetail> getLeagueDetail({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía del detalle de liga.');
      }
      return LeagueDetail.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/season-wrap?idUsuario=
  Future<LeagueSeasonWrap> getSeasonWrap({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/season-wrap',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía del resumen de temporada.');
      }
      return LeagueSeasonWrap.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/season-wrap/seen?idUsuario=
  Future<void> markSeasonWrapSeen({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/season-wrap/seen',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/standings?idUsuario=
  Future<List<LeagueStandingRow>> getStandings({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/standings',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueStandingRow.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/rounds/{idJornada}/standings?idUsuario=
  Future<List<LeagueRoundStandingRow>> getRoundStandings({
    required int idLiga,
    required int idJornada,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/rounds/$idJornada/standings',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueRoundStandingRow.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/team-standings?idUsuario=
  Future<List<LeagueTeamStandingRow>> getTeamStandings({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/team-standings',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueTeamStandingRow.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/home-feed?idUsuario=
  Future<LeagueHomeFeed> getHomeFeed({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/home-feed',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía del home-feed de la liga.');
      }
      return LeagueHomeFeed.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/participants?idUsuario=
  Future<List<LeagueParticipant>> getParticipants({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/participants',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueParticipant.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/unavailable-players?idUsuario=
  Future<List<LeagueUnavailablePlayer>> fetchUnavailablePlayers({
    required int leagueId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$leagueId/unavailable-players',
        queryParameters: <String, dynamic>{'idUsuario': userId},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueUnavailablePlayer.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/market/history?idUsuario=
  Future<List<LeagueMarketHistoryEntry>> getMarketHistory({
    required int leagueId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$leagueId/market/history',
        queryParameters: <String, dynamic>{'idUsuario': userId},
      );
      final rows = readLeagueListMap(response.data);
      return rows.map(LeagueMarketHistoryEntry.fromJson).toList();
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/participants/{idLigaParticipante}/squad?idUsuario= [&idJornada=]
  /// Plantilla y última alineación guardada de otro participante (solo lectura).
  Future<LeagueParticipantSquadPayload> getParticipantSquad({
    required int idLiga,
    required int idLigaParticipante,
    required int idUsuario,
    int? idJornada,
  }) async {
    if (idLigaParticipante <= 0) {
      throw const ApiException('Participante no válido.');
    }
    try {
      final qp = <String, dynamic>{'idUsuario': idUsuario};
      if (idJornada != null && idJornada > 0) {
        qp['idJornada'] = idJornada;
      }
      _debugLogStarterProbGet(
        'participant-squad-url',
        '${ApiConstants.leagues}/$idLiga/participants/$idLigaParticipante/squad',
        qp,
      );
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/participants/$idLigaParticipante/squad',
        queryParameters: qp,
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty ||
          readLeagueInt(map, const [
                'idLigaParticipante',
                'id_liga_participante',
              ]) <=
              0) {
        throw const ApiException(
          'Respuesta inválida de la plantilla del participante.',
        );
      }
      return LeagueParticipantSquadPayload.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/participants/{idLigaParticipante}/lineup-history?idUsuario=
  Future<LeagueParticipantLineupHistorySummary> getParticipantLineupHistory({
    required int idLiga,
    required int idLigaParticipante,
    required int idUsuario,
    int? fallbackParticipantUserId,
  }) async {
    if (idLigaParticipante <= 0 && (fallbackParticipantUserId ?? 0) <= 0) {
      throw const ApiException('Participante no válido.');
    }
    final candidates = <int>[
      if (idLigaParticipante > 0) idLigaParticipante,
      if (fallbackParticipantUserId != null &&
          fallbackParticipantUserId > 0 &&
          fallbackParticipantUserId != idLigaParticipante)
        fallbackParticipantUserId,
    ];
    ApiException? lastError;
    for (final participantId in candidates) {
      try {
        final response = await _apiClient.dio.get(
          '${ApiConstants.leagues}/$idLiga/participants/$participantId/lineup-history',
          queryParameters: <String, dynamic>{'idUsuario': idUsuario},
        );
        final map = readLeagueSingleMap(response.data);
        if (map.isEmpty) {
          throw const ApiException(
            'Respuesta vacía del historial de alineaciones.',
          );
        }
        return LeagueParticipantLineupHistorySummary.fromJson(map);
      } catch (e) {
        lastError = ApiException(_apiClient.extractErrorMessage(e));
      }
    }
    throw lastError ??
        const ApiException('No se pudo cargar el historial de alineaciones.');
  }

  /// GET /leagues/{idLiga}/participants/{idLigaParticipante}/lineup-history/{idJornada}?idUsuario=
  ///
  /// Cuando el backend incluya `entrenadorAsignado` (u objeto equivalente ya contemplado en
  /// [LeagueParticipantLineupRoundDetail.fromJson]), la UI lo muestra en el campo sin llamadas extra.
  ///
  /// **No** usar aquí [getCoachInventory], `GET .../coach` ni endpoints similares para pintar
  /// jornadas pasadas: devolverían el entrenador **actual**, no el histórico de esa jornada.
  Future<LeagueParticipantLineupRoundDetail> getParticipantLineupRoundDetail({
    required int idLiga,
    required int idLigaParticipante,
    required int idJornada,
    required int idUsuario,
    int? fallbackParticipantUserId,
  }) async {
    if (idLigaParticipante <= 0 && (fallbackParticipantUserId ?? 0) <= 0) {
      throw const ApiException('Participante no válido.');
    }
    if (idJornada <= 0) {
      throw const ApiException('Jornada no válida.');
    }
    final candidates = <int>[
      if (idLigaParticipante > 0) idLigaParticipante,
      if (fallbackParticipantUserId != null &&
          fallbackParticipantUserId > 0 &&
          fallbackParticipantUserId != idLigaParticipante)
        fallbackParticipantUserId,
    ];
    ApiException? lastError;
    for (final participantId in candidates) {
      try {
        final response = await _apiClient.dio.get(
          '${ApiConstants.leagues}/$idLiga/participants/$participantId/lineup-history/$idJornada',
          queryParameters: <String, dynamic>{'idUsuario': idUsuario},
        );
        if (kDebugMode) {
          debugPrint('[lineup-history-detail][response] body=${response.data}');
        }
        final map = readLeagueSingleMap(response.data);
        if (map.isEmpty) {
          throw const ApiException(
            'Respuesta vacía del detalle de alineación.',
          );
        }
        return LeagueParticipantLineupRoundDetail.fromJson(map);
      } catch (e) {
        lastError = ApiException(_apiClient.extractErrorMessage(e));
      }
    }
    throw lastError ??
        const ApiException('No se pudo cargar el detalle de alineación.');
  }

  /// GET /leagues/{idLiga}/squad?idUsuario= [&idJornada=]
  ///
  /// El backend devuelve un objeto raíz con `plantilla` y metadatos de entrenador/formación.
  Future<LeagueSquadResponse> getSquadResponse({
    required int idLiga,
    required int idUsuario,
    int? idJornada,
  }) async {
    try {
      final qp = <String, dynamic>{'idUsuario': idUsuario};
      if (idJornada != null && idJornada > 0) {
        qp['idJornada'] = idJornada;
      }
      _debugLogStarterProbGet(
        'squad-url',
        '${ApiConstants.leagues}/$idLiga/squad',
        qp,
      );
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/squad',
        queryParameters: qp,
      );
      final data = response.data;
      if (data is List) {
        final rows = <LeagueSquadPlayer>[];
        for (final e in data) {
          if (e is! Map) {
            continue;
          }
          final map = e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e);
          rows.add(LeagueSquadPlayer.fromJson(map));
        }
        _debugLogSquadParsedPlayers(rows);
        return LeagueSquadResponse.plantillaOnly(rows);
      }
      final map = readLeagueSingleMap(data);
      if (map.isEmpty) {
        return const LeagueSquadResponse();
      }
      final squadResp = LeagueSquadResponse.fromJson(map);
      _debugLogSquadParsedPlayers(squadResp.plantilla);
      return squadResp;
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/squad?idUsuario= [&idJornada=] — solo jugadores (compatibilidad).
  Future<List<LeagueSquadPlayer>> getSquad({
    required int idLiga,
    required int idUsuario,
    int? idJornada,
  }) async {
    final response = await getSquadResponse(
      idLiga: idLiga,
      idUsuario: idUsuario,
      idJornada: idJornada,
    );
    return response.plantilla;
  }

  /// GET /leagues/{idLiga}/participants/{idLigaParticipante}/coach/inventory?idUsuarioSolicitante=
  Future<List<LeagueCoachAssignment>> getCoachInventory({
    required int idLiga,
    required int idLigaParticipante,
    required int idUsuarioSolicitante,
  }) async {
    if (idLigaParticipante <= 0) {
      throw const ApiException('Participante no válido.');
    }
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/participants/$idLigaParticipante/coach/inventory',
        queryParameters: <String, dynamic>{
          'idUsuarioSolicitante': idUsuarioSolicitante,
        },
      );
      final data = response.data;
      if (data == null) {
        return const [];
      }
      if (data is String && data.trim().isEmpty) {
        return const [];
      }
      if (data is List) {
        return LeagueCoachAssignment.listFromJson(data);
      }
      final map = readLeagueSingleMap(data);
      if (map.isEmpty) {
        return const [];
      }
      return LeagueCoachAssignment.listFromJson(map['entrenadores']);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// PATCH /leagues/{idLiga}/participants/{idLigaParticipante}/coach/active
  Future<LeagueCoachAssignment> setCoachActive({
    required int idLiga,
    required int idLigaParticipante,
    required int idUsuarioSolicitante,
    required bool activo,
    int? idEntrenador,
  }) async {
    if (idLigaParticipante <= 0) {
      throw const ApiException('Participante no válido.');
    }
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.leagues}/$idLiga/participants/$idLigaParticipante/coach/active',
        data: <String, dynamic>{
          'idUsuarioSolicitante': idUsuarioSolicitante,
          'activo': activo,
          if (idEntrenador != null && idEntrenador > 0)
            'idEntrenador': idEntrenador,
        },
      );
      final map = readLeagueSingleMap(response.data);
      Object? coachRaw =
          map['entrenadorAsignado'] ?? map['coach'] ?? map['assignment'];
      if (coachRaw is Map) {
        final c = LeagueCoachAssignment.maybeFromJson(coachRaw);
        if (c != null && (c.idEntrenador ?? 0) > 0) {
          return c;
        }
      }
      final direct = LeagueCoachAssignment.maybeFromJson(map);
      if (direct != null && (direct.idEntrenador ?? 0) > 0) {
        return direct;
      }
      if (!activo) {
        return const LeagueCoachAssignment(activo: false);
      }
      if (activo &&
          idEntrenador != null &&
          idEntrenador > 0) {
        return LeagueCoachAssignment(
          idEntrenador: idEntrenador,
          activo: true,
        );
      }
      final msg = map['message']?.toString().trim();
      if (msg != null && msg.isNotEmpty) {
        throw ApiException(msg);
      }
      throw const ApiException(
        'No se pudo leer el entrenador en la respuesta del servidor.',
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/lineup?idUsuario=
  Future<LeagueEditableLineup> getEditableLineup({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/lineup',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
      final map = readLeagueSingleMap(response.data);
      if (map.isEmpty) {
        throw const ApiException('Respuesta vacía de la alineación fantasy.');
      }
      return LeagueEditableLineup.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/lineup
  Future<void> saveLineup({
    required int idLiga,
    required int idUsuario,
    required int idJornada,
    required List<int> titulares,
    required List<int> reservas,
    required int idCapitan,
  }) async {
    final endpoint = '${ApiConstants.leagues}/$idLiga/lineup';
    final payload = <String, dynamic>{
      'idUsuario': idUsuario,
      'idJornada': idJornada,
      'titulares': titulares,
      'reservas': reservas,
      'idCapitan': idCapitan,
    };
    if (kDebugMode) {
      debugPrint('[saveLineup][request] method=POST');
      debugPrint(
        '[saveLineup][request] url=${_apiClient.dio.options.baseUrl}$endpoint',
      );
      debugPrint(
        '[saveLineup][request] contentType=${_apiClient.dio.options.contentType}',
      );
      debugPrint('[saveLineup][request] body=$payload');
    }
    try {
      final response = await _apiClient.dio.post(endpoint, data: payload);
      if (kDebugMode) {
        debugPrint('[saveLineup][response] status=${response.statusCode}');
        debugPrint('[saveLineup][response] body=${response.data}');
      }
    } catch (e) {
      if (kDebugMode && e is DioException) {
        debugPrint('[saveLineup][error] status=${e.response?.statusCode}');
        debugPrint('[saveLineup][error] body=${e.response?.data}');
      }
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/leave
  Future<void> leaveLeague({
    required int idLiga,
    required int idUsuario,
    int? nuevoAdministradorId,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/leave',
        data: <String, dynamic>{
          'idUsuario': idUsuario,
          'nuevoAdministradorId': nuevoAdministradorId,
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/close?idUsuario=
  Future<void> closeLeague({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/close',
        queryParameters: <String, dynamic>{'idUsuario': idUsuario},
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/admin/transfer
  Future<ApiMessageModel> transferLeagueAdmin({
    required int idLiga,
    required int idAdminActual,
    required int idNuevoAdmin,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/admin/transfer',
        data: <String, dynamic>{
          'idAdminActual': idAdminActual,
          'idNuevoAdmin': idNuevoAdmin,
        },
      );
      final map = readLeagueSingleMap(response.data);
      return ApiMessageModel.fromJson(map);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/kick
  Future<void> kickParticipant({
    required int idLiga,
    required int idAdminUsuario,
    required int idUsuarioExpulsado,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/kick',
        data: <String, dynamic>{
          'idAdminUsuario': idAdminUsuario,
          'idUsuarioExpulsado': idUsuarioExpulsado,
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/activity?idUsuario=&limit=&offset=
  Future<List<LeagueActivityEvent>> getLeagueActivity({
    required int idLiga,
    required int idUsuario,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/activity',
        queryParameters: <String, dynamic>{
          'idUsuario': idUsuario,
          'limit': limit,
          'offset': offset,
        },
      );
      return LeagueActivityEvent.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/chat?idUsuario=&recent=true|afterId=
  Future<List<LeagueChatMessage>> getLeagueChatMessages({
    required int idLiga,
    required int idUsuario,
    int? afterId,
    bool recent = false,
    int limit = 100,
  }) async {
    try {
      final params = <String, dynamic>{
        'idUsuario': idUsuario,
        'limit': limit,
      };
      if (recent) {
        params['recent'] = true;
      } else if (afterId != null) {
        params['afterId'] = afterId;
      }
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/chat',
        queryParameters: params,
      );
      return LeagueChatMessage.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/chat
  Future<LeagueChatMessage> postLeagueChatMessage({
    required int idLiga,
    required int idUsuario,
    required String texto,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/chat',
        data: <String, dynamic>{
          'idUsuario': idUsuario,
          'texto': texto,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Respuesta de chat inválida');
      }
      final m = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);
      return LeagueChatMessage.fromJson(m);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> reportLeagueChatMessage({
    required int idLiga,
    required int idMensaje,
    required int idUsuario,
    String? motivo,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/chat/$idMensaje/report',
        data: {
          'idUsuario': idUsuario,
          if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
        },
      );
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/dm/threads
  Future<List<LeagueDmThread>> getLeagueDmThreads({
    required int idLiga,
    required int idUsuario,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/dm/threads',
        queryParameters: {'idUsuario': idUsuario},
      );
      return LeagueDmThread.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// GET /leagues/{idLiga}/dm/{idPeer}
  Future<List<LeagueDmMessage>> getLeagueDmMessages({
    required int idLiga,
    required int idUsuario,
    required int idPeer,
    int? afterId,
    bool recent = false,
    int limit = 100,
  }) async {
    try {
      final params = <String, dynamic>{
        'idUsuario': idUsuario,
        'limit': limit,
      };
      if (recent) {
        params['recent'] = true;
      } else if (afterId != null) {
        params['afterId'] = afterId;
      }
      final response = await _apiClient.dio.get(
        '${ApiConstants.leagues}/$idLiga/dm/$idPeer',
        queryParameters: params,
      );
      return LeagueDmMessage.listFrom(response.data);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }

  /// POST /leagues/{idLiga}/dm/{idPeer}
  Future<LeagueDmMessage> postLeagueDmMessage({
    required int idLiga,
    required int idUsuario,
    required int idPeer,
    required String texto,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.leagues}/$idLiga/dm/$idPeer',
        data: <String, dynamic>{
          'idUsuario': idUsuario,
          'idDestino': idPeer,
          'texto': texto,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Respuesta de mensaje privado inválida');
      }
      final m = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);
      return LeagueDmMessage.fromJson(m);
    } catch (e) {
      throw ApiException(_apiClient.extractErrorMessage(e));
    }
  }
}

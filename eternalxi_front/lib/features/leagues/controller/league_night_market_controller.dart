import 'package:eternal_xi/data/models/night_market_models.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:flutter/foundation.dart';

/// Estado del mercado nocturno dentro de la pestaña Mercado de una liga.
class LeagueNightMarketController extends ChangeNotifier {
  LeagueNightMarketController({
    required LeaguesApiService leaguesApiService,
    required this.idLiga,
    required this.idUsuario,
  }) : _api = leaguesApiService;

  final LeaguesApiService _api;
  final int idLiga;
  final int idUsuario;

  NightMarketResponse? data;
  String? errorMessage;
  bool isLoading = false;
  bool isRefreshing = false;
  int? actionItemId;

  Future<void> load() async {
    if (idLiga <= 0 || idUsuario <= 0) {
      errorMessage = 'Usuario o liga no válidos.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _api.getNightMarket(idLiga: idLiga, idUsuario: idUsuario);
    } catch (e) {
      data = null;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Devuelve mensaje de error si falla (los datos previos se conservan).
  Future<String?> refresh() async {
    if (idLiga <= 0 || idUsuario <= 0) {
      return 'Usuario o liga no válidos.';
    }
    isRefreshing = true;
    notifyListeners();
    try {
      data = await _api.getNightMarket(idLiga: idLiga, idUsuario: idUsuario);
      errorMessage = null;
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<({String message, bool success})> submitBid({
    required int idMercadoDiario,
    required int cantidad,
  }) async {
    actionItemId = idMercadoDiario;
    notifyListeners();
    try {
      final response = await _api.upsertNightMarketBid(
        idLiga: idLiga,
        idMercadoDiario: idMercadoDiario,
        idUsuario: idUsuario,
        cantidad: cantidad,
      );
      final m = response.message.trim();
      final baseMsg = m.isEmpty ? 'Puja guardada correctamente' : m;
      try {
        await _reloadAfterAction();
      } catch (_) {
        final message =
            '$baseMsg No se pudo refrescar el mercado; desliza hacia abajo para actualizar.';
        return (message: message, success: true);
      }
      return (message: baseMsg, success: true);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return (message: message, success: false);
    } finally {
      actionItemId = null;
      notifyListeners();
    }
  }

  Future<({String message, bool success})> deleteBid({
    required int idMercadoDiario,
  }) async {
    actionItemId = idMercadoDiario;
    notifyListeners();
    try {
      final response = await _api.deleteNightMarketBid(
        idLiga: idLiga,
        idMercadoDiario: idMercadoDiario,
        idUsuario: idUsuario,
      );
      final m = response.message.trim();
      final baseMsg = m.isEmpty ? 'Puja eliminada correctamente' : m;
      try {
        await _reloadAfterAction();
      } catch (_) {
        final message =
            '$baseMsg No se pudo refrescar el mercado; desliza hacia abajo para actualizar.';
        return (message: message, success: true);
      }
      return (message: baseMsg, success: true);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return (message: message, success: false);
    } finally {
      actionItemId = null;
      notifyListeners();
    }
  }

  Future<void> _reloadAfterAction() async {
    data = await _api.getNightMarket(idLiga: idLiga, idUsuario: idUsuario);
  }
}

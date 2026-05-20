import 'package:eternal_xi/data/models/league_offer_item.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:flutter/foundation.dart';

class LeagueOffersController extends ChangeNotifier {
  LeagueOffersController({
    required LeaguesApiService leaguesApiService,
    required this.idLiga,
    required this.idUsuario,
  }) : _api = leaguesApiService;

  final LeaguesApiService _api;
  final int idLiga;
  final int idUsuario;

  List<LeagueOfferItem> sent = const [];
  List<LeagueOfferItem> received = const [];

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  int? actionOfferId;

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
      final all = await Future.wait([
        _api.getSentOffers(idLiga: idLiga, idUsuario: idUsuario),
        _api.getReceivedOffers(idLiga: idLiga, idUsuario: idUsuario),
      ]);
      sent = all[0];
      received = all[1];
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      sent = const [];
      received = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> refresh() async {
    if (idLiga <= 0 || idUsuario <= 0) {
      return 'Usuario o liga no válidos.';
    }
    isRefreshing = true;
    notifyListeners();
    try {
      final all = await Future.wait([
        _api.getSentOffers(idLiga: idLiga, idUsuario: idUsuario),
        _api.getReceivedOffers(idLiga: idLiga, idUsuario: idUsuario),
      ]);
      sent = all[0];
      received = all[1];
      errorMessage = null;
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<({bool success, String message})> cancel(int idOferta) async {
    actionOfferId = idOferta;
    notifyListeners();
    try {
      final response = await _api.cancelOffer(
        idLiga: idLiga,
        idOferta: idOferta,
        idUsuario: idUsuario,
      );
      final msg = response.message.trim().isEmpty
          ? 'Oferta cancelada correctamente.'
          : response.message.trim();
      await refresh();
      return (success: true, message: msg);
    } catch (e) {
      return (
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      actionOfferId = null;
      notifyListeners();
    }
  }

  Future<({bool success, String message})> accept(int idOferta) async {
    actionOfferId = idOferta;
    notifyListeners();
    try {
      final response = await _api.acceptOffer(
        idLiga: idLiga,
        idOferta: idOferta,
        idUsuario: idUsuario,
      );
      final msg = response.message.trim().isEmpty
          ? 'Oferta aceptada correctamente.'
          : response.message.trim();
      await refresh();
      return (success: true, message: msg);
    } catch (e) {
      return (
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      actionOfferId = null;
      notifyListeners();
    }
  }

  Future<({bool success, String message})> reject(int idOferta) async {
    actionOfferId = idOferta;
    notifyListeners();
    try {
      final response = await _api.rejectOffer(
        idLiga: idLiga,
        idOferta: idOferta,
        idUsuario: idUsuario,
      );
      final msg = response.message.trim().isEmpty
          ? 'Oferta rechazada correctamente.'
          : response.message.trim();
      await refresh();
      return (success: true, message: msg);
    } catch (e) {
      return (
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      actionOfferId = null;
      notifyListeners();
    }
  }
}

import 'package:eternal_xi/data/models/league_summary.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:flutter/material.dart';

/// Estado del listado "mis ligas". El detalle y formularios cargan vía servicio en pantalla.
class LeaguesController extends ChangeNotifier {
  LeaguesController({required LeaguesApiService leaguesApiService})
    : _leaguesApiService = leaguesApiService;

  final LeaguesApiService _leaguesApiService;

  List<LeagueSummary> myLeagues = [];
  bool isLoading = false;
  String? errorMessage;

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> loadMyLeagues(int idUsuario) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      myLeagues = await _leaguesApiService.getMyLeagues(idUsuario: idUsuario);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      myLeagues = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

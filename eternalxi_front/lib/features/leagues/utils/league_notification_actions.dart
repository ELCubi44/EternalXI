import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/models/user_notification_item.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_market.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_squad.dart';
import 'package:flutter/material.dart';

Future<void> handleLeagueNotificationTap({
  required BuildContext context,
  required UserNotificationItem notification,
  required int leagueId,
  required int idUsuario,
}) async {
  final shell = LeagueShellData.maybeOf(context);
  final tab = notification.actionTab;
  final segment = notification.actionSegment ?? 0;

  if (tab == 'squad') {
    shell?.selectTab(2);
    if (segment >= 0 && segment <= 1) {
      LeagueTabSquad.externalSegmentRequest.value = segment;
    }
  } else if (tab == 'market') {
    shell?.selectTab(3);
    if (segment >= 0 && segment <= 2) {
      LeagueTabMarket.externalSegmentRequest.value = segment;
    }
  }

  final idLigaJugador = notification.idLigaJugador;
  if (idLigaJugador != null &&
      idLigaJugador > 0 &&
      (notification.tipo == 'offer_received' ||
          notification.tipo == 'CLAUSE_EXECUTED')) {
    final name = notification.playerName ?? 'Jugador';
    final stub = LeagueSquadPlayer(
      idLigaJugador: idLigaJugador,
      idJugador: notification.idJugador ?? 0,
      nombre: name,
      pila: name,
      posicion: 'MED',
      valoracion: 0,
      idEquipo: 0,
      nombreEquipo: '',
      estado: 'DISPONIBLE',
      cansancio: 0,
      valor: 0,
      fotoJugador: notification.playerPhotoUrl ?? '',
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: 0,
      idLiga: leagueId,
    );
    await LeagueInnerNavigation.openPlayerProfile(
      context: context,
      player: stub,
      leagueId: leagueId,
      idLigaJugador: idLigaJugador,
      idUsuario: idUsuario,
    );
  }
}

String? resolveNotificationImageUrl(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  if (raw.contains('/users/') && !raw.contains('photo')) {
    final id = int.tryParse(raw.split('/').where((p) => p.isNotEmpty).last);
    if (id != null) {
      return ApiConstants.userProfilePhotoUrl(id, cacheBuster: id);
    }
  }
  return LeagueAssetUrls.buildBackendImageUrl(raw);
}

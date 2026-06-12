import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/data/models/user_notification_item.dart';
import 'package:eternal_xi/features/leagues/navigation/league_inner_navigation.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_tabs.dart';
import 'package:eternal_xi/features/leagues/tabs/league_tab_market.dart';
import 'package:flutter/material.dart';

String normalizeNotificationTipo(String raw) => raw.trim().toLowerCase();

/// Evita mostrar el importe dos veces cuando ya viene en [UserNotificationItem.mensaje].
bool notificationMessageAlreadyShowsPrice(String message) {
  return message.contains('€');
}

bool notificationHasAction(UserNotificationItem item) {
  if (item.actionTab != null && item.actionTab!.trim().isNotEmpty) {
    return true;
  }
  return _tipoOpensDestination(normalizeNotificationTipo(item.tipo));
}

Future<void> handleLeagueNotificationTap({
  required BuildContext context,
  required UserNotificationItem notification,
  required int leagueId,
  required int idUsuario,
}) async {
  final shell = LeagueShellData.maybeOf(context);
  final tipo = normalizeNotificationTipo(notification.tipo);
  final idLigaJugador = notification.idLigaJugador;

  switch (tipo) {
    case 'market_purchase':
    case 'offer_accepted':
    case 'market_award':
      shell?.openSquad(segment: 0);
      if (idLigaJugador != null && idLigaJugador > 0) {
        await _openNotificationPlayerProfile(
          context: context,
          notification: notification,
          leagueId: leagueId,
          idUsuario: idUsuario,
          isOwnPlayerHint: true,
        );
      }
      return;

    case 'offer_received':
      if (idLigaJugador != null && idLigaJugador > 0) {
        await _openNotificationPlayerProfile(
          context: context,
          notification: notification,
          leagueId: leagueId,
          idUsuario: idUsuario,
          isOwnPlayerHint: true,
        );
      } else {
        shell?.selectTab(LeagueShellTabs.market);
        LeagueTabMarket.externalSegmentRequest.value = 1;
      }
      return;

    case 'offer_rejected':
      shell?.selectTab(LeagueShellTabs.market);
      LeagueTabMarket.externalSegmentRequest.value = 2;
      return;

    case 'clause_executed':
      shell?.openSquad(segment: 1);
      if (idLigaJugador != null && idLigaJugador > 0) {
        await _openNotificationPlayerProfile(
          context: context,
          notification: notification,
          leagueId: leagueId,
          idUsuario: idUsuario,
          isOwnPlayerHint: false,
        );
      }
      return;

    case 'lineup_player_injured':
    case 'lineup_player_sanctioned':
      shell?.openSquad(segment: 0);
      if (idLigaJugador != null && idLigaJugador > 0) {
        await _openNotificationPlayerProfile(
          context: context,
          notification: notification,
          leagueId: leagueId,
          idUsuario: idUsuario,
          isOwnPlayerHint: true,
        );
      }
      return;

    default:
      _applyLegacyActionTab(notification, shell);
      if (idLigaJugador != null &&
          idLigaJugador > 0 &&
          _legacyOpensPlayerProfile(tipo)) {
        await _openNotificationPlayerProfile(
          context: context,
          notification: notification,
          leagueId: leagueId,
          idUsuario: idUsuario,
        );
      }
  }
}

bool _tipoOpensDestination(String tipo) {
  switch (tipo) {
    case 'market_purchase':
    case 'offer_accepted':
    case 'market_award':
    case 'offer_received':
    case 'offer_rejected':
    case 'clause_executed':
    case 'lineup_player_injured':
    case 'lineup_player_sanctioned':
      return true;
    default:
      return false;
  }
}

bool _legacyOpensPlayerProfile(String tipo) {
  return tipo == 'offer_received' || tipo == 'clause_executed';
}

void _applyLegacyActionTab(
  UserNotificationItem notification,
  LeagueShellData? shell,
) {
  final tab = notification.actionTab;
  if (shell == null || tab == null || tab.isEmpty) {
    return;
  }
  final segment = notification.actionSegment ?? 0;
  if (tab == 'squad') {
    shell.openSquad(segment: segment.clamp(0, 1));
  } else if (tab == 'market' || tab == 'transfers' || tab == 'offers') {
    shell.selectTab(LeagueShellTabs.market);
    if (segment >= 0 && segment <= 2) {
      LeagueTabMarket.externalSegmentRequest.value = segment;
    }
  }
}

Future<void> _openNotificationPlayerProfile({
  required BuildContext context,
  required UserNotificationItem notification,
  required int leagueId,
  required int idUsuario,
  bool? isOwnPlayerHint,
}) async {
  final idLigaJugador = notification.idLigaJugador;
  if (idLigaJugador == null || idLigaJugador <= 0) {
    return;
  }
  final name = notification.playerName ?? 'Jugador';
  final player = LeagueSquadPlayer(
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
    valor: notification.precio?.toDouble() ?? 0,
    fotoJugador: notification.playerPhotoUrl ?? '',
    enPoolMercado: false,
    propietarioNick: '',
    idUsuarioDueno: isOwnPlayerHint == true ? idUsuario : 0,
    idLiga: leagueId,
  );
  await LeagueInnerNavigation.openPlayerProfile(
    context: context,
    player: player,
    leagueId: leagueId,
    idLigaJugador: idLigaJugador,
    idUsuario: idUsuario,
    isOwnPlayerHint: isOwnPlayerHint,
  );
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

/// Foto del jugador en notificaciones: URL guardada o fallback por [idJugador].
String? resolveNotificationPlayerImageUrl(UserNotificationItem item) {
  return LeagueAssetUrls.resolvePlayerPhotoUrl(
    idJugador: item.idJugador ?? 0,
    rawFoto: item.playerPhotoUrl,
  );
}

/// Foto del actor (manager rival): URL guardada o fallback por [idUsuarioActor].
String? resolveNotificationActorImageUrl(UserNotificationItem item) {
  final fromRaw = resolveNotificationImageUrl(item.actorPhotoUrl);
  if (fromRaw != null) {
    return fromRaw;
  }
  final id = item.idUsuarioActor;
  if (id != null && id > 0) {
    return ApiConstants.userProfilePhotoUrl(id, cacheBuster: id);
  }
  return null;
}

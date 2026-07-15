import 'package:eternal_xi/app/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Registra listeners FCM para refrescar notificaciones y abrir la liga correspondiente.
class PushNotificationHandler {
  PushNotificationHandler._();

  static final PushNotificationHandler instance = PushNotificationHandler._();

  VoidCallback? onForegroundMessage;
  bool _initialized = false;

  Future<void> initialize(GoRouter router) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onMessage.listen((_) {
      onForegroundMessage?.call();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromMessage(router, message.data);
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _navigateFromMessage(router, initial.data);
    }
  }

  void _navigateFromMessage(GoRouter router, Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type == 'FRIEND_REQUEST' || data['actionRoute'] == 'friends') {
      router.push(AppRoutes.profileFriends);
      return;
    }
    if (type == 'LEAGUE_INVITE' || data['actionRoute'] == 'join_league') {
      final code = data['codigoInvitacion']?.toString();
      if (code != null && code.isNotEmpty) {
        router.push('${AppRoutes.leaguesJoin}?code=$code');
      } else {
        router.push(AppRoutes.leaguesJoin);
      }
      return;
    }

    final idLigaRaw = data['idLiga']?.toString();
    final idLiga = int.tryParse(idLigaRaw ?? '');
    if (idLiga == null || idLiga <= 0) {
      return;
    }
    if (type == 'LEAGUE_SEASON_WRAP' || data['actionRoute'] == 'league_season_wrap') {
      router.push(AppRoutes.leagueDetail(idLiga));
      return;
    }

    router.push(AppRoutes.leagueDetail(idLiga));
  }
}

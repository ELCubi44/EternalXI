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
    final idLigaRaw = data['idLiga']?.toString();
    final idLiga = int.tryParse(idLigaRaw ?? '');
    if (idLiga == null || idLiga <= 0) {
      return;
    }
    router.push(AppRoutes.leagueDetail(idLiga));
  }
}

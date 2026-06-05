import 'package:eternal_xi/data/models/user_notification_item.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:flutter/foundation.dart';

class LeagueNotificationsController extends ChangeNotifier {
  LeagueNotificationsController({
    required UserApiService userApiService,
    required int idUsuario,
    required int idLiga,
  })  : _userApiService = userApiService,
        _idUsuario = idUsuario,
        _idLiga = idLiga;

  final UserApiService _userApiService;
  final int _idUsuario;
  final int _idLiga;

  List<UserNotificationItem> _items = const [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;

  List<UserNotificationItem> get items => _items;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _userApiService.getNotifications(
        idUsuario: _idUsuario,
        idLiga: _idLiga,
        limit: 40,
      );
      _items = response.items;
      _unreadCount = response.noLeidas;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _userApiService.getUnreadNotificationsCount(
        idUsuario: _idUsuario,
        idLiga: _idLiga,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markRead(UserNotificationItem item) async {
    if (item.leida) {
      return;
    }
    try {
      await _userApiService.markNotificationsRead(
        idUsuario: _idUsuario,
        ids: [item.id],
      );
      _items = _items
          .map(
            (n) => n.id == item.id
                ? UserNotificationItem(
                    id: n.id,
                    idLiga: n.idLiga,
                    tipo: n.tipo,
                    titulo: n.titulo,
                    mensaje: n.mensaje,
                    leida: true,
                    datos: n.datos,
                    creadaEn: n.creadaEn,
                  )
                : n,
          )
          .toList();
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _userApiService.markNotificationsRead(
        idUsuario: _idUsuario,
        idLiga: _idLiga,
        marcarTodas: true,
      );
      _items = _items
          .map(
            (n) => UserNotificationItem(
              id: n.id,
              idLiga: n.idLiga,
              tipo: n.tipo,
              titulo: n.titulo,
              mensaje: n.mensaje,
              leida: true,
              datos: n.datos,
              creadaEn: n.creadaEn,
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}

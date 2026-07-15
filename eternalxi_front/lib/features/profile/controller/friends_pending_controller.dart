import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:flutter/foundation.dart';

/// Contador de solicitudes de amistad entrantes (badge en perfil / amigos).
class FriendsPendingController extends ChangeNotifier {
  FriendsPendingController(this._userApi);

  final UserApiService _userApi;

  int _incomingCount = 0;

  int get incomingCount => _incomingCount;
  bool get hasPending => _incomingCount > 0;

  Future<void> refresh(int userId) async {
    if (userId <= 0) return;
    try {
      final rows = await _userApi.listFriendships(idUsuario: userId);
      _incomingCount = rows
          .where((f) => f.isPending && !f.soySolicitante)
          .length;
    } catch (_) {
      // Mantener ultimo valor conocido.
    } finally {
      notifyListeners();
    }
  }
}

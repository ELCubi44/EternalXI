import 'package:flutter/foundation.dart';

/// Pestaña activa del shell Clash compartida entre rutas internas.
class ClashNavigationController extends ChangeNotifier {
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void selectTab(int index) {
    if (index < 0 || index > 3 || index == _tabIndex) {
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }
}

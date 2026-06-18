import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local del inventario de tickets (Fase 26).
abstract class ClashGachaTicketInventoryStorageBackend {
  Map<String, int> readQuantities();

  Future<void> writeQuantities(Map<String, int> quantities);

  Future<void> clearAll();
}

class SharedPreferencesClashGachaTicketInventoryBackend
    implements ClashGachaTicketInventoryStorageBackend {
  SharedPreferencesClashGachaTicketInventoryBackend(this._prefs);

  static const storageKey = 'clash_gacha_ticket_inventory_v1';
  static const defaultStarterTicketId = 'starter-single-ticket';
  static const defaultStarterQuantity = 3;

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashGachaTicketInventoryBackend>
  create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashGachaTicketInventoryBackend(prefs);
  }

  @override
  Map<String, int> readQuantities() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return {defaultStarterTicketId: defaultStarterQuantity};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return {defaultStarterTicketId: defaultStarterQuantity};
    }
    final quantities = <String, int>{};
    decoded.forEach((key, value) {
      final quantity = value is int ? value : int.tryParse('$value') ?? 0;
      if (quantity > 0) {
        quantities[key.toString()] = quantity;
      }
    });
    if (quantities.isEmpty) {
      return {defaultStarterTicketId: defaultStarterQuantity};
    }
    return quantities;
  }

  @override
  Future<void> writeQuantities(Map<String, int> quantities) async {
    final sanitized = <String, int>{};
    quantities.forEach((key, value) {
      if (value > 0) {
        sanitized[key] = value;
      }
    });
    await _prefs.setString(storageKey, jsonEncode(sanitized));
  }

  @override
  Future<void> clearAll() => _prefs.remove(storageKey);
}

class InMemoryClashGachaTicketInventoryBackend
    implements ClashGachaTicketInventoryStorageBackend {
  InMemoryClashGachaTicketInventoryBackend({Map<String, int>? initial}) {
    if (initial != null) {
      _quantities.addAll(initial);
      _explicit = true;
    }
  }

  final Map<String, int> _quantities = {};
  bool _explicit = false;

  @override
  Map<String, int> readQuantities() {
    if (!_explicit && _quantities.isEmpty) {
      return {
        SharedPreferencesClashGachaTicketInventoryBackend
                .defaultStarterTicketId:
            SharedPreferencesClashGachaTicketInventoryBackend
                .defaultStarterQuantity,
      };
    }
    return Map<String, int>.from(_quantities);
  }

  @override
  Future<void> writeQuantities(Map<String, int> quantities) async {
    _quantities
      ..clear()
      ..addAll(quantities);
  }

  @override
  Future<void> clearAll() async {
    _quantities.clear();
  }
}

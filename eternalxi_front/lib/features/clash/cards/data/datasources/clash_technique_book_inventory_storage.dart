import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot del inventario local de libros de técnica.
class ClashTechniqueBookInventorySnapshot {
  const ClashTechniqueBookInventorySnapshot({this.quantities = const {}});

  final Map<String, int> quantities;

  ClashTechniqueBookInventorySnapshot copyWith({Map<String, int>? quantities}) {
    return ClashTechniqueBookInventorySnapshot(
      quantities: quantities ?? this.quantities,
    );
  }

  Map<String, dynamic> toJson() => {'quantities': quantities};

  factory ClashTechniqueBookInventorySnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['quantities'] as Map? ?? const {};
    final quantities = <String, int>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is int) {
        quantities[entry.key.toString()] = value;
      } else if (value is num) {
        quantities[entry.key.toString()] = value.toInt();
      }
    }
    return ClashTechniqueBookInventorySnapshot(quantities: quantities);
  }
}

abstract class ClashTechniqueBookInventoryStorageBackend {
  ClashTechniqueBookInventorySnapshot readSnapshot();

  Future<void> writeSnapshot(ClashTechniqueBookInventorySnapshot snapshot);
}

class SharedPreferencesClashTechniqueBookInventoryBackend
    implements ClashTechniqueBookInventoryStorageBackend {
  SharedPreferencesClashTechniqueBookInventoryBackend(this._prefs);

  static const storageKey = 'clash_technique_book_inventory_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashTechniqueBookInventoryBackend>
  create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashTechniqueBookInventoryBackend(prefs);
  }

  @override
  ClashTechniqueBookInventorySnapshot readSnapshot() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const ClashTechniqueBookInventorySnapshot();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const ClashTechniqueBookInventorySnapshot();
    }
    return ClashTechniqueBookInventorySnapshot.fromJson(decoded);
  }

  @override
  Future<void> writeSnapshot(
    ClashTechniqueBookInventorySnapshot snapshot,
  ) async {
    await _prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearForTests() async {
    await _prefs.remove(storageKey);
  }
}

class InMemoryClashTechniqueBookInventoryBackend
    implements ClashTechniqueBookInventoryStorageBackend {
  ClashTechniqueBookInventorySnapshot _snapshot =
      const ClashTechniqueBookInventorySnapshot();

  @override
  ClashTechniqueBookInventorySnapshot readSnapshot() => _snapshot;

  @override
  Future<void> writeSnapshot(
    ClashTechniqueBookInventorySnapshot snapshot,
  ) async {
    _snapshot = snapshot;
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot del inventario local de materiales EXP.
class ClashExpMaterialInventorySnapshot {
  const ClashExpMaterialInventorySnapshot({this.quantities = const {}});

  final Map<String, int> quantities;

  ClashExpMaterialInventorySnapshot copyWith({Map<String, int>? quantities}) {
    return ClashExpMaterialInventorySnapshot(
      quantities: quantities ?? this.quantities,
    );
  }

  Map<String, dynamic> toJson() => {'quantities': quantities};

  factory ClashExpMaterialInventorySnapshot.fromJson(
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
    return ClashExpMaterialInventorySnapshot(quantities: quantities);
  }
}

abstract class ClashExpMaterialInventoryStorageBackend {
  ClashExpMaterialInventorySnapshot readSnapshot();

  Future<void> writeSnapshot(ClashExpMaterialInventorySnapshot snapshot);
}

class SharedPreferencesClashExpMaterialInventoryBackend
    implements ClashExpMaterialInventoryStorageBackend {
  SharedPreferencesClashExpMaterialInventoryBackend(this._prefs);

  static const storageKey = 'clash_exp_material_inventory_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashExpMaterialInventoryBackend>
  create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashExpMaterialInventoryBackend(prefs);
  }

  @override
  ClashExpMaterialInventorySnapshot readSnapshot() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const ClashExpMaterialInventorySnapshot();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const ClashExpMaterialInventorySnapshot();
    }
    return ClashExpMaterialInventorySnapshot.fromJson(decoded);
  }

  @override
  Future<void> writeSnapshot(ClashExpMaterialInventorySnapshot snapshot) async {
    await _prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearForTests() async {
    await _prefs.remove(storageKey);
  }
}

class InMemoryClashExpMaterialInventoryBackend
    implements ClashExpMaterialInventoryStorageBackend {
  ClashExpMaterialInventorySnapshot _snapshot =
      const ClashExpMaterialInventorySnapshot();

  @override
  ClashExpMaterialInventorySnapshot readSnapshot() => _snapshot;

  @override
  Future<void> writeSnapshot(ClashExpMaterialInventorySnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

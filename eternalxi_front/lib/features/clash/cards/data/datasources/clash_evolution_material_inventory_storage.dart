import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClashEvolutionMaterialInventorySnapshot {
  const ClashEvolutionMaterialInventorySnapshot({this.quantities = const {}});

  final Map<String, int> quantities;

  ClashEvolutionMaterialInventorySnapshot copyWith({
    Map<String, int>? quantities,
  }) {
    return ClashEvolutionMaterialInventorySnapshot(
      quantities: quantities ?? this.quantities,
    );
  }

  Map<String, dynamic> toJson() => {'quantities': quantities};

  factory ClashEvolutionMaterialInventorySnapshot.fromJson(
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
    return ClashEvolutionMaterialInventorySnapshot(quantities: quantities);
  }
}

abstract class ClashEvolutionMaterialInventoryStorageBackend {
  ClashEvolutionMaterialInventorySnapshot readSnapshot();

  Future<void> writeSnapshot(ClashEvolutionMaterialInventorySnapshot snapshot);
}

class SharedPreferencesClashEvolutionMaterialInventoryBackend
    implements ClashEvolutionMaterialInventoryStorageBackend {
  SharedPreferencesClashEvolutionMaterialInventoryBackend(this._prefs);

  static const storageKey = 'clash_evolution_material_inventory_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashEvolutionMaterialInventoryBackend>
  create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashEvolutionMaterialInventoryBackend(prefs);
  }

  @override
  ClashEvolutionMaterialInventorySnapshot readSnapshot() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const ClashEvolutionMaterialInventorySnapshot();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const ClashEvolutionMaterialInventorySnapshot();
    }
    return ClashEvolutionMaterialInventorySnapshot.fromJson(decoded);
  }

  @override
  Future<void> writeSnapshot(
    ClashEvolutionMaterialInventorySnapshot snapshot,
  ) async {
    await _prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearForTests() async {
    await _prefs.remove(storageKey);
  }
}

class InMemoryClashEvolutionMaterialInventoryBackend
    implements ClashEvolutionMaterialInventoryStorageBackend {
  ClashEvolutionMaterialInventorySnapshot _snapshot =
      const ClashEvolutionMaterialInventorySnapshot();

  @override
  ClashEvolutionMaterialInventorySnapshot readSnapshot() => _snapshot;

  @override
  Future<void> writeSnapshot(
    ClashEvolutionMaterialInventorySnapshot snapshot,
  ) async {
    _snapshot = snapshot;
  }
}

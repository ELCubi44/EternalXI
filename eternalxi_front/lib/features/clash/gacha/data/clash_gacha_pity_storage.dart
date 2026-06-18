import 'dart:convert';

import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local de pity por banner (Fase 25).
abstract class ClashGachaPityStorageBackend {
  ClashGachaPityState? readState(String bannerId);

  Future<void> writeState(ClashGachaPityState state);

  Future<void> clearAll();
}

class SharedPreferencesClashGachaPityBackend
    implements ClashGachaPityStorageBackend {
  SharedPreferencesClashGachaPityBackend(this._prefs);

  static const storageKey = 'clash_gacha_pity_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashGachaPityBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashGachaPityBackend(prefs);
  }

  Map<String, dynamic> _readMap() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return {};
    }
    return Map<String, dynamic>.from(decoded);
  }

  @override
  ClashGachaPityState? readState(String bannerId) {
    final banners = _readMap()['banners'];
    if (banners is! Map) {
      return null;
    }
    final raw = banners[bannerId];
    if (raw is! Map) {
      return null;
    }
    return ClashGachaPityState.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> writeState(ClashGachaPityState state) async {
    final map = _readMap();
    final banners = Map<String, dynamic>.from(
      map['banners'] as Map? ?? const {},
    );
    banners[state.bannerId] = state.toJson();
    map['banners'] = banners;
    await _prefs.setString(storageKey, jsonEncode(map));
  }

  @override
  Future<void> clearAll() => _prefs.remove(storageKey);
}

class InMemoryClashGachaPityBackend implements ClashGachaPityStorageBackend {
  final Map<String, ClashGachaPityState> _states = {};

  @override
  ClashGachaPityState? readState(String bannerId) => _states[bannerId];

  @override
  Future<void> writeState(ClashGachaPityState state) async {
    _states[state.bannerId] = state;
  }

  @override
  Future<void> clearAll() async {
    _states.clear();
  }
}

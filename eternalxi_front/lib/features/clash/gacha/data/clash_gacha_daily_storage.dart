import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Fechas de uso del single diario por banner (Fase 23).
abstract class ClashGachaDailyStorageBackend {
  String? readLastUsedDate(String bannerId);

  Future<void> writeLastUsedDate(String bannerId, String yyyyMmDd);
}

class SharedPreferencesClashGachaDailyBackend
    implements ClashGachaDailyStorageBackend {
  SharedPreferencesClashGachaDailyBackend(this._prefs);

  static const storageKey = 'clash_gacha_daily_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashGachaDailyBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashGachaDailyBackend(prefs);
  }

  Map<String, String> _readMap() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return {};
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  @override
  String? readLastUsedDate(String bannerId) => _readMap()[bannerId];

  @override
  Future<void> writeLastUsedDate(String bannerId, String yyyyMmDd) async {
    final map = _readMap();
    map[bannerId] = yyyyMmDd;
    await _prefs.setString(storageKey, jsonEncode(map));
  }

  Future<void> clearForTests() => _prefs.remove(storageKey);
}

class InMemoryClashGachaDailyBackend implements ClashGachaDailyStorageBackend {
  final Map<String, String> _dates = {};

  @override
  String? readLastUsedDate(String bannerId) => _dates[bannerId];

  @override
  Future<void> writeLastUsedDate(String bannerId, String yyyyMmDd) async {
    _dates[bannerId] = yyyyMmDd;
  }
}

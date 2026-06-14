import 'dart:convert';

import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend de persistencia intercambiable (producción / tests).
abstract class ClashLineupsStorageBackend {
  List<ClashLineup7v7>? readLineups();

  Future<void> writeLineups(List<ClashLineup7v7> lineups);
}

class SharedPreferencesClashLineupsBackend
    implements ClashLineupsStorageBackend {
  SharedPreferencesClashLineupsBackend(this._prefs);

  static const storageKey = 'clash_lineups_7v7_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashLineupsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashLineupsBackend(prefs);
  }

  @override
  List<ClashLineup7v7>? readLineups() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return ClashLineupsJson.parseLineups(raw);
  }

  @override
  Future<void> writeLineups(List<ClashLineup7v7> lineups) async {
    await _prefs.setString(storageKey, ClashLineupsJson.encodeLineups(lineups));
  }

  Future<void> clearForTests() => _prefs.remove(storageKey);
}

class InMemoryClashLineupsBackend implements ClashLineupsStorageBackend {
  String? _raw;

  @override
  List<ClashLineup7v7>? readLineups() {
    if (_raw == null) {
      return null;
    }
    return ClashLineupsJson.parseLineups(_raw!);
  }

  @override
  Future<void> writeLineups(List<ClashLineup7v7> lineups) async {
    _raw = ClashLineupsJson.encodeLineups(lineups);
  }

  String? get raw => _raw;
}

/// Serialización compartida de alineaciones Clash.
class ClashLineupsJson {
  static List<ClashLineup7v7> parseLineups(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de alineaciones Clash debe ser un objeto');
    }
    final lineupsRaw = decoded['lineups'];
    if (lineupsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: lineups');
    }
    return lineupsRaw
        .map(
          (item) =>
              ClashLineup7v7.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  static String encodeLineups(List<ClashLineup7v7> lineups) {
    return jsonEncode({
      'lineups': lineups.map((lineup) => lineup.toJson()).toList(),
    });
  }
}

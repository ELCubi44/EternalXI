import 'dart:convert';

import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local del historial de invocaciones (Fase 24).
abstract class ClashGachaHistoryStorageBackend {
  List<ClashGachaHistoryEntry> readEntries();

  Future<void> writeEntries(List<ClashGachaHistoryEntry> entries);

  Future<void> appendEntry(ClashGachaHistoryEntry entry);

  Future<void> clearHistory();
}

class SharedPreferencesClashGachaHistoryBackend
    implements ClashGachaHistoryStorageBackend {
  SharedPreferencesClashGachaHistoryBackend(this._prefs);

  static const storageKey = 'clash_gacha_history_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashGachaHistoryBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashGachaHistoryBackend(prefs);
  }

  @override
  List<ClashGachaHistoryEntry> readEntries() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return [];
    }
    final entriesRaw = decoded['entries'];
    if (entriesRaw is! List) {
      return [];
    }
    return entriesRaw
        .map(
          (item) => ClashGachaHistoryEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: true);
  }

  @override
  Future<void> writeEntries(List<ClashGachaHistoryEntry> entries) async {
    final sorted = List<ClashGachaHistoryEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trimmed = sorted
        .take(ClashGachaHistoryEntry.maxStoredEntries)
        .toList();
    await _prefs.setString(
      storageKey,
      jsonEncode({'entries': trimmed.map((entry) => entry.toJson()).toList()}),
    );
  }

  @override
  Future<void> appendEntry(ClashGachaHistoryEntry entry) async {
    final entries = readEntries();
    entries.insert(0, entry);
    await writeEntries(entries);
  }

  @override
  Future<void> clearHistory() => _prefs.remove(storageKey);
}

class InMemoryClashGachaHistoryBackend
    implements ClashGachaHistoryStorageBackend {
  List<ClashGachaHistoryEntry> _entries = [];

  @override
  List<ClashGachaHistoryEntry> readEntries() =>
      List<ClashGachaHistoryEntry>.from(_entries);

  @override
  Future<void> writeEntries(List<ClashGachaHistoryEntry> entries) async {
    final sorted = List<ClashGachaHistoryEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _entries = sorted
        .take(ClashGachaHistoryEntry.maxStoredEntries)
        .toList(growable: false);
  }

  @override
  Future<void> appendEntry(ClashGachaHistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > ClashGachaHistoryEntry.maxStoredEntries) {
      _entries = _entries
          .take(ClashGachaHistoryEntry.maxStoredEntries)
          .toList(growable: false);
    }
  }

  @override
  Future<void> clearHistory() async {
    _entries = [];
  }
}

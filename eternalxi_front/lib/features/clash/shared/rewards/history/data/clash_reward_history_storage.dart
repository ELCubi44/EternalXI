import 'dart:convert';

import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local del historial de recompensas Clash (Fase 60).
abstract class ClashRewardHistoryStorageBackend {
  List<ClashRewardHistoryEntry> readEntries();

  Future<void> writeEntries(List<ClashRewardHistoryEntry> entries);

  Future<void> appendEntry(ClashRewardHistoryEntry entry);
}

class SharedPreferencesClashRewardHistoryBackend
    implements ClashRewardHistoryStorageBackend {
  SharedPreferencesClashRewardHistoryBackend(this._prefs);

  static const storageKey = ClashSharedPreferencesKeys.rewardHistory;

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashRewardHistoryBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashRewardHistoryBackend(prefs);
  }

  @override
  List<ClashRewardHistoryEntry> readEntries() {
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
          (item) => ClashRewardHistoryEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: true);
  }

  @override
  Future<void> writeEntries(List<ClashRewardHistoryEntry> entries) async {
    final sorted = List<ClashRewardHistoryEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trimmed = sorted
        .take(ClashRewardHistoryEntry.maxStoredEntries)
        .toList(growable: false);
    await _prefs.setString(
      storageKey,
      jsonEncode({'entries': trimmed.map((entry) => entry.toJson()).toList()}),
    );
  }

  @override
  Future<void> appendEntry(ClashRewardHistoryEntry entry) async {
    final entries = readEntries();
    entries.insert(0, entry);
    await writeEntries(entries);
  }
}

class InMemoryClashRewardHistoryBackend
    implements ClashRewardHistoryStorageBackend {
  List<ClashRewardHistoryEntry> _entries = [];

  @override
  List<ClashRewardHistoryEntry> readEntries() =>
      List<ClashRewardHistoryEntry>.from(_entries);

  @override
  Future<void> writeEntries(List<ClashRewardHistoryEntry> entries) async {
    final sorted = List<ClashRewardHistoryEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _entries = sorted
        .take(ClashRewardHistoryEntry.maxStoredEntries)
        .toList(growable: false);
  }

  @override
  Future<void> appendEntry(ClashRewardHistoryEntry entry) async {
    final entries = List<ClashRewardHistoryEntry>.from(_entries);
    entries.insert(0, entry);
    _entries = entries
        .take(ClashRewardHistoryEntry.maxStoredEntries)
        .toList(growable: true);
  }
}

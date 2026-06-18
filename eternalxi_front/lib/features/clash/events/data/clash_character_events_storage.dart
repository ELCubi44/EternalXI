import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClashCharacterEventsProgressState {
  const ClashCharacterEventsProgressState({
    this.completedStageIds = const {},
    this.claimedFirstClearRewardKeys = const {},
    this.clearCounts = const {},
    this.lastPlayedAt,
  });

  final Set<String> completedStageIds;
  final Set<String> claimedFirstClearRewardKeys;
  final Map<String, int> clearCounts;
  final String? lastPlayedAt;

  ClashCharacterEventsProgressState copyWith({
    Set<String>? completedStageIds,
    Set<String>? claimedFirstClearRewardKeys,
    Map<String, int>? clearCounts,
    String? lastPlayedAt,
  }) {
    return ClashCharacterEventsProgressState(
      completedStageIds: completedStageIds ?? this.completedStageIds,
      claimedFirstClearRewardKeys:
          claimedFirstClearRewardKeys ?? this.claimedFirstClearRewardKeys,
      clearCounts: clearCounts ?? this.clearCounts,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'completedStageIds': completedStageIds.toList(growable: false),
    'claimedFirstClearRewardKeys': claimedFirstClearRewardKeys.toList(
      growable: false,
    ),
    'clearCounts': clearCounts,
    if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt,
  };

  factory ClashCharacterEventsProgressState.fromJson(
    Map<String, dynamic> json,
  ) {
    final completedRaw = json['completedStageIds'];
    final claimedRaw = json['claimedFirstClearRewardKeys'];
    final countsRaw = json['clearCounts'];
    final completed = <String>{};
    final claimed = <String>{};
    final counts = <String, int>{};
    if (completedRaw is List) {
      for (final item in completedRaw) {
        completed.add(item.toString());
      }
    }
    if (claimedRaw is List) {
      for (final item in claimedRaw) {
        claimed.add(item.toString());
      }
    }
    if (countsRaw is Map) {
      for (final entry in countsRaw.entries) {
        final value = entry.value;
        if (value is int) {
          counts[entry.key.toString()] = value;
        } else if (value is num) {
          counts[entry.key.toString()] = value.toInt();
        }
      }
    }
    return ClashCharacterEventsProgressState(
      completedStageIds: completed,
      claimedFirstClearRewardKeys: claimed,
      clearCounts: counts,
      lastPlayedAt: json['lastPlayedAt']?.toString(),
    );
  }
}

abstract class ClashCharacterEventsStorageBackend {
  ClashCharacterEventsProgressState? readState();

  Future<void> writeState(ClashCharacterEventsProgressState state);

  Future<void> clear();
}

class SharedPreferencesClashCharacterEventsBackend
    implements ClashCharacterEventsStorageBackend {
  SharedPreferencesClashCharacterEventsBackend(this._prefs);

  static const storageKey = 'clash_character_events_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashCharacterEventsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashCharacterEventsBackend(prefs);
  }

  @override
  ClashCharacterEventsProgressState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashCharacterEventsProgressState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> writeState(ClashCharacterEventsProgressState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashCharacterEventsBackend
    implements ClashCharacterEventsStorageBackend {
  ClashCharacterEventsProgressState? _state;

  @override
  ClashCharacterEventsProgressState? readState() => _state;

  @override
  Future<void> writeState(ClashCharacterEventsProgressState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido de misiones semanales.
class ClashWeeklyMissionsWeekState {
  const ClashWeeklyMissionsWeekState({
    required this.weekKey,
    this.progress = const {},
    this.claimedMissionIds = const {},
  });

  final String weekKey;
  final Map<String, int> progress;
  final Set<String> claimedMissionIds;

  ClashWeeklyMissionsWeekState copyWith({
    String? weekKey,
    Map<String, int>? progress,
    Set<String>? claimedMissionIds,
  }) {
    return ClashWeeklyMissionsWeekState(
      weekKey: weekKey ?? this.weekKey,
      progress: progress ?? this.progress,
      claimedMissionIds: claimedMissionIds ?? this.claimedMissionIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekKey': weekKey,
    'progress': progress,
    'claimedMissionIds': claimedMissionIds.toList(growable: false),
  };

  factory ClashWeeklyMissionsWeekState.fromJson(Map<String, dynamic> json) {
    final progressRaw = json['progress'];
    final claimedRaw = json['claimedMissionIds'];
    final progress = <String, int>{};
    if (progressRaw is Map) {
      for (final entry in progressRaw.entries) {
        final value = entry.value;
        if (value is int) {
          progress[entry.key.toString()] = value;
        } else if (value is num) {
          progress[entry.key.toString()] = value.toInt();
        }
      }
    }
    final claimed = <String>{};
    if (claimedRaw is List) {
      for (final item in claimedRaw) {
        claimed.add(item.toString());
      }
    }
    return ClashWeeklyMissionsWeekState(
      weekKey: json['weekKey']?.toString() ?? '',
      progress: progress,
      claimedMissionIds: claimed,
    );
  }
}

abstract class ClashWeeklyMissionsStorageBackend {
  ClashWeeklyMissionsWeekState? readState();

  Future<void> writeState(ClashWeeklyMissionsWeekState state);

  Future<void> clear();
}

class SharedPreferencesClashWeeklyMissionsBackend
    implements ClashWeeklyMissionsStorageBackend {
  SharedPreferencesClashWeeklyMissionsBackend(this._prefs);

  static const storageKey = 'clash_weekly_missions_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashWeeklyMissionsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashWeeklyMissionsBackend(prefs);
  }

  @override
  ClashWeeklyMissionsWeekState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashWeeklyMissionsWeekState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> writeState(ClashWeeklyMissionsWeekState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashWeeklyMissionsBackend
    implements ClashWeeklyMissionsStorageBackend {
  ClashWeeklyMissionsWeekState? _state;

  @override
  ClashWeeklyMissionsWeekState? readState() => _state;

  @override
  Future<void> writeState(ClashWeeklyMissionsWeekState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

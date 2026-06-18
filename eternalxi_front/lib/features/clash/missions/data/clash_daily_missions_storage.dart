import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido de misiones diarias para un día local.
class ClashDailyMissionsDayState {
  const ClashDailyMissionsDayState({
    required this.localDate,
    this.progress = const {},
    this.claimedMissionIds = const {},
  });

  final String localDate;
  final Map<String, int> progress;
  final Set<String> claimedMissionIds;

  ClashDailyMissionsDayState copyWith({
    String? localDate,
    Map<String, int>? progress,
    Set<String>? claimedMissionIds,
  }) {
    return ClashDailyMissionsDayState(
      localDate: localDate ?? this.localDate,
      progress: progress ?? this.progress,
      claimedMissionIds: claimedMissionIds ?? this.claimedMissionIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'localDate': localDate,
    'progress': progress,
    'claimedMissionIds': claimedMissionIds.toList(growable: false),
  };

  factory ClashDailyMissionsDayState.fromJson(Map<String, dynamic> json) {
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
    return ClashDailyMissionsDayState(
      localDate: json['localDate']?.toString() ?? '',
      progress: progress,
      claimedMissionIds: claimed,
    );
  }
}

abstract class ClashDailyMissionsStorageBackend {
  ClashDailyMissionsDayState? readState();

  Future<void> writeState(ClashDailyMissionsDayState state);

  Future<void> clear();
}

class SharedPreferencesClashDailyMissionsBackend
    implements ClashDailyMissionsStorageBackend {
  SharedPreferencesClashDailyMissionsBackend(this._prefs);

  static const storageKey = 'clash_daily_missions_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashDailyMissionsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashDailyMissionsBackend(prefs);
  }

  @override
  ClashDailyMissionsDayState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashDailyMissionsDayState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> writeState(ClashDailyMissionsDayState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashDailyMissionsBackend
    implements ClashDailyMissionsStorageBackend {
  ClashDailyMissionsDayState? _state;

  @override
  ClashDailyMissionsDayState? readState() => _state;

  @override
  Future<void> writeState(ClashDailyMissionsDayState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

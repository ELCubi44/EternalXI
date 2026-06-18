import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido de logros Clash (permanente, sin reset diario).
class ClashAchievementsState {
  const ClashAchievementsState({
    this.progress = const {},
    this.claimedAchievementIds = const {},
    this.updatedAt,
  });

  final Map<String, int> progress;
  final Set<String> claimedAchievementIds;
  final String? updatedAt;

  ClashAchievementsState copyWith({
    Map<String, int>? progress,
    Set<String>? claimedAchievementIds,
    String? updatedAt,
  }) {
    return ClashAchievementsState(
      progress: progress ?? this.progress,
      claimedAchievementIds:
          claimedAchievementIds ?? this.claimedAchievementIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'claimedAchievementIds': claimedAchievementIds.toList(growable: false),
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  factory ClashAchievementsState.fromJson(Map<String, dynamic> json) {
    final progressRaw = json['progress'];
    final claimedRaw = json['claimedAchievementIds'];
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
    return ClashAchievementsState(
      progress: progress,
      claimedAchievementIds: claimed,
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

abstract class ClashAchievementsStorageBackend {
  ClashAchievementsState? readState();

  Future<void> writeState(ClashAchievementsState state);

  Future<void> clear();
}

class SharedPreferencesClashAchievementsBackend
    implements ClashAchievementsStorageBackend {
  SharedPreferencesClashAchievementsBackend(this._prefs);

  static const storageKey = 'clash_achievements_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashAchievementsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashAchievementsBackend(prefs);
  }

  @override
  ClashAchievementsState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashAchievementsState.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> writeState(ClashAchievementsState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashAchievementsBackend
    implements ClashAchievementsStorageBackend {
  ClashAchievementsState? _state;

  @override
  ClashAchievementsState? readState() => _state;

  @override
  Future<void> writeState(ClashAchievementsState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

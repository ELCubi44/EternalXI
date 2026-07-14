import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClashTrialsProgressState {
  const ClashTrialsProgressState({
    this.completedFloorIds = const {},
    this.clearCounts = const {},
    this.dailyAttemptsUsed = 0,
    this.dailyAttemptsDateKey = '',
    this.totalTechniqueUses = 0,
    this.lastPlayedAt,
  });

  static const dailyAttemptLimit = 12;

  final Set<String> completedFloorIds;
  final Map<String, int> clearCounts;
  final int dailyAttemptsUsed;
  final String dailyAttemptsDateKey;
  final int totalTechniqueUses;
  final String? lastPlayedAt;

  ClashTrialsProgressState copyWith({
    Set<String>? completedFloorIds,
    Map<String, int>? clearCounts,
    int? dailyAttemptsUsed,
    String? dailyAttemptsDateKey,
    int? totalTechniqueUses,
    String? lastPlayedAt,
  }) {
    return ClashTrialsProgressState(
      completedFloorIds: completedFloorIds ?? this.completedFloorIds,
      clearCounts: clearCounts ?? this.clearCounts,
      dailyAttemptsUsed: dailyAttemptsUsed ?? this.dailyAttemptsUsed,
      dailyAttemptsDateKey: dailyAttemptsDateKey ?? this.dailyAttemptsDateKey,
      totalTechniqueUses: totalTechniqueUses ?? this.totalTechniqueUses,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'completedFloorIds': completedFloorIds.toList(growable: false),
    'clearCounts': clearCounts,
    'dailyAttemptsUsed': dailyAttemptsUsed,
    'dailyAttemptsDateKey': dailyAttemptsDateKey,
    'totalTechniqueUses': totalTechniqueUses,
    if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt,
  };

  factory ClashTrialsProgressState.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completedFloorIds'];
    final countsRaw = json['clearCounts'];
    final completed = <String>{};
    final counts = <String, int>{};
    if (completedRaw is List) {
      for (final item in completedRaw) {
        completed.add(item.toString());
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
    return ClashTrialsProgressState(
      completedFloorIds: completed,
      clearCounts: counts,
      dailyAttemptsUsed: json['dailyAttemptsUsed'] is int
          ? json['dailyAttemptsUsed'] as int
          : int.tryParse(json['dailyAttemptsUsed']?.toString() ?? '') ?? 0,
      dailyAttemptsDateKey: json['dailyAttemptsDateKey']?.toString() ?? '',
      totalTechniqueUses: json['totalTechniqueUses'] is int
          ? json['totalTechniqueUses'] as int
          : int.tryParse(json['totalTechniqueUses']?.toString() ?? '') ?? 0,
      lastPlayedAt: json['lastPlayedAt']?.toString(),
    );
  }
}

abstract class ClashTrialsStorageBackend {
  ClashTrialsProgressState? readState();

  Future<void> writeState(ClashTrialsProgressState state);

  Future<void> clear();
}

class SharedPreferencesClashTrialsBackend implements ClashTrialsStorageBackend {
  SharedPreferencesClashTrialsBackend(this._prefs);

  static const storageKey = 'clash_trials_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashTrialsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashTrialsBackend(prefs);
  }

  @override
  ClashTrialsProgressState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashTrialsProgressState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> writeState(ClashTrialsProgressState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashTrialsBackend implements ClashTrialsStorageBackend {
  ClashTrialsProgressState? _state;

  @override
  ClashTrialsProgressState? readState() => _state;

  @override
  Future<void> writeState(ClashTrialsProgressState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

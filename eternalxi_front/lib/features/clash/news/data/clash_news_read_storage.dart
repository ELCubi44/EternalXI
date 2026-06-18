import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido de noticias leídas Clash (Fase 31).
class ClashNewsReadState {
  const ClashNewsReadState({this.readNewsIds = const {}, this.lastOpenedAt});

  final Set<String> readNewsIds;
  final String? lastOpenedAt;

  ClashNewsReadState copyWith({
    Set<String>? readNewsIds,
    String? lastOpenedAt,
  }) {
    return ClashNewsReadState(
      readNewsIds: readNewsIds ?? this.readNewsIds,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'readNewsIds': readNewsIds.toList(growable: false),
    if (lastOpenedAt != null) 'lastOpenedAt': lastOpenedAt,
  };

  factory ClashNewsReadState.fromJson(Map<String, dynamic> json) {
    final readRaw = json['readNewsIds'];
    final readIds = <String>{};
    if (readRaw is List) {
      for (final item in readRaw) {
        readIds.add(item.toString());
      }
    }
    return ClashNewsReadState(
      readNewsIds: readIds,
      lastOpenedAt: json['lastOpenedAt']?.toString(),
    );
  }
}

abstract class ClashNewsReadStorageBackend {
  ClashNewsReadState? readState();

  Future<void> writeState(ClashNewsReadState state);

  Future<void> clear();
}

class SharedPreferencesClashNewsReadBackend
    implements ClashNewsReadStorageBackend {
  SharedPreferencesClashNewsReadBackend(this._prefs);

  static const storageKey = 'clash_news_read_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashNewsReadBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashNewsReadBackend(prefs);
  }

  @override
  ClashNewsReadState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashNewsReadState.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> writeState(ClashNewsReadState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashNewsReadBackend implements ClashNewsReadStorageBackend {
  ClashNewsReadState? _state;

  @override
  ClashNewsReadState? readState() => _state;

  @override
  Future<void> writeState(ClashNewsReadState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

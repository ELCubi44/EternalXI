import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido del buzón de regalos Clash (Fase 32).
class ClashGiftsState {
  const ClashGiftsState({this.claimedGiftIds = const {}, this.lastOpenedAt});

  final Set<String> claimedGiftIds;
  final String? lastOpenedAt;

  ClashGiftsState copyWith({
    Set<String>? claimedGiftIds,
    String? lastOpenedAt,
  }) {
    return ClashGiftsState(
      claimedGiftIds: claimedGiftIds ?? this.claimedGiftIds,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'claimedGiftIds': claimedGiftIds.toList(growable: false),
    if (lastOpenedAt != null) 'lastOpenedAt': lastOpenedAt,
  };

  factory ClashGiftsState.fromJson(Map<String, dynamic> json) {
    final claimedRaw = json['claimedGiftIds'];
    final claimed = <String>{};
    if (claimedRaw is List) {
      for (final item in claimedRaw) {
        claimed.add(item.toString());
      }
    }
    return ClashGiftsState(
      claimedGiftIds: claimed,
      lastOpenedAt: json['lastOpenedAt']?.toString(),
    );
  }
}

abstract class ClashGiftsStorageBackend {
  ClashGiftsState? readState();

  Future<void> writeState(ClashGiftsState state);

  Future<void> clear();
}

class SharedPreferencesClashGiftsBackend implements ClashGiftsStorageBackend {
  SharedPreferencesClashGiftsBackend(this._prefs);

  static const storageKey = 'clash_gifts_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashGiftsBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashGiftsBackend(prefs);
  }

  @override
  ClashGiftsState? readState() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return ClashGiftsState.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> writeState(ClashGiftsState state) async {
    await _prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}

class InMemoryClashGiftsBackend implements ClashGiftsStorageBackend {
  ClashGiftsState? _state;

  @override
  ClashGiftsState? readState() => _state;

  @override
  Future<void> writeState(ClashGiftsState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = null;
  }
}

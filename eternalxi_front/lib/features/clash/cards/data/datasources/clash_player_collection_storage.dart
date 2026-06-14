import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Backend intercambiable para la colección de cartas del jugador.
abstract class ClashPlayerCollectionStorageBackend {
  Set<String> readOwnedCardIds();

  Future<void> writeOwnedCardIds(Set<String> cardIds);
}

class SharedPreferencesClashPlayerCollectionBackend
    implements ClashPlayerCollectionStorageBackend {
  SharedPreferencesClashPlayerCollectionBackend(this._prefs);

  static const storageKey = 'clash_player_collection_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashPlayerCollectionBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashPlayerCollectionBackend(prefs);
  }

  @override
  Set<String> readOwnedCardIds() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return {};
    }
    return decoded.map((id) => id.toString()).toSet();
  }

  @override
  Future<void> writeOwnedCardIds(Set<String> cardIds) async {
    await _prefs.setString(storageKey, jsonEncode(cardIds.toList()));
  }

  Future<void> clearForTests() => _prefs.remove(storageKey);
}

class InMemoryClashPlayerCollectionBackend
    implements ClashPlayerCollectionStorageBackend {
  Set<String> _owned = {};

  @override
  Set<String> readOwnedCardIds() => Set<String>.from(_owned);

  @override
  Future<void> writeOwnedCardIds(Set<String> cardIds) async {
    _owned = Set<String>.from(cardIds);
  }
}

import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot persistido de la colección Clash (poseídas + progreso).
class ClashPlayerCollectionSnapshot {
  const ClashPlayerCollectionSnapshot({
    this.ownedCardIds = const {},
    this.cardProgress = const {},
  });

  final Set<String> ownedCardIds;
  final Map<String, ClashCardProgress> cardProgress;

  ClashPlayerCollectionSnapshot copyWith({
    Set<String>? ownedCardIds,
    Map<String, ClashCardProgress>? cardProgress,
  }) {
    return ClashPlayerCollectionSnapshot(
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      cardProgress: cardProgress ?? this.cardProgress,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownedCardIds': ownedCardIds.toList(),
    'cardProgress': cardProgress.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };

  factory ClashPlayerCollectionSnapshot.fromJson(Map<String, dynamic> json) {
    final ownedRaw = json['ownedCardIds'] as List? ?? const [];
    final progressRaw = json['cardProgress'] as Map? ?? const {};
    final progress = <String, ClashCardProgress>{};
    for (final entry in progressRaw.entries) {
      progress[entry.key.toString()] = ClashCardProgress.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return ClashPlayerCollectionSnapshot(
      ownedCardIds: ownedRaw.map((id) => id.toString()).toSet(),
      cardProgress: progress,
    );
  }
}

/// Backend intercambiable para la colección de cartas del jugador.
abstract class ClashPlayerCollectionStorageBackend {
  ClashPlayerCollectionSnapshot readSnapshot();

  Future<void> writeSnapshot(ClashPlayerCollectionSnapshot snapshot);
}

class SharedPreferencesClashPlayerCollectionBackend
    implements ClashPlayerCollectionStorageBackend {
  SharedPreferencesClashPlayerCollectionBackend(this._prefs);

  static const storageKeyV1 = ClashSharedPreferencesKeys.playerCollectionV1;
  static const storageKeyV2 = ClashSharedPreferencesKeys.playerCollectionV2;

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashPlayerCollectionBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashPlayerCollectionBackend(prefs);
  }

  @override
  ClashPlayerCollectionSnapshot readSnapshot() {
    final rawV2 = _prefs.getString(storageKeyV2);
    if (rawV2 != null && rawV2.isNotEmpty) {
      final decoded = jsonDecode(rawV2);
      if (decoded is Map<String, dynamic>) {
        return ClashPlayerCollectionSnapshot.fromJson(decoded);
      }
    }

    final rawV1 = _prefs.getString(storageKeyV1);
    if (rawV1 == null || rawV1.isEmpty) {
      return const ClashPlayerCollectionSnapshot();
    }
    final decoded = jsonDecode(rawV1);
    if (decoded is! List) {
      return const ClashPlayerCollectionSnapshot();
    }
    return ClashPlayerCollectionSnapshot(
      ownedCardIds: decoded.map((id) => id.toString()).toSet(),
    );
  }

  @override
  Future<void> writeSnapshot(ClashPlayerCollectionSnapshot snapshot) async {
    await _prefs.setString(storageKeyV2, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearForTests() async {
    await _prefs.remove(storageKeyV1);
    await _prefs.remove(storageKeyV2);
  }
}

class InMemoryClashPlayerCollectionBackend
    implements ClashPlayerCollectionStorageBackend {
  ClashPlayerCollectionSnapshot _snapshot =
      const ClashPlayerCollectionSnapshot();

  @override
  ClashPlayerCollectionSnapshot readSnapshot() => _snapshot;

  @override
  Future<void> writeSnapshot(ClashPlayerCollectionSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

import 'dart:convert';

import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ClashStoryProgressStorageBackend {
  ClashStoryProgress readProgress();

  Future<void> writeProgress(ClashStoryProgress progress);
}

class SharedPreferencesClashStoryProgressBackend
    implements ClashStoryProgressStorageBackend {
  SharedPreferencesClashStoryProgressBackend(this._prefs);

  static const storageKey = 'clash_story_progress_v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesClashStoryProgressBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClashStoryProgressBackend(prefs);
  }

  @override
  ClashStoryProgress readProgress() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const ClashStoryProgress();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const ClashStoryProgress();
    }
    return ClashStoryProgress.fromJson(decoded);
  }

  @override
  Future<void> writeProgress(ClashStoryProgress progress) async {
    await _prefs.setString(storageKey, jsonEncode(progress.toJson()));
  }

  Future<void> clearForTests() => _prefs.remove(storageKey);
}

class InMemoryClashStoryProgressBackend
    implements ClashStoryProgressStorageBackend {
  ClashStoryProgress _progress = const ClashStoryProgress();

  @override
  ClashStoryProgress readProgress() => _progress;

  @override
  Future<void> writeProgress(ClashStoryProgress progress) async {
    _progress = progress;
  }
}

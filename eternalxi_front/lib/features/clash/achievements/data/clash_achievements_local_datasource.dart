import 'dart:convert';

import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:flutter/services.dart';

class ClashAchievementsLocalDataSource {
  ClashAchievementsLocalDataSource({
    this.assetPath = 'assets/data/clash/achievements.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashAchievement>? _cache;

  Future<List<ClashAchievement>> loadAchievements() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashAchievement>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseAchievementsJson(raw);
  }

  List<ClashAchievement> parseAchievementsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de logros Clash debe ser un objeto');
    }
    final achievementsRaw = decoded['achievements'];
    if (achievementsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: achievements');
    }
    return achievementsRaw
        .map(
          (item) =>
              ClashAchievement.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

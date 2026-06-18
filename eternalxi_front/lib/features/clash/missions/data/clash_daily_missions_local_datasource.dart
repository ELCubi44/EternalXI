import 'dart:convert';

import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:flutter/services.dart';

class ClashDailyMissionsLocalDataSource {
  ClashDailyMissionsLocalDataSource({
    this.assetPath = 'assets/data/clash/daily_missions.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashDailyMission>? _cache;

  Future<List<ClashDailyMission>> loadMissions() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashDailyMission>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseMissionsJson(raw);
  }

  List<ClashDailyMission> parseMissionsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de misiones diarias debe ser un objeto');
    }
    final missionsRaw = decoded['missions'];
    if (missionsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: missions');
    }
    return missionsRaw
        .map(
          (item) => ClashDailyMission.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

import 'dart:convert';

import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:flutter/services.dart';

class ClashWeeklyMissionsLocalDataSource {
  ClashWeeklyMissionsLocalDataSource({
    this.assetPath = 'assets/data/clash/weekly_missions.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashWeeklyMission>? _cache;

  Future<List<ClashWeeklyMission>> loadMissions() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashWeeklyMission>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseMissionsJson(raw);
  }

  List<ClashWeeklyMission> parseMissionsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'JSON de misiones semanales Clash debe ser un objeto',
      );
    }
    final missionsRaw = decoded['missions'];
    if (missionsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: missions');
    }
    return missionsRaw
        .map(
          (item) => ClashWeeklyMission.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

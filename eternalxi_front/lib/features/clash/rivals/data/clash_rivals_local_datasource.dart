import 'dart:convert';

import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';
import 'package:flutter/services.dart';

class ClashRivalsLocalDataSource {
  ClashRivalsLocalDataSource({
    this.assetPath = 'assets/data/clash/rivals.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashRivalTeam>? _cache;

  Future<List<ClashRivalTeam>> loadRivals() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashRivalTeam>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseRivalsJson(raw);
  }

  List<ClashRivalTeam> parseRivalsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de rivales Clash debe ser un objeto');
    }
    final rivalsRaw = decoded['rivals'];
    if (rivalsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: rivals');
    }
    return rivalsRaw
        .map(
          (item) =>
              ClashRivalTeam.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

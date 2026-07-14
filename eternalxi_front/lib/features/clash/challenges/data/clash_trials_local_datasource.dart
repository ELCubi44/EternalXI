import 'dart:convert';

import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:flutter/services.dart';

class ClashTrialsLocalDataSource {
  ClashTrialsLocalDataSource({
    this.assetPath = 'assets/data/clash/trials.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashTrial>? _cache;

  Future<List<ClashTrial>> loadTrials() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashTrial>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseTrialsJson(raw);
  }

  List<ClashTrial> parseTrialsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de desaf�os Clash debe ser un objeto');
    }
    final trialsRaw = decoded['trials'];
    if (trialsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: trials');
    }
    final trials = trialsRaw
        .map(
          (item) => ClashTrial.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    trials.sort((a, b) => a.order.compareTo(b.order));
    return trials;
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

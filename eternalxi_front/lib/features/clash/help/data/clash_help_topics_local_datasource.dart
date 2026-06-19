import 'dart:convert';

import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:flutter/services.dart';

class ClashHelpTopicsLocalDataSource {
  ClashHelpTopicsLocalDataSource({
    this.assetPath = 'assets/data/clash/help_topics.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashHelpTopic>? _cache;

  Future<List<ClashHelpTopic>> loadTopics() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashHelpTopic>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseTopicsJson(raw);
  }

  List<ClashHelpTopic> parseTopicsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de ayuda Clash debe ser un objeto');
    }
    final topicsRaw = decoded['topics'];
    if (topicsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: topics');
    }
    return topicsRaw
        .map(
          (item) =>
              ClashHelpTopic.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() => _cache = null;
}

import 'dart:convert';

import 'package:eternal_xi/features/clash/news/domain/clash_news_item.dart';
import 'package:flutter/services.dart';

class ClashNewsLocalDataSource {
  ClashNewsLocalDataSource({
    this.assetPath = 'assets/data/clash/news.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashNewsItem>? _cache;

  Future<List<ClashNewsItem>> loadNews() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashNewsItem>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseNewsJson(raw);
  }

  List<ClashNewsItem> parseNewsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de noticias Clash debe ser un objeto');
    }
    final newsRaw = decoded['news'];
    if (newsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: news');
    }
    return newsRaw
        .map(
          (item) =>
              ClashNewsItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

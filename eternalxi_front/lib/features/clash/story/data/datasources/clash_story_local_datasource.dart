import 'dart:convert';

import 'package:eternal_xi/features/clash/story/domain/clash_story_chapter.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_saga.dart';
import 'package:flutter/services.dart';

/// Carga sagas y capítulos de historia Clash desde assets locales.
class ClashStoryLocalDataSource {
  ClashStoryLocalDataSource({
    this.sagasAssetPath = 'assets/data/clash/story/sagas.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String sagasAssetPath;
  final AssetBundle _bundle;

  final Map<String, String> _chapterAssetPaths = const {
    'chapter-01': 'assets/data/clash/story/chapter_01.json',
  };

  Future<List<ClashStorySaga>> loadSagas() async {
    final raw = await _bundle.loadString(sagasAssetPath);
    return parseSagasJson(raw);
  }

  Future<ClashStoryChapter> loadChapter(String chapterId) async {
    final assetPath = _chapterAssetPaths[chapterId];
    if (assetPath == null) {
      throw FormatException('Capítulo desconocido: $chapterId');
    }
    final raw = await _bundle.loadString(assetPath);
    return parseChapterJson(raw);
  }

  List<ClashStorySaga> parseSagasJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de sagas Clash debe ser un objeto');
    }
    final sagasRaw = decoded['sagas'];
    if (sagasRaw is! List) {
      throw FormatException('Campo obligatorio ausente: sagas');
    }
    return sagasRaw
        .map(
          (item) =>
              ClashStorySaga.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  ClashStoryChapter parseChapterJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de capítulo Clash debe ser un objeto');
    }
    final chapterRaw = decoded['chapter'];
    if (chapterRaw is! Map<String, dynamic>) {
      throw FormatException('Campo obligatorio ausente: chapter');
    }
    return ClashStoryChapter.fromJson(chapterRaw);
  }
}

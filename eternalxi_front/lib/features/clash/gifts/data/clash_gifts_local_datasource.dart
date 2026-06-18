import 'dart:convert';

import 'package:eternal_xi/features/clash/gifts/domain/clash_gift.dart';
import 'package:flutter/services.dart';

class ClashGiftsLocalDataSource {
  ClashGiftsLocalDataSource({
    this.assetPath = 'assets/data/clash/gifts.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashGift>? _cache;

  Future<List<ClashGift>> loadGifts() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashGift>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseGiftsJson(raw);
  }

  List<ClashGift> parseGiftsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de regalos Clash debe ser un objeto');
    }
    final giftsRaw = decoded['gifts'];
    if (giftsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: gifts');
    }
    return giftsRaw
        .map(
          (item) => ClashGift.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}

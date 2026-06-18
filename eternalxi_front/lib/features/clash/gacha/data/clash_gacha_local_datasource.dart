import 'dart:convert';

import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_banner.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:flutter/services.dart';

class ClashGachaCatalog {
  const ClashGachaCatalog({required this.banners, required this.rates});

  final List<ClashGachaBanner> banners;
  final ClashGachaRarityRates rates;
}

class ClashGachaLocalDataSource {
  ClashGachaLocalDataSource({
    this.assetPath = 'assets/data/clash/gacha_banners.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<ClashGachaCatalog> loadCatalog() async {
    final raw = await _bundle.loadString(assetPath);
    return parseCatalogJson(raw);
  }

  ClashGachaCatalog parseCatalogJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de gacha Clash debe ser un objeto');
    }
    final ratesRaw = decoded['rates'] as Map<String, dynamic>? ?? const {};
    final bannersRaw = decoded['banners'];
    if (bannersRaw is! List) {
      throw FormatException('Campo obligatorio ausente: banners');
    }
    return ClashGachaCatalog(
      rates: ClashGachaRarityRates.fromJson(ratesRaw),
      banners: bannersRaw
          .map(
            (item) => ClashGachaBanner.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

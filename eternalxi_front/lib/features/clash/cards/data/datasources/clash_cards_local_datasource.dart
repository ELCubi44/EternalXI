import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/content/clash_content_download_service.dart';
import 'package:flutter/services.dart';

/// Carga cartas Clash desde cache descargado o fallback empaquetado.
class ClashCardsLocalDataSource {
  ClashCardsLocalDataSource({
    this.assetPath = 'assets/data/clash/cards.json',
    AssetBundle? bundle,
    ClashContentDownloadService? downloadService,
  })  : _bundle = bundle ?? rootBundle,
        _downloadService = downloadService ?? ClashContentDownloadService();

  final String assetPath;
  final AssetBundle _bundle;
  final ClashContentDownloadService _downloadService;

  Future<List<ClashCardCatalogEntry>> loadCards() async {
    final raw = await _loadRawJson();
    return parseCardsJson(raw);
  }

  Future<String> _loadRawJson() async {
    final cached = await _downloadService.loadLocalCardsJson();
    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }
    return _bundle.loadString(assetPath);
  }

  /// Parseo tolerante para tests y reutilizacion sin I/O.
  List<ClashCardCatalogEntry> parseCardsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de cartas Clash debe ser un objeto');
    }

    final cardsRaw = decoded['cards'];
    if (cardsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: cards');
    }

    return cardsRaw
        .map(
          (item) => ClashCardCatalogEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }
}

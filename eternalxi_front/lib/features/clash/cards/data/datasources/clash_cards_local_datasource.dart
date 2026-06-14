import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:flutter/services.dart';

/// Carga cartas Clash desde un JSON empaquetado en assets.
class ClashCardsLocalDataSource {
  ClashCardsLocalDataSource({
    this.assetPath = 'assets/data/clash/cards.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashCardCatalogEntry>> loadCards() async {
    final raw = await _bundle.loadString(assetPath);
    return parseCardsJson(raw);
  }

  /// Parseo tolerante para tests y reutilización sin I/O.
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

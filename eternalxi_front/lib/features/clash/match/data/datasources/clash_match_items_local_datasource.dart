import 'dart:convert';

import 'package:eternal_xi/features/clash/match/domain/clash_match_item.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';
import 'package:flutter/services.dart';

/// Carga objetos de partido Clash desde JSON local.
class ClashMatchItemsLocalDataSource {
  ClashMatchItemsLocalDataSource({
    this.assetPath = 'assets/data/clash/match_items.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashMatchItem>> loadItems() async {
    final raw = await _bundle.loadString(assetPath);
    return parseItemsJson(raw);
  }

  Future<List<ClashMatchItemInventoryEntry>> loadDefaultKit() async {
    final raw = await _bundle.loadString(assetPath);
    return parseDefaultKitJson(raw);
  }

  List<ClashMatchItem> parseItemsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de objetos Clash debe ser un objeto');
    }
    final itemsRaw = decoded['items'];
    if (itemsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: items');
    }
    return itemsRaw
        .map(
          (item) =>
              ClashMatchItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  List<ClashMatchItemInventoryEntry> parseDefaultKitJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de objetos Clash debe ser un objeto');
    }
    final items = parseItemsJson(rawJson);
    final byId = {for (final item in items) item.id: item};
    final kitRaw = decoded['defaultKit'];
    if (kitRaw is! Map) {
      throw FormatException('Campo obligatorio ausente: defaultKit');
    }
    return kitRaw.entries
        .map((entry) {
          final item = byId[entry.key.toString()];
          if (item == null) {
            throw FormatException('Objeto de kit desconocido: ${entry.key}');
          }
          final quantity = switch (entry.value) {
            int value => value,
            num value => value.toInt(),
            String value => int.parse(value),
            _ => 0,
          };
          return ClashMatchItemInventoryEntry(item: item, quantity: quantity);
        })
        .toList(growable: false);
  }
}

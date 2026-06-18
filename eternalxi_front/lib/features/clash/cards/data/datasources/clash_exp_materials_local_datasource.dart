import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material.dart';
import 'package:flutter/services.dart';

/// Carga materiales EXP Clash desde JSON empaquetado en assets.
class ClashExpMaterialsLocalDataSource {
  ClashExpMaterialsLocalDataSource({
    this.assetPath = 'assets/data/clash/exp_materials.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashExpMaterial>> loadMaterials() async {
    final raw = await _bundle.loadString(assetPath);
    return parseMaterialsJson(raw);
  }

  List<ClashExpMaterial> parseMaterialsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de materiales EXP Clash debe ser un objeto');
    }

    final materialsRaw = decoded['materials'];
    if (materialsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: materials');
    }

    return materialsRaw
        .map(
          (item) =>
              ClashExpMaterial.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }
}

import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material.dart';
import 'package:flutter/services.dart';

/// Carga materiales de evolución Clash desde JSON empaquetado en assets.
class ClashEvolutionMaterialsLocalDataSource {
  ClashEvolutionMaterialsLocalDataSource({
    this.assetPath = 'assets/data/clash/evolution_materials.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashEvolutionMaterial>> loadMaterials() async {
    final raw = await _bundle.loadString(assetPath);
    return parseMaterialsJson(raw);
  }

  List<ClashEvolutionMaterial> parseMaterialsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'JSON de materiales de evolución Clash debe ser un objeto',
      );
    }

    final materialsRaw = decoded['materials'];
    if (materialsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: materials');
    }

    return materialsRaw
        .map(
          (item) => ClashEvolutionMaterial.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }
}

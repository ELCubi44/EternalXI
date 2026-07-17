import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';

/// Técnica futura aún no disponible en la carta actual.
class ClashLockedTechniquePreview {
  const ClashLockedTechniquePreview({
    required this.technique,
    required this.unlockRarity,
    this.unlockLevel,
  });

  final ClashSuperTechnique technique;
  final ClashRarity unlockRarity;
  final int? unlockLevel;
}

/// Técnicas activas según rareza/nivel efectivo (fusiona hermanos del catálogo).
List<ClashSuperTechnique> resolveActiveTechniques({
  required ClashCardCatalogEntry current,
  required List<ClashCardCatalogEntry> catalog,
}) {
  final playerId = current.playerId;
  if (playerId <= 0) {
    return List<ClashSuperTechnique>.from(current.displayCard.superTechniques);
  }

  final effective = current.effectiveRarity;
  final level = current.displayLevel;
  final byRarity = _siblingsByRarity(playerId, catalog);
  final merged = <ClashSuperTechnique>[];
  final seen = <String>{};

  void addFrom(ClashCardCatalogEntry? entry) {
    if (entry == null) {
      return;
    }
    for (final technique in entry.card.superTechniques) {
      final key = technique.name.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      merged.add(technique);
    }
  }

  for (final rarity in ClashRarity.values) {
    if (rarity.index > effective.index) {
      break;
    }
    addFrom(byRarity[rarity]);
  }

  // Cartas N: a nivel 50+ desbloquean la 2ª técnica de la versión R.
  if (effective == ClashRarity.n && level >= 50) {
    addFrom(byRarity[ClashRarity.r]);
  }

  if (merged.isEmpty) {
    return List<ClashSuperTechnique>.from(current.displayCard.superTechniques);
  }

  final maxSlots = effective.maxSuperTechniques;
  if (merged.length > maxSlots) {
    return merged.take(maxSlots).toList(growable: false);
  }
  return merged;
}

/// Resuelve técnicas de rarezas superiores del mismo jugador para mostrarlas
/// bloqueadas en el detalle.
List<ClashLockedTechniquePreview> resolveLockedTechniquePreviews({
  required ClashCardCatalogEntry current,
  required List<ClashCardCatalogEntry> catalog,
}) {
  final playerId = current.playerId;
  if (playerId <= 0) {
    return const [];
  }

  final active = resolveActiveTechniques(current: current, catalog: catalog);
  final currentNames = active.map((t) => t.name.trim().toLowerCase()).toSet();
  final byRarity = _siblingsByRarity(playerId, catalog);
  final previews = <ClashLockedTechniquePreview>[];
  final seenNames = {...currentNames};

  const order = [
    ClashRarity.r,
    ClashRarity.sr,
    ClashRarity.lr,
    ClashRarity.xi,
  ];

  for (final rarity in order) {
    if (rarity.index <= current.effectiveRarity.index) {
      continue;
    }
    final sibling = byRarity[rarity];
    if (sibling == null) {
      continue;
    }
    for (final technique in sibling.card.superTechniques) {
      final key = technique.name.trim().toLowerCase();
      if (seenNames.contains(key)) {
        continue;
      }
      seenNames.add(key);
      final unlockLevel = rarity == ClashRarity.r &&
              current.effectiveRarity == ClashRarity.n &&
              previews.isEmpty
          ? 50
          : null;
      previews.add(
        ClashLockedTechniquePreview(
          technique: technique,
          unlockRarity: rarity,
          unlockLevel: unlockLevel,
        ),
      );
    }
  }

  return previews;
}

Map<ClashRarity, ClashCardCatalogEntry> _siblingsByRarity(
  int playerId,
  List<ClashCardCatalogEntry> catalog,
) {
  final byRarity = <ClashRarity, ClashCardCatalogEntry>{};
  for (final entry in catalog) {
    if (entry.playerId != playerId) {
      continue;
    }
    final rarity = entry.card.rarity;
    final existing = byRarity[rarity];
    if (existing == null ||
        entry.card.superTechniques.length >
            existing.card.superTechniques.length) {
      byRarity[rarity] = entry;
    }
  }
  return byRarity;
}

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

  final currentNames = current.displayCard.superTechniques
      .map((t) => t.name.trim().toLowerCase())
      .toSet();

  final byRarity = <ClashRarity, ClashCardCatalogEntry>{};
  for (final entry in catalog) {
    if (entry.playerId != playerId) {
      continue;
    }
    final rarity = entry.effectiveRarity;
    final existing = byRarity[rarity];
    if (existing == null ||
        entry.card.superTechniques.length >
            existing.card.superTechniques.length) {
      byRarity[rarity] = entry;
    }
  }

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
      // La 2ª técnica de R también se anuncia como nivel 50 en cartas N
      // (pista de progresión además de la evolución).
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


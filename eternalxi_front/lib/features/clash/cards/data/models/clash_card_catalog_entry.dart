import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_level_scaling.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';

/// Carta Clash con metadatos de presentación del catálogo local.
///
/// Nombre y equipo pertenecen al jugador base; no forman parte del dominio puro.
class ClashCardCatalogEntry {
  const ClashCardCatalogEntry({
    required this.card,
    required this.name,
    required this.team,
    this.progress,
  });

  final ClashCard card;
  final String name;
  final String team;
  final ClashCardProgress? progress;

  String get id => card.id;
  int get playerId => card.playerId;

  ClashRarity get effectiveRarity =>
      ClashCardEvolutionResolver.effectiveRarity(card, progress);

  ClashCard get displayCard => card.withRarity(effectiveRarity);

  int get displayLevel => ClashCardLevelScaling.effectiveLevel(card, progress);

  ClashStats get displayStats =>
      ClashCardLevelScaling.effectiveStats(card, progress);

  int get power => ClashCardLevelScaling.effectivePower(card, progress);

  int? get xpToNextLevel {
    final p = progress;
    if (p == null || displayLevel >= effectiveRarity.maxLevel) {
      return null;
    }
    return ClashCardXpTable.xpToNextLevel(displayLevel, effectiveRarity);
  }

  bool get isMaxLevel => displayLevel >= effectiveRarity.maxLevel;

  ClashCardCatalogEntry withProgress(ClashCardProgress? value) {
    return ClashCardCatalogEntry(
      card: card,
      name: name,
      team: team,
      progress: value,
    );
  }

  factory ClashCardCatalogEntry.fromJson(Map<String, dynamic> json) {
    final name = clashRequireString(json['name'], 'name');
    final team = clashRequireString(json['team'], 'team');
    final card = ClashCard.fromJson(json);
    return ClashCardCatalogEntry(card: card, name: name, team: team);
  }

  Map<String, dynamic> toJson() => {
    ...card.toJson(),
    'name': name,
    'team': team,
  };
}

import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

/// Carta Clash con metadatos de presentación del catálogo local.
///
/// Nombre y equipo pertenecen al jugador base; no forman parte del dominio puro.
class ClashCardCatalogEntry {
  const ClashCardCatalogEntry({
    required this.card,
    required this.name,
    required this.team,
  });

  final ClashCard card;
  final String name;
  final String team;

  String get id => card.id;
  int get playerId => card.playerId;
  int get power => card.power;

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

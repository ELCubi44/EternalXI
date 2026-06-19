import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_player.dart';

/// Equipo rival reutilizable para partidos Clash (Fase 42).
class ClashRivalTeam {
  const ClashRivalTeam({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.recommendedPower,
    required this.lineup7v7,
  });

  final String id;
  final String name;
  final String description;
  final int difficulty;
  final int recommendedPower;
  final List<ClashRivalPlayer> lineup7v7;

  bool get hasCompleteLineup {
    if (lineup7v7.length != ClashPosition.values.length) {
      return false;
    }
    final positions = lineup7v7.map((player) => player.position).toSet();
    return positions.length == ClashPosition.values.length;
  }

  factory ClashRivalTeam.fromJson(Map<String, dynamic> json) {
    final lineupRaw = json['lineup7v7'] as List? ?? const [];
    return ClashRivalTeam(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      difficulty: clashAsInt(json['difficulty'], fallback: 1),
      recommendedPower: clashRequireInt(
        json['recommendedPower'],
        'recommendedPower',
      ),
      lineup7v7: lineupRaw
          .map(
            (item) => ClashRivalPlayer.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

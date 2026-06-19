import 'package:eternal_xi/features/clash/cards/domain/clash_card_level_scaling.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';

/// Jugador de un equipo rival Clash (read-only, no está en colección).
class ClashRivalPlayer {
  const ClashRivalPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.style,
    required this.level,
    required this.stats,
    this.playerId,
    this.rarity = ClashRarity.n,
    this.superTechniques = const [],
  });

  final String id;
  final int? playerId;
  final String name;
  final ClashPosition position;
  final ClashPlayerStyle style;
  final ClashRarity rarity;
  final int level;
  final ClashStats stats;
  final List<ClashSuperTechnique> superTechniques;

  ClashStats get effectiveStats {
    final multiplier = ClashCardLevelScaling.levelMultiplier(level, rarity);
    return stats.scaled(multiplier);
  }

  int get power => effectiveStats.power;

  factory ClashRivalPlayer.fromJson(Map<String, dynamic> json) {
    final techniquesRaw = json['superTechniques'] as List? ?? const [];
    return ClashRivalPlayer(
      id: clashRequireString(json['id'], 'id'),
      playerId: json['playerId'] == null ? null : clashAsInt(json['playerId']),
      name: clashRequireString(json['name'], 'name'),
      position: ClashPosition.fromJson(json['position']),
      style: ClashPlayerStyle.fromJson(json['style']),
      rarity: json['rarity'] == null
          ? ClashRarity.n
          : ClashRarity.fromJson(json['rarity']),
      level: clashAsInt(json['level'], fallback: 1),
      stats: ClashStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? const {}),
      ),
      superTechniques: techniquesRaw
          .map(
            (item) => ClashSuperTechnique.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

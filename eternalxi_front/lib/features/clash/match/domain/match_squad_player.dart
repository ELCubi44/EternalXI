import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Jugador en el partido con stats, resistencia y PT actuales.
class MatchSquadPlayer {
  const MatchSquadPlayer({
    required this.index,
    required this.side,
    required this.cardId,
    required this.playerId,
    required this.position,
    required this.label,
    required this.homeX,
    required this.homeY,
    required this.baseStats,
    required this.power,
    required this.currentStamina,
    required this.style,
    required this.superTechniques,
    required this.maxPt,
    required this.currentPt,
  });

  final int index;
  final MatchTeamSide side;
  final String cardId;
  final int playerId;
  final ClashPosition position;
  final ClashPlayerStyle style;
  final String label;
  final double homeX;
  final double homeY;
  final ClashStats baseStats;
  final int power;
  final int currentStamina;
  final List<ClashSuperTechnique> superTechniques;
  final int maxPt;
  final int currentPt;

  MatchBallZone get homeZone => MatchBallZone.forPositionIndex(index);

  int get effectivePass => baseStats.effectivePass(currentStamina);

  int get effectiveDribble => baseStats.effectiveDribble(currentStamina);

  int get effectiveDefense => baseStats.effectiveDefense(currentStamina);

  int get effectiveShot => baseStats.effectiveShot(currentStamina);

  int get effectiveSave => baseStats.effectiveSave(currentStamina);

  int get maxStamina => baseStats.stamina;

  MatchSquadPlayer copyWith({int? currentStamina, int? currentPt}) {
    return MatchSquadPlayer(
      index: index,
      side: side,
      cardId: cardId,
      playerId: playerId,
      position: position,
      style: style,
      label: label,
      homeX: homeX,
      homeY: homeY,
      baseStats: baseStats,
      power: power,
      currentStamina: currentStamina ?? this.currentStamina,
      superTechniques: superTechniques,
      maxPt: maxPt,
      currentPt: currentPt ?? this.currentPt,
    );
  }
}

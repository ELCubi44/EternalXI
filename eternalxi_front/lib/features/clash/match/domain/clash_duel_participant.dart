import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Participante de un duelo Clash.
class ClashDuelParticipant {
  const ClashDuelParticipant({
    required this.teamSide,
    required this.cardId,
    required this.playerId,
    required this.position,
    required this.style,
    required this.label,
    required this.squadIndex,
    required this.baseStat,
    required this.effectiveStat,
    required this.stamina,
    required this.power,
  });

  final MatchTeamSide teamSide;
  final String cardId;
  final int playerId;
  final ClashPosition position;
  final ClashPlayerStyle style;
  final String label;
  final int squadIndex;
  final int baseStat;
  final int effectiveStat;
  final int stamina;
  final int power;

  factory ClashDuelParticipant.fromSquadPlayer(
    MatchSquadPlayer player, {
    required int baseStat,
    required int effectiveStat,
  }) {
    return ClashDuelParticipant(
      teamSide: player.side,
      cardId: player.cardId,
      playerId: player.playerId,
      position: player.position,
      style: player.style,
      label: player.label,
      squadIndex: player.index,
      baseStat: baseStat,
      effectiveStat: effectiveStat,
      stamina: player.currentStamina,
      power: player.power,
    );
  }
}

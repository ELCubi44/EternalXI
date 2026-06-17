import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';

/// Duelo activo o recién resuelto en un partido Clash.
class ClashDuelState {
  const ClashDuelState({
    required this.duelId,
    required this.type,
    required this.attacker,
    required this.defender,
    required this.ballZone,
    required this.status,
    required this.attackerStyleResult,
    this.resolution,
  });

  final String duelId;
  final ClashDuelType type;
  final ClashDuelParticipant attacker;
  final ClashDuelParticipant defender;
  final MatchBallZone ballZone;
  final ClashDuelStatus status;
  final ClashDuelStyleResult attackerStyleResult;
  final ClashDuelResolution? resolution;

  bool get isPending => status == ClashDuelStatus.pendingUserChoice;

  String get eventText => resolution?.eventText ?? '';

  ClashDuelState copyWith({
    ClashDuelStatus? status,
    ClashDuelResolution? resolution,
  }) {
    return ClashDuelState(
      duelId: duelId,
      type: type,
      attacker: attacker,
      defender: defender,
      ballZone: ballZone,
      status: status ?? this.status,
      attackerStyleResult: attackerStyleResult,
      resolution: resolution ?? this.resolution,
    );
  }
}

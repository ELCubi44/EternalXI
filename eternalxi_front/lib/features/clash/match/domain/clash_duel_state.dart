import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

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
    this.presetAttackerChoice,
    this.defenderCandidateIndices,
  });

  final String duelId;
  final ClashDuelType type;
  final ClashDuelParticipant attacker;
  final ClashDuelParticipant defender;
  final MatchBallZone ballZone;
  final ClashDuelStatus status;
  final ClashDuelStyleResult attackerStyleResult;
  final ClashDuelResolution? resolution;
  final ClashDuelActionChoice? presetAttackerChoice;
  final List<int>? defenderCandidateIndices;

  bool get isPending =>
      status == ClashDuelStatus.pendingUserChoice ||
      status == ClashDuelStatus.pendingUserDefenderSelection ||
      status == ClashDuelStatus.pendingUserDefensiveChoice;

  bool get isUserAttacking =>
      status == ClashDuelStatus.pendingUserChoice &&
      attacker.teamSide == MatchTeamSide.user;

  bool get isUserDefending =>
      status == ClashDuelStatus.pendingUserDefenderSelection ||
      status == ClashDuelStatus.pendingUserDefensiveChoice;

  bool get needsDefenderSelection =>
      status == ClashDuelStatus.pendingUserDefenderSelection;

  String get eventText => resolution?.eventText ?? '';

  ClashDuelState copyWith({
    ClashDuelParticipant? defender,
    ClashDuelStatus? status,
    ClashDuelResolution? resolution,
    ClashDuelStyleResult? attackerStyleResult,
    ClashDuelActionChoice? presetAttackerChoice,
    List<int>? defenderCandidateIndices,
    bool clearDefenderCandidates = false,
  }) {
    return ClashDuelState(
      duelId: duelId,
      type: type,
      attacker: attacker,
      defender: defender ?? this.defender,
      ballZone: ballZone,
      status: status ?? this.status,
      attackerStyleResult: attackerStyleResult ?? this.attackerStyleResult,
      resolution: resolution ?? this.resolution,
      presetAttackerChoice: presetAttackerChoice ?? this.presetAttackerChoice,
      defenderCandidateIndices: clearDefenderCandidates
          ? null
          : (defenderCandidateIndices ?? this.defenderCandidateIndices),
    );
  }
}

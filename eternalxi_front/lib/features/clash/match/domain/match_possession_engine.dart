import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pass_option.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Motor provisional de posesión: pase y avance (Fase 8).
class MatchPossessionEngine {
  const MatchPossessionEngine._();

  static const int passStaminaCost = 3;
  static const int advanceStaminaCost = 6;

  static List<MatchPassOption> passOptions(MatchState state) {
    final squad = state.squadInPossession();
    final holder = state.ballHolderPlayer();
    if (holder == null) {
      return const [];
    }

    final defense = MatchPossessionMath.defenseQualityAgainst(state);
    final options = <MatchPassOption>[];

    for (final teammate in squad) {
      if (teammate.index == holder.index) {
        continue;
      }
      final percent = MatchPossessionMath.passSuccessPercent(
        passer: holder,
        receiver: teammate,
        ballZone: state.ballZone,
        pressure: state.pressure,
        rivalDefenseQuality: defense,
      );
      options.add(
        MatchPassOption(
          targetIndex: teammate.index,
          targetName: teammate.label,
          targetPosition: teammate.position,
          approximateZone: teammate.homeZone,
          successPercent: percent,
          targetPower: teammate.power,
        ),
      );
    }

    options.sort((a, b) => b.successPercent.compareTo(a.successPercent));
    return options;
  }

  static int advanceChance(MatchState state) {
    final holder = state.ballHolderPlayer();
    if (holder == null) {
      return MatchPossessionMath.minPercent;
    }
    return MatchPossessionMath.advanceSuccessPercent(
      carrier: holder,
      ballZone: state.ballZone,
      pressure: state.pressure,
      rivalDefenseQuality: MatchPossessionMath.defenseQualityAgainst(state),
    );
  }

  static MatchState executePass(
    MatchState state,
    int targetIndex,
    MatchChanceResolver chance,
  ) {
    final holder = state.ballHolderPlayer();
    if (holder == null) {
      return state;
    }

    final squad = state.squadInPossession();
    final receiver = squad.firstWhere(
      (player) => player.index == targetIndex,
      orElse: () => holder,
    );
    if (receiver.index == holder.index) {
      return state;
    }

    final percent = MatchPossessionMath.passSuccessPercent(
      passer: holder,
      receiver: receiver,
      ballZone: state.ballZone,
      pressure: state.pressure,
      rivalDefenseQuality: MatchPossessionMath.defenseQualityAgainst(state),
    );

    final success = chance.succeeds(percent);
    if (success) {
      final updatedSquad = _updateStamina(
        squad,
        holder.index,
        holder.currentStamina - passStaminaCost,
      );
      final nextState = state
          .copyWithSquad(state.possession, updatedSquad)
          .copyWith(
            ballHolderIndex: receiver.index,
            ballZone: receiver.homeZone,
            pressure: MatchPossessionMath.adjustPressureAfterPass(
              success: true,
              currentPressure: state.pressure,
              passRisk: MatchPossessionMath.possessionRiskForPass(percent),
            ),
            possessionRisk: MatchPossessionMath.possessionRiskForPass(percent),
            eventLog: [
              ...state.eventLog,
              MatchEvent(
                type: MatchEventType.passSuccess,
                message: 'Pase exitoso a ${receiver.label}',
              ),
            ],
          );
      return nextState;
    }

    return _losePossession(
      state,
      zone: receiver.homeZone,
      message: 'Pase fallido — el rival recupera',
      eventType: MatchEventType.passFail,
    );
  }

  static MatchState executeAdvance(
    MatchState state,
    MatchChanceResolver chance,
  ) {
    return executeFreeAdvance(state, chance);
  }

  /// Avance directo sin duelo (fallback o rival provisional).
  static MatchState executeFreeAdvance(
    MatchState state,
    MatchChanceResolver chance,
  ) {
    final holder = state.ballHolderPlayer();
    if (holder == null) {
      return state;
    }

    final percent = MatchPossessionMath.advanceSuccessPercent(
      carrier: holder,
      ballZone: state.ballZone,
      pressure: state.pressure,
      rivalDefenseQuality: MatchPossessionMath.defenseQualityAgainst(state),
    );

    final success = chance.succeeds(percent);
    if (success) {
      final nextZone = state.ballZone.advanceFor(state.possession);
      final updatedSquad = _updateStamina(
        state.squadInPossession(),
        holder.index,
        holder.currentStamina - advanceStaminaCost,
      );
      return state
          .copyWithSquad(state.possession, updatedSquad)
          .copyWith(
            ballZone: nextZone,
            pressure: MatchPossessionMath.adjustPressureAfterAdvance(
              success: true,
              currentPressure: state.pressure,
            ),
            possessionRisk: MatchPossessionMath.possessionRiskForPass(percent),
            eventLog: [
              ...state.eventLog,
              const MatchEvent(
                type: MatchEventType.advanceSuccess,
                message: 'Avance exitoso',
              ),
            ],
          );
    }

    return _losePossession(
      state,
      zone: state.ballZone,
      message: 'El rival recupera',
      eventType: MatchEventType.advanceFail,
    );
  }

  static MatchState _losePossession(
    MatchState state, {
    required MatchBallZone zone,
    required String message,
    required MatchEventType eventType,
    MatchTeamSide? newPossession,
  }) {
    final nextPossession = newPossession ?? state.possession.opposite();
    final receiver = nextPossession == MatchTeamSide.user
        ? MatchPossessionMath.pickUserInZone(state, zone)
        : MatchPossessionMath.pickRivalInZone(state, zone);

    return state.copyWith(
      possession: nextPossession,
      ballHolderIndex: receiver?.index ?? 3,
      ballZone: zone,
      pressure: (state.pressure + 8).clamp(0, 100),
      possessionRisk: (state.possessionRisk + 10).clamp(0, 100),
      eventLog: [
        ...state.eventLog,
        MatchEvent(type: eventType, message: message),
      ],
    );
  }

  static List<MatchSquadPlayer> _updateStamina(
    List<MatchSquadPlayer> squad,
    int index,
    int stamina,
  ) {
    return squad
        .map(
          (player) => player.index == index
              ? player.copyWith(currentStamina: stamina.clamp(0, 200))
              : player,
        )
        .toList();
  }
}

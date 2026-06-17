import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';

/// Motor de duelos Regate vs Defensa al avanzar (Fase 9).
class ClashDuelEngine {
  const ClashDuelEngine._();

  static const int defenderStaminaCost = 3;

  static MatchState beginAdvance(MatchState state, MatchChanceResolver chance) {
    final holder = state.ballHolderPlayer();
    if (holder == null || state.activeDuel != null) {
      return state;
    }

    final defender = ClashDuelDefenderSelector.selectForAdvance(state, holder);
    if (defender == null) {
      return MatchPossessionEngine.executeFreeAdvance(state, chance);
    }

    final attackerStyle = ClashDuelDefenderSelector.attackerStyleResult(
      holder.style,
      defender.style,
    );

    final duel = ClashDuelState(
      duelId: 'duel-${state.eventLog.length + 1}',
      type: ClashDuelType.dribbleVsDefense,
      attacker: ClashDuelParticipant.fromSquadPlayer(
        holder,
        baseStat: holder.baseStats.dribble,
        effectiveStat: holder.effectiveDribble,
      ),
      defender: ClashDuelParticipant.fromSquadPlayer(
        defender,
        baseStat: defender.baseStats.defense,
        effectiveStat: defender.effectiveDefense,
      ),
      ballZone: state.ballZone,
      status: ClashDuelStatus.pendingUserChoice,
      attackerStyleResult: attackerStyle,
    );

    return state.copyWith(
      activeDuel: duel,
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: MatchEventType.duelStarted,
          message: '${defender.label} sale a defender',
        ),
      ],
    );
  }

  static MatchState resolveNormalDribble(
    MatchState state,
    MatchChanceResolver chance, {
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final duel = state.activeDuel;
    if (duel == null || !duel.isPending) {
      return state;
    }

    final resolution = ClashDuelMath.resolveDribbleVsDefense(
      attacker: duel.attacker,
      defender: duel.defender,
      attackerStyleResult: duel.attackerStyleResult,
      ballZone: duel.ballZone,
      pressure: state.pressure,
      chance: chance,
      attackerVariance: attackerVariance,
      defenderVariance: defenderVariance,
    );

    final attackerWon = resolution.winner == duel.attacker.teamSide;
    final next = attackerWon
        ? _applyAttackerWin(state, duel, resolution)
        : _applyDefenderWin(state, duel, resolution);

    return next.copyWith(
      clearActiveDuel: true,
      lastDuelResolution: resolution,
    );
  }

  static MatchState dismissDuelResult(MatchState state) {
    return state.copyWith(clearLastDuelResolution: true);
  }

  static MatchState _applyAttackerWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
  ) {
    final nextZone = state.ballZone.advanceFor(state.possession);
    final updatedAttackers = _updateStamina(
      state.squadFor(duel.attacker.teamSide),
      duel.attacker.squadIndex,
      duel.attacker.stamina - MatchPossessionEngine.advanceStaminaCost,
    );
    final updatedDefenders = _updateStamina(
      state.squadFor(duel.defender.teamSide),
      duel.defender.squadIndex,
      duel.defender.stamina - defenderStaminaCost,
    );

    var next = state.copyWith(
      ballZone: nextZone,
      pressure: MatchPossessionMath.adjustPressureAfterAdvance(
        success: true,
        currentPressure: state.pressure,
      ),
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: MatchEventType.duelSuccess,
          message: resolution.eventText,
        ),
      ],
    );
    next = next.copyWithSquad(duel.attacker.teamSide, updatedAttackers);
    return next.copyWithSquad(duel.defender.teamSide, updatedDefenders);
  }

  static MatchState _applyDefenderWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
  ) {
    final nextPossession = duel.defender.teamSide;
    final updatedAttackers = _updateStamina(
      state.squadFor(duel.attacker.teamSide),
      duel.attacker.squadIndex,
      duel.attacker.stamina - MatchPossessionEngine.advanceStaminaCost,
    );
    final updatedDefenders = _updateStamina(
      state.squadFor(duel.defender.teamSide),
      duel.defender.squadIndex,
      duel.defender.stamina - defenderStaminaCost,
    );

    var next = state.copyWith(
      possession: nextPossession,
      ballHolderIndex: duel.defender.squadIndex,
      ballZone: state.ballZone,
      pressure: (state.pressure + 8).clamp(0, 100),
      possessionRisk: (state.possessionRisk + 10).clamp(0, 100),
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: MatchEventType.duelFail,
          message: resolution.eventText,
        ),
      ],
    );
    next = next.copyWithSquad(duel.attacker.teamSide, updatedAttackers);
    return next.copyWithSquad(duel.defender.teamSide, updatedDefenders);
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

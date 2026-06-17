import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Motor de duelos Clash: Regate vs Defensa (Fase 9) y Tiro vs Parada (Fase 10).
class ClashDuelEngine {
  const ClashDuelEngine._();

  static const int defenderStaminaCost = 3;
  static const int shotStaminaCost = 5;
  static const int goalkeeperStaminaCost = 4;

  static bool canShoot(MatchState state) {
    if (state.activeDuel != null || state.isFinished) {
      return false;
    }
    return state.isInShootingZone && state.ballHolderPlayer() != null;
  }

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

  static MatchState beginShot(MatchState state) {
    final holder = state.ballHolderPlayer();
    if (holder == null || state.activeDuel != null || !canShoot(state)) {
      return state;
    }

    final goalkeeper = ClashDuelDefenderSelector.selectGoalkeeper(
      state,
      holder.side,
    );
    if (goalkeeper == null) {
      return state;
    }

    final attackerStyle = ClashDuelDefenderSelector.attackerStyleResult(
      holder.style,
      goalkeeper.style,
    );

    final duel = ClashDuelState(
      duelId: 'shot-${state.eventLog.length + 1}',
      type: ClashDuelType.shotVsSave,
      attacker: ClashDuelParticipant.fromSquadPlayer(
        holder,
        baseStat: holder.baseStats.shot,
        effectiveStat: holder.effectiveShot,
      ),
      defender: ClashDuelParticipant.fromSquadPlayer(
        goalkeeper,
        baseStat: goalkeeper.baseStats.save,
        effectiveStat: goalkeeper.effectiveSave,
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
          type: MatchEventType.shotDuelStarted,
          message: '${holder.label} se planta ante ${goalkeeper.label}',
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
    if (duel == null ||
        !duel.isPending ||
        duel.type != ClashDuelType.dribbleVsDefense) {
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
        ? _applyDribbleAttackerWin(state, duel, resolution)
        : _applyDribbleDefenderWin(state, duel, resolution);

    return next.copyWith(clearActiveDuel: true, lastDuelResolution: resolution);
  }

  static MatchState resolveNormalShot(
    MatchState state,
    MatchChanceResolver chance, {
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final duel = state.activeDuel;
    if (duel == null ||
        !duel.isPending ||
        duel.type != ClashDuelType.shotVsSave) {
      return state;
    }

    final resolution = ClashDuelMath.resolveShotVsSave(
      shooter: duel.attacker,
      goalkeeper: duel.defender,
      attackerStyleResult: duel.attackerStyleResult,
      ballZone: duel.ballZone,
      pressure: state.pressure,
      chance: chance,
      attackerVariance: attackerVariance,
      defenderVariance: defenderVariance,
    );

    final attackerWon = resolution.winner == duel.attacker.teamSide;
    final next = attackerWon
        ? _applyShotAttackerWin(state, duel, resolution)
        : _applyShotGoalkeeperWin(state, duel, resolution);

    return next.copyWith(clearActiveDuel: true, lastDuelResolution: resolution);
  }

  static MatchState dismissDuelResult(MatchState state) {
    return state.copyWith(clearLastDuelResolution: true);
  }

  static MatchState _applyDribbleAttackerWin(
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

  static MatchState _applyDribbleDefenderWin(
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

  static MatchState _applyShotAttackerWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
  ) {
    var next = _applyShotStamina(state, duel);
    next = MatchRules.applyGoal(
      next,
      duel.attacker.teamSide,
      goalMessage: resolution.eventText,
    );
    return next;
  }

  static MatchState _applyShotGoalkeeperWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
  ) {
    final keeperSide = duel.defender.teamSide;
    final keeperZone = keeperSide == MatchTeamSide.user
        ? MatchBallZone.ownDefense
        : MatchBallZone.rivalArea;

    var next = _applyShotStamina(state, duel);
    next = next.copyWith(
      possession: keeperSide,
      ballHolderIndex: duel.defender.squadIndex,
      ballZone: keeperZone,
      pressure: (state.pressure - 6).clamp(0, 100),
      possessionRisk: (state.possessionRisk - 4).clamp(0, 100),
      eventLog: [
        ...next.eventLog,
        MatchEvent(
          type: MatchEventType.saveMade,
          message: resolution.eventText,
        ),
      ],
    );
    return next;
  }

  static MatchState _applyShotStamina(MatchState state, ClashDuelState duel) {
    final updatedShooters = _updateStamina(
      state.squadFor(duel.attacker.teamSide),
      duel.attacker.squadIndex,
      duel.attacker.stamina - shotStaminaCost,
    );
    final updatedKeepers = _updateStamina(
      state.squadFor(duel.defender.teamSide),
      duel.defender.squadIndex,
      duel.defender.stamina - goalkeeperStaminaCost,
    );
    var next = state.copyWithSquad(duel.attacker.teamSide, updatedShooters);
    return next.copyWithSquad(duel.defender.teamSide, updatedKeepers);
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

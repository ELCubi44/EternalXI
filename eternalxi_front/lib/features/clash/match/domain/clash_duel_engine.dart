import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_technique_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/domain/match_goal_details.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Motor de duelos Clash: Regate vs Defensa (Fase 9) y Tiro vs Parada (Fase 10–11).
class ClashDuelEngine {
  const ClashDuelEngine._();

  static const int defenderStaminaCost = 3;
  static const int defenderTechniqueStaminaCost = 5;
  static const int shotStaminaCost = 5;
  static const int shotTechniqueStaminaCost = 8;
  static const int goalkeeperStaminaCost = 4;
  static const int goalkeeperTechniqueStaminaCost = 6;
  static const int dribbleTechniqueStaminaCost = 9;

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

  /// Avance rival: duelo manual Regate vs Defensa del usuario (Fase 14).
  static MatchState beginRivalAdvance(
    MatchState state,
    MatchChanceResolver chance,
  ) {
    final holder = state.ballHolderPlayer();
    if (holder == null ||
        state.possession != MatchTeamSide.rival ||
        state.activeDuel != null) {
      return state;
    }

    final candidates = ClashDuelDefenderSelector.candidatesForRivalAdvance(
      state,
      holder,
    );
    if (candidates.isEmpty) {
      return MatchPossessionEngine.executeFreeAdvance(state, chance);
    }

    if (candidates.length == 1) {
      return _beginRivalDefenseDuel(state, holder, candidates.first);
    }

    final placeholder = candidates.first;
    final presetChoice = _rivalAttackerChoice(
      state,
      holder,
      placeholder,
      ClashDuelType.dribbleVsDefense,
    );

    return state.copyWith(
      activeDuel: ClashDuelState(
        duelId: 'rival-duel-${state.eventLog.length + 1}',
        type: ClashDuelType.dribbleVsDefense,
        attacker: _attackerParticipant(holder),
        defender: _defenderParticipant(placeholder),
        ballZone: state.ballZone,
        status: ClashDuelStatus.pendingUserDefenderSelection,
        attackerStyleResult: ClashDuelDefenderSelector.attackerStyleResult(
          holder.style,
          placeholder.style,
        ),
        presetAttackerChoice: presetChoice,
        defenderCandidateIndices: candidates.map((p) => p.index).toList(),
      ),
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: MatchEventType.duelStarted,
          message: '${holder.label} encara a tu defensa',
        ),
      ],
    );
  }

  /// Tiro rival pendiente de parada manual del usuario (Fase 14).
  static MatchState beginRivalShot(MatchState state) {
    final holder = state.ballHolderPlayer();
    if (holder == null ||
        state.possession != MatchTeamSide.rival ||
        state.activeDuel != null ||
        !canShoot(state)) {
      return state;
    }

    final goalkeeper = ClashDuelDefenderSelector.selectGoalkeeper(
      state,
      holder.side,
    );
    if (goalkeeper == null) {
      return state;
    }

    return _beginRivalDefenseDuel(state, holder, goalkeeper);
  }

  static MatchState selectUserDefender(MatchState state, int defenderIndex) {
    final duel = state.activeDuel;
    if (duel == null || !duel.needsDefenderSelection) {
      return state;
    }

    final candidates = duel.defenderCandidateIndices;
    if (candidates == null || !candidates.contains(defenderIndex)) {
      return state;
    }

    final defender = _userPlayer(state, defenderIndex);
    final attackerPlayer = _squadPlayer(state, duel.attacker);
    if (defender == null || attackerPlayer == null) {
      return state;
    }

    return state.copyWith(
      activeDuel: duel.copyWith(
        defender: _defenderParticipant(defender),
        status: ClashDuelStatus.pendingUserDefensiveChoice,
        attackerStyleResult: ClashDuelDefenderSelector.attackerStyleResult(
          attackerPlayer.style,
          defender.style,
        ),
        clearDefenderCandidates: true,
      ),
    );
  }

  static MatchState resolveManualDefense(
    MatchState state,
    MatchChanceResolver chance, {
    ClashDuelActionChoice defenderChoice = const ClashDuelActionChoice.normal(),
  }) {
    final duel = state.activeDuel;
    if (duel == null ||
        duel.status != ClashDuelStatus.pendingUserDefensiveChoice) {
      return state;
    }

    return resolveDuel(
      state,
      chance,
      attackerChoice:
          duel.presetAttackerChoice ?? const ClashDuelActionChoice.normal(),
      defenderChoice: defenderChoice,
    );
  }

  static MatchState _beginRivalDefenseDuel(
    MatchState state,
    MatchSquadPlayer holder,
    MatchSquadPlayer defender,
  ) {
    final isShot = state.isInShootingZone;
    final duelType = isShot
        ? ClashDuelType.shotVsSave
        : ClashDuelType.dribbleVsDefense;
    final presetChoice = _rivalAttackerChoice(
      state,
      holder,
      defender,
      duelType,
    );

    final duel = ClashDuelState(
      duelId: isShot
          ? 'rival-shot-${state.eventLog.length + 1}'
          : 'rival-duel-${state.eventLog.length + 1}',
      type: duelType,
      attacker: isShot
          ? _shooterParticipant(holder)
          : _attackerParticipant(holder),
      defender: isShot
          ? _goalkeeperParticipant(defender)
          : _defenderParticipant(defender),
      ballZone: state.ballZone,
      status: ClashDuelStatus.pendingUserDefensiveChoice,
      attackerStyleResult: ClashDuelDefenderSelector.attackerStyleResult(
        holder.style,
        defender.style,
      ),
      presetAttackerChoice: presetChoice,
    );

    return state.copyWith(
      activeDuel: duel,
      eventLog: [
        ...state.eventLog,
        MatchEvent(
          type: isShot
              ? MatchEventType.shotDuelStarted
              : MatchEventType.duelStarted,
          message: isShot
              ? '${holder.label} se planta ante ${defender.label}'
              : '${holder.label} encara a ${defender.label}',
        ),
      ],
    );
  }

  static ClashDuelParticipant _attackerParticipant(MatchSquadPlayer player) {
    return ClashDuelParticipant.fromSquadPlayer(
      player,
      baseStat: player.baseStats.dribble,
      effectiveStat: player.effectiveDribble,
    );
  }

  static ClashDuelParticipant _shooterParticipant(MatchSquadPlayer player) {
    return ClashDuelParticipant.fromSquadPlayer(
      player,
      baseStat: player.baseStats.shot,
      effectiveStat: player.effectiveShot,
    );
  }

  static ClashDuelParticipant _defenderParticipant(MatchSquadPlayer player) {
    return ClashDuelParticipant.fromSquadPlayer(
      player,
      baseStat: player.baseStats.defense,
      effectiveStat: player.effectiveDefense,
    );
  }

  static ClashDuelParticipant _goalkeeperParticipant(MatchSquadPlayer player) {
    return ClashDuelParticipant.fromSquadPlayer(
      player,
      baseStat: player.baseStats.save,
      effectiveStat: player.effectiveSave,
    );
  }

  static ClashDuelActionChoice _rivalAttackerChoice(
    MatchState state,
    MatchSquadPlayer attacker,
    MatchSquadPlayer defender,
    ClashDuelType duelType,
  ) {
    return ClashRivalTechniqueSelector.selectAttacker(
      player: attacker,
      duelType: duelType,
      effectiveBaseStat: duelType == ClashDuelType.shotVsSave
          ? attacker.effectiveShot
          : attacker.effectiveDribble,
      opponentStyle: defender.style,
      ballZone: state.ballZone,
      score: state.score,
      playerSide: attacker.side,
    );
  }

  static MatchSquadPlayer? _userPlayer(MatchState state, int index) {
    for (final player in state.userSquad) {
      if (player.index == index) {
        return player;
      }
    }
    return null;
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
    return resolveDuel(
      state,
      chance,
      attackerChoice: const ClashDuelActionChoice.normal(),
      attackerVariance: attackerVariance,
      defenderVariance: defenderVariance,
    );
  }

  static MatchState resolveNormalShot(
    MatchState state,
    MatchChanceResolver chance, {
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    return resolveDuel(
      state,
      chance,
      attackerChoice: const ClashDuelActionChoice.normal(),
      attackerVariance: attackerVariance,
      defenderVariance: defenderVariance,
    );
  }

  /// Resuelve un duelo pendiente con elección del atacante (usuario o IA).
  static MatchState resolveDuel(
    MatchState state,
    MatchChanceResolver chance, {
    ClashDuelActionChoice attackerChoice = const ClashDuelActionChoice.normal(),
    ClashDuelActionChoice? defenderChoice,
    int attackerVariance = 0,
    int defenderVariance = 0,
  }) {
    final duel = state.activeDuel;
    if (duel == null || !duel.isPending) {
      return state;
    }

    if (duel.status == ClashDuelStatus.pendingUserDefenderSelection) {
      return state;
    }

    final attackerPlayer = _squadPlayer(state, duel.attacker);
    final defenderPlayer = _squadPlayer(state, duel.defender);
    if (attackerPlayer == null || defenderPlayer == null) {
      return state;
    }

    final isManualDefense =
        duel.status == ClashDuelStatus.pendingUserDefensiveChoice;

    final resolvedAttackerChoice = isManualDefense
        ? (duel.presetAttackerChoice ?? const ClashDuelActionChoice.normal())
        : attackerChoice;

    final attackerTechnique = _validateTechnique(
      player: attackerPlayer,
      choice: resolvedAttackerChoice,
      requiredType: ClashDuelTechniqueRules.attackerTechniqueType(duel.type),
    );
    if (resolvedAttackerChoice.usesTechnique && attackerTechnique == null) {
      return state;
    }

    final resolvedDefenderChoice = isManualDefense
        ? defenderChoice
        : (defenderChoice ??
              _selectDefenderChoice(
                state: state,
                duel: duel,
                attackerPlayer: attackerPlayer,
                defenderPlayer: defenderPlayer,
                attackerTechnique: attackerTechnique,
                pressure: state.pressure,
              ));
    if (resolvedDefenderChoice == null) {
      return state;
    }

    final defenderTechnique = _validateTechnique(
      player: defenderPlayer,
      choice: resolvedDefenderChoice,
      requiredType: ClashDuelTechniqueRules.defenderTechniqueType(duel.type),
    );
    if (resolvedDefenderChoice.usesTechnique && defenderTechnique == null) {
      return state;
    }

    final techniqueEvents = _techniqueEvents(
      duel: duel,
      attackerTechnique: attackerTechnique,
      defenderTechnique: defenderTechnique,
    );

    final resolution = duel.type == ClashDuelType.dribbleVsDefense
        ? ClashDuelMath.resolveDribbleVsDefense(
            attacker: duel.attacker,
            defender: duel.defender,
            ballZone: duel.ballZone,
            pressure: state.pressure,
            chance: chance,
            attackerTechnique: attackerTechnique,
            defenderTechnique: defenderTechnique,
            attackerVariance: attackerVariance,
            defenderVariance: defenderVariance,
          )
        : ClashDuelMath.resolveShotVsSave(
            shooter: duel.attacker,
            goalkeeper: duel.defender,
            ballZone: duel.ballZone,
            pressure: state.pressure,
            chance: chance,
            shooterTechnique: attackerTechnique,
            goalkeeperTechnique: defenderTechnique,
            attackerVariance: attackerVariance,
            defenderVariance: defenderVariance,
          );

    var next = state.copyWith(
      eventLog: [...state.eventLog, ...techniqueEvents],
    );
    next = _applyPtCosts(
      next,
      duel,
      attackerTechnique: attackerTechnique,
      defenderTechnique: defenderTechnique,
    );

    final attackerWon = resolution.winner == duel.attacker.teamSide;
    if (duel.type == ClashDuelType.dribbleVsDefense) {
      next = attackerWon
          ? _applyDribbleAttackerWin(next, duel, resolution, attackerTechnique)
          : _applyDribbleDefenderWin(next, duel, resolution, defenderTechnique);
    } else {
      next = attackerWon
          ? _applyShotAttackerWin(next, duel, resolution, attackerTechnique)
          : _applyShotGoalkeeperWin(next, duel, resolution, defenderTechnique);
    }

    return next.copyWith(clearActiveDuel: true, lastDuelResolution: resolution);
  }

  /// Resuelve automáticamente un duelo del rival (ambos lados con IA).
  static MatchState resolveRivalAutoDuel(
    MatchState state,
    MatchChanceResolver chance,
  ) {
    final duel = state.activeDuel;
    if (duel == null || !duel.isPending) {
      return state;
    }

    final attackerPlayer = _squadPlayer(state, duel.attacker);
    final defenderPlayer = _squadPlayer(state, duel.defender);
    if (attackerPlayer == null || defenderPlayer == null) {
      return state;
    }

    final attackerChoice = ClashRivalTechniqueSelector.selectAttacker(
      player: attackerPlayer,
      duelType: duel.type,
      effectiveBaseStat: duel.attacker.effectiveStat,
      opponentStyle: defenderPlayer.style,
      ballZone: duel.ballZone,
      score: state.score,
      playerSide: attackerPlayer.side,
    );
    final attackerTechnique = _validateTechnique(
      player: attackerPlayer,
      choice: attackerChoice,
      requiredType: ClashDuelTechniqueRules.attackerTechniqueType(duel.type),
    );
    final opponentStyle = attackerTechnique?.style ?? attackerPlayer.style;

    final defenderChoice = ClashRivalTechniqueSelector.selectDefender(
      player: defenderPlayer,
      duelType: duel.type,
      effectiveBaseStat: duel.defender.effectiveStat,
      opponentStyle: opponentStyle,
      pressure: state.pressure,
      score: state.score,
      playerSide: defenderPlayer.side,
    );

    return resolveDuel(
      state,
      chance,
      attackerChoice: attackerChoice,
      defenderChoice: defenderChoice,
    );
  }

  static MatchState dismissDuelResult(MatchState state) {
    return state.copyWith(clearLastDuelResolution: true);
  }

  static ClashDuelActionChoice _selectDefenderChoice({
    required MatchState state,
    required ClashDuelState duel,
    required MatchSquadPlayer attackerPlayer,
    required MatchSquadPlayer defenderPlayer,
    required ClashSuperTechnique? attackerTechnique,
    required int pressure,
  }) {
    final opponentStyle = attackerTechnique?.style ?? attackerPlayer.style;
    return ClashRivalTechniqueSelector.selectDefender(
      player: defenderPlayer,
      duelType: duel.type,
      effectiveBaseStat: duel.defender.effectiveStat,
      opponentStyle: opponentStyle,
      pressure: pressure,
      score: state.score,
      playerSide: defenderPlayer.side,
    );
  }

  static ClashSuperTechnique? _validateTechnique({
    required MatchSquadPlayer player,
    required ClashDuelActionChoice choice,
    required ClashTechniqueType requiredType,
  }) {
    if (choice.isNormal) {
      return null;
    }
    final technique = ClashDuelTechniqueRules.findTechnique(
      player,
      choice.techniqueId,
    );
    if (technique == null ||
        technique.type != requiredType ||
        !technique.canBeUsed(player.currentPt)) {
      return null;
    }
    return technique;
  }

  static List<MatchEvent> _techniqueEvents({
    required ClashDuelState duel,
    required ClashSuperTechnique? attackerTechnique,
    required ClashSuperTechnique? defenderTechnique,
  }) {
    final events = <MatchEvent>[];
    if (attackerTechnique != null) {
      events.add(
        MatchEvent(
          type: MatchEventType.duelTechniqueUsed,
          message: '${duel.attacker.label} usa ${attackerTechnique.name}',
        ),
      );
    }
    if (defenderTechnique != null) {
      events.add(
        MatchEvent(
          type: MatchEventType.duelTechniqueUsed,
          message:
              '${duel.defender.label} responde con ${defenderTechnique.name}',
        ),
      );
    }
    return events;
  }

  static MatchState _applyPtCosts(
    MatchState state,
    ClashDuelState duel, {
    required ClashSuperTechnique? attackerTechnique,
    required ClashSuperTechnique? defenderTechnique,
  }) {
    var next = state;
    if (attackerTechnique != null) {
      next = _updatePt(
        next,
        duel.attacker.teamSide,
        duel.attacker.squadIndex,
        -attackerTechnique.ptCost,
      );
    }
    if (defenderTechnique != null) {
      next = _updatePt(
        next,
        duel.defender.teamSide,
        duel.defender.squadIndex,
        -defenderTechnique.ptCost,
      );
    }
    return next;
  }

  static MatchState _applyDribbleAttackerWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
    ClashSuperTechnique? attackerTechnique,
  ) {
    final nextZone = state.ballZone.advanceFor(state.possession);
    final attackerCost = attackerTechnique != null
        ? dribbleTechniqueStaminaCost
        : MatchPossessionEngine.advanceStaminaCost;
    final defenderCost = resolution.defenderUsedNormal
        ? defenderStaminaCost
        : defenderTechniqueStaminaCost;

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
    next = _updateStaminaOnSquad(
      next,
      duel.attacker.teamSide,
      duel.attacker.squadIndex,
      duel.attacker.stamina - attackerCost,
    );
    return _updateStaminaOnSquad(
      next,
      duel.defender.teamSide,
      duel.defender.squadIndex,
      duel.defender.stamina - defenderCost,
    );
  }

  static MatchState _applyDribbleDefenderWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
    ClashSuperTechnique? defenderTechnique,
  ) {
    final attackerCost = resolution.attackerUsedNormal
        ? MatchPossessionEngine.advanceStaminaCost
        : dribbleTechniqueStaminaCost;
    final defenderCost = defenderTechnique != null
        ? defenderTechniqueStaminaCost
        : defenderStaminaCost;

    var next = state.copyWith(
      possession: duel.defender.teamSide,
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
    next = _updateStaminaOnSquad(
      next,
      duel.attacker.teamSide,
      duel.attacker.squadIndex,
      duel.attacker.stamina - attackerCost,
    );
    return _updateStaminaOnSquad(
      next,
      duel.defender.teamSide,
      duel.defender.squadIndex,
      duel.defender.stamina - defenderCost,
    );
  }

  static MatchState _applyShotAttackerWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
    ClashSuperTechnique? attackerTechnique,
  ) {
    var next = _applyShotStamina(
      state,
      duel,
      attackerTechnique: attackerTechnique,
      defenderTechnique: null,
      resolution: resolution,
    );
    next = MatchRules.applyGoal(
      next,
      duel.attacker.teamSide,
      goalMessage: resolution.eventText,
      goalDetails: MatchGoalDetails(
        scorer: duel.attacker.teamSide,
        usedTechnique: attackerTechnique != null,
        techniqueType:
            attackerTechnique?.type ?? resolution.attackerTechniqueType,
        techniqueId: attackerTechnique?.id,
        techniqueName: attackerTechnique?.name,
      ),
    );
    return next;
  }

  static MatchState _applyShotGoalkeeperWin(
    MatchState state,
    ClashDuelState duel,
    ClashDuelResolution resolution,
    ClashSuperTechnique? defenderTechnique,
  ) {
    final keeperSide = duel.defender.teamSide;
    final keeperZone = keeperSide == MatchTeamSide.user
        ? MatchBallZone.ownDefense
        : MatchBallZone.rivalArea;

    var next = _applyShotStamina(
      state,
      duel,
      attackerTechnique: null,
      defenderTechnique: defenderTechnique,
      resolution: resolution,
    );
    return next.copyWith(
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
  }

  static MatchState _applyShotStamina(
    MatchState state,
    ClashDuelState duel, {
    required ClashSuperTechnique? attackerTechnique,
    required ClashSuperTechnique? defenderTechnique,
    required ClashDuelResolution resolution,
  }) {
    final shooterCost = resolution.attackerUsedNormal
        ? shotStaminaCost
        : shotTechniqueStaminaCost;
    final keeperCost = resolution.defenderUsedNormal
        ? goalkeeperStaminaCost
        : goalkeeperTechniqueStaminaCost;

    var next = _updateStaminaOnSquad(
      state,
      duel.attacker.teamSide,
      duel.attacker.squadIndex,
      duel.attacker.stamina - shooterCost,
    );
    return _updateStaminaOnSquad(
      next,
      duel.defender.teamSide,
      duel.defender.squadIndex,
      duel.defender.stamina - keeperCost,
    );
  }

  static MatchSquadPlayer? _squadPlayer(
    MatchState state,
    ClashDuelParticipant participant,
  ) {
    final squad = state.squadFor(participant.teamSide);
    if (participant.squadIndex < 0 || participant.squadIndex >= squad.length) {
      return null;
    }
    return squad[participant.squadIndex];
  }

  static MatchState _updateStaminaOnSquad(
    MatchState state,
    MatchTeamSide side,
    int index,
    int stamina,
  ) {
    final squad = state.squadFor(side);
    final updated = squad
        .map(
          (player) => player.index == index
              ? player.copyWith(currentStamina: stamina.clamp(0, 200))
              : player,
        )
        .toList();
    return state.copyWithSquad(side, updated);
  }

  static MatchState _updatePt(
    MatchState state,
    MatchTeamSide side,
    int index,
    int delta,
  ) {
    final squad = state.squadFor(side);
    final updated = squad
        .map(
          (player) => player.index == index
              ? player.copyWith(
                  currentPt: (player.currentPt + delta).clamp(0, player.maxPt),
                )
              : player,
        )
        .toList();
    return state.copyWithSquad(side, updated);
  }
}

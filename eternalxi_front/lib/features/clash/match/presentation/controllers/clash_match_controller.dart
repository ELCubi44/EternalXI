import 'dart:math';

import 'package:eternal_xi/features/clash/match/data/datasources/clash_match_items_local_datasource.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_halftime_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_engine.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pass_option.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:flutter/foundation.dart';

/// Controlador local del partido 7vs7 Clash.
class ClashMatchController extends ChangeNotifier {
  ClashMatchController({Random? random, MatchChanceResolver? chanceResolver})
    : _random = random ?? Random(),
      _chance = chanceResolver ?? RandomMatchChanceResolver(random ?? Random());

  final Random _random;
  final MatchChanceResolver _chance;

  MatchState? _state;

  MatchState? get state => _state;

  bool get isHalftime => _state?.isPausedForHalftime ?? false;

  static Future<List<ClashMatchItemInventoryEntry>> loadDefaultMatchKit() {
    return ClashMatchItemsLocalDataSource().loadDefaultKit();
  }

  bool _isGameplayBlocked(MatchState state) =>
      state.isPausedForHalftime || state.isFinished;

  List<MatchPassOption> get passOptions {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.user) {
      return const [];
    }
    return MatchPossessionEngine.passOptions(current);
  }

  int? get advanceChancePercent {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.user) {
      return null;
    }
    return MatchPossessionEngine.advanceChance(current);
  }

  void startMatch({
    required String levelId,
    ClashLineup7v7? lineup,
    Map<String, ClashCardCatalogEntry> catalogById = const {},
    int rivalPower = 120,
    List<ClashMatchItemInventoryEntry> matchInventory = const [],
  }) {
    final userSquad = MatchSquadBuilder.buildUserSquad(
      lineup: lineup,
      catalogById: catalogById,
    );
    final rivalSquad = MatchSquadBuilder.buildRivalSquad(basePower: rivalPower);

    _state = MatchState(
      levelId: levelId,
      status: MatchStatus.awaitingCoinToss,
      score: const MatchScore(),
      possession: MatchTeamSide.user,
      ballHolderIndex: 3,
      ballZone: MatchBallZone.ownMidfield,
      userSquad: userSquad,
      rivalSquad: rivalSquad,
      pressure: 20,
      possessionRisk: 15,
      eventLog: const [],
      matchInventory: matchInventory,
    );
    notifyListeners();
  }

  void chooseCoinToss(CoinTossChoice choice) {
    final current = _state;
    if (current == null || current.status != MatchStatus.awaitingCoinToss) {
      return;
    }

    final outcome = CoinTossOutcome.random(_random);
    final result = CoinTossResult.resolve(userChoice: choice, outcome: outcome);
    final kickoffSide = result.kickoffSide;
    final kickoffZone = kickoffSide == MatchTeamSide.user
        ? MatchBallZone.ownMidfield
        : MatchBallZone.rivalMidfield;

    _state = current.copyWith(
      status: MatchStatus.playing,
      coinToss: result,
      possession: kickoffSide,
      ballHolderIndex: 3,
      ballZone: kickoffZone,
      pressure: 18,
      possessionRisk: 14,
      eventLog: [
        ...current.eventLog,
        MatchEvent(
          type: MatchEventType.kickoff,
          message: kickoffSide == MatchTeamSide.user
              ? 'Saque inicial: Eternal XI'
              : 'Saque inicial: Rival',
        ),
      ],
    );
    notifyListeners();
  }

  bool get hasPendingDuel {
    final current = _state;
    return current?.hasPendingDuel ?? false;
  }

  bool get hasDuelResultToShow => _state?.lastDuelResolution != null;

  bool get canUserShoot {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
        current.isPausedForHalftime ||
        current.possession != MatchTeamSide.user ||
        current.hasPendingDuel ||
        current.lastDuelResolution != null) {
      return false;
    }
    return ClashDuelEngine.canShoot(current);
  }

  void passTo(int targetIndex) {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.user ||
        current.hasPendingDuel) {
      return;
    }
    _state = MatchPossessionEngine.executePass(current, targetIndex, _chance);
    notifyListeners();
  }

  void advance() {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.user ||
        current.hasPendingDuel ||
        current.lastDuelResolution != null) {
      return;
    }
    _state = ClashDuelEngine.beginAdvance(current, _chance);
    notifyListeners();
  }

  void resolveNormalDribble() {
    final current = _state;
    if (current == null ||
        !current.hasPendingDuel ||
        current.isPausedForHalftime) {
      return;
    }
    _state = ClashDuelEngine.resolveNormalDribble(current, _chance);
    notifyListeners();
  }

  void shoot() {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.user ||
        current.hasPendingDuel ||
        current.lastDuelResolution != null ||
        !ClashDuelEngine.canShoot(current)) {
      return;
    }
    _state = ClashDuelEngine.beginShot(current);
    notifyListeners();
  }

  void resolveNormalShot() {
    final current = _state;
    if (current == null ||
        !current.hasPendingDuel ||
        current.isPausedForHalftime) {
      return;
    }
    _state = ClashDuelEngine.resolveNormalShot(current, _chance);
    notifyListeners();
  }

  void resolvePendingDuel({String? techniqueId}) {
    final current = _state;
    final duel = current?.activeDuel;
    if (current == null ||
        duel == null ||
        !duel.isPending ||
        current.isPausedForHalftime) {
      return;
    }
    final attackerChoice = techniqueId != null
        ? ClashDuelActionChoice.technique(techniqueId)
        : const ClashDuelActionChoice.normal();
    _state = ClashDuelEngine.resolveDuel(
      current,
      _chance,
      attackerChoice: attackerChoice,
    );
    notifyListeners();
  }

  void dismissDuelResult() {
    final current = _state;
    if (current == null || current.lastDuelResolution == null) {
      return;
    }
    _state = ClashDuelEngine.dismissDuelResult(current);
    notifyListeners();
  }

  void simulateRivalAction() {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.rival) {
      return;
    }
    _state = MatchPossessionEngine.executeRivalTurn(current, _chance);
    notifyListeners();
  }

  void simulateUserGoal() {
    _scoreGoal(MatchTeamSide.user);
  }

  void simulateRivalGoal() {
    _scoreGoal(MatchTeamSide.rival);
  }

  void _scoreGoal(MatchTeamSide scorer) {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
        current.isPausedForHalftime) {
      return;
    }
    _state = MatchRules.applyGoal(current, scorer);
    notifyListeners();
  }

  void continueFromHalftime() {
    final current = _state;
    if (current == null || !current.isPausedForHalftime) {
      return;
    }
    _state = ClashHalftimeEngine.continueFromHalftime(current);
    notifyListeners();
  }

  void useMatchItem(String itemId, {List<int> targetIndices = const []}) {
    final current = _state;
    if (current == null || !current.isPausedForHalftime) {
      return;
    }
    _state = ClashMatchItemEngine.useItem(
      current,
      itemId: itemId,
      targetIndices: targetIndices,
    );
    notifyListeners();
  }

  void clearItemEffectFeedback() {
    final current = _state;
    if (current == null || current.lastItemEffectResult == null) {
      return;
    }
    _state = current.copyWith(clearLastItemEffectResult: true);
    notifyListeners();
  }

  void reset() {
    _state = null;
    notifyListeners();
  }

  /// Inicio directo en juego (solo tests).
  @visibleForTesting
  void beginPlayingWithKickoff(MatchTeamSide kickoffSide) {
    final current = _state;
    if (current == null) {
      return;
    }
    _state = current.copyWith(
      status: MatchStatus.playing,
      possession: kickoffSide,
      ballHolderIndex: 3,
      ballZone: kickoffSide == MatchTeamSide.user
          ? MatchBallZone.ownMidfield
          : MatchBallZone.rivalMidfield,
      eventLog: [
        ...current.eventLog,
        MatchEvent(
          type: MatchEventType.kickoff,
          message: kickoffSide == MatchTeamSide.user
              ? 'Saque inicial: Eternal XI'
              : 'Saque inicial: Rival',
        ),
      ],
    );
    notifyListeners();
  }

  /// Sustituye el estado del partido (solo tests).
  @visibleForTesting
  void setStateForTesting(MatchState state) {
    _state = state;
    notifyListeners();
  }
}

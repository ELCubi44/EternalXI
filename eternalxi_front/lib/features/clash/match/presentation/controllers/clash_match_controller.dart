import 'dart:math';

import 'package:eternal_xi/features/clash/match/data/datasources/clash_match_items_local_datasource.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_halftime_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_engine.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pass_option.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_decision.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
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
  ClashRivalAiDecision? _lastRivalAiDecision;
  String? _levelId;
  ClashLineup7v7? _lineup;
  Map<String, ClashCardCatalogEntry> _catalogById = const {};
  List<MatchSquadPlayer>? _rivalSquad;
  String? _rivalTeamName;
  int _rivalPower = 120;
  List<ClashMatchItemInventoryEntry> _matchInventory = const [];

  MatchState? get state => _state;

  ClashRivalAiDecision? get lastRivalAiDecision => _lastRivalAiDecision;

  bool get isHalftime => _state?.isPausedForHalftime ?? false;

  String? get rivalTeamName => _rivalTeamName;

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

  bool get canUserPass => passOptions.isNotEmpty;

  void startMatch({
    required String levelId,
    ClashLineup7v7? lineup,
    Map<String, ClashCardCatalogEntry> catalogById = const {},
    int rivalPower = 120,
    List<MatchSquadPlayer>? rivalSquad,
    String? rivalTeamName,
    List<ClashMatchItemInventoryEntry> matchInventory = const [],
  }) {
    final userSquad = MatchSquadBuilder.buildUserSquad(
      lineup: lineup,
      catalogById: catalogById,
    );
    final resolvedRivalSquad =
        rivalSquad ?? MatchSquadBuilder.buildRivalSquad(basePower: rivalPower);

    _levelId = levelId;
    _lineup = lineup;
    _catalogById = catalogById;
    _rivalPower = rivalPower;
    _rivalSquad = rivalSquad;
    _rivalTeamName = rivalTeamName;
    _matchInventory = matchInventory;
    _lastRivalAiDecision = null;

    _state = MatchState(
      levelId: levelId,
      status: MatchStatus.awaitingCoinToss,
      score: const MatchScore(),
      possession: MatchTeamSide.user,
      ballHolderIndex: 3,
      ballZone: MatchBallZone.ownMidfield,
      userSquad: userSquad,
      rivalSquad: resolvedRivalSquad,
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
    final rivalLabel = _rivalTeamName ?? 'Rival';

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
              : 'Saque inicial: $rivalLabel',
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
        !duel.isUserAttacking ||
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

  void selectManualDefender(int defenderIndex) {
    final current = _state;
    if (current == null || current.isPausedForHalftime) {
      return;
    }
    _state = ClashDuelEngine.selectUserDefender(current, defenderIndex);
    notifyListeners();
  }

  void resolveManualDefense({String? techniqueId}) {
    final current = _state;
    final duel = current?.activeDuel;
    if (current == null ||
        duel == null ||
        duel.status != ClashDuelStatus.pendingUserDefensiveChoice ||
        current.isPausedForHalftime) {
      return;
    }
    final defenderChoice = techniqueId != null
        ? ClashDuelActionChoice.technique(techniqueId)
        : const ClashDuelActionChoice.normal();
    _state = ClashDuelEngine.resolveManualDefense(
      current,
      _chance,
      defenderChoice: defenderChoice,
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

  void continueRivalTurn() {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        _isGameplayBlocked(current) ||
        current.possession != MatchTeamSide.rival ||
        current.hasPendingDuel) {
      return;
    }
    final result = ClashRivalAiEngine.executeTurn(current, _chance);
    _state = result.state;
    _lastRivalAiDecision = result.decision;
    notifyListeners();
  }

  void simulateRivalAction() => continueRivalTurn();

  /// Reinicia el partido con la misma configuración (Fase 15).
  void restartMatch({
    ClashLineup7v7? lineup,
    Map<String, ClashCardCatalogEntry>? catalogById,
    List<ClashMatchItemInventoryEntry>? matchInventory,
    int? rivalPower,
    List<MatchSquadPlayer>? rivalSquad,
    String? rivalTeamName,
  }) {
    final levelId = _levelId;
    if (levelId == null) {
      return;
    }
    startMatch(
      levelId: levelId,
      lineup: lineup ?? _lineup,
      catalogById: catalogById ?? _catalogById,
      rivalPower: rivalPower ?? _rivalPower,
      rivalSquad: rivalSquad ?? _rivalSquad,
      rivalTeamName: rivalTeamName ?? _rivalTeamName,
      matchInventory: matchInventory ?? _matchInventory,
    );
  }

  @visibleForTesting
  void simulateUserGoal() {
    _scoreGoal(MatchTeamSide.user);
  }

  @visibleForTesting
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
    _lastRivalAiDecision = null;
    _levelId = null;
    _lineup = null;
    _catalogById = const {};
    _rivalPower = 120;
    _rivalSquad = null;
    _rivalTeamName = null;
    _matchInventory = const [];
    notifyListeners();
  }

  /// Inicio directo en juego (solo tests).
  @visibleForTesting
  void beginPlayingWithKickoff(MatchTeamSide kickoffSide) {
    final current = _state;
    if (current == null) {
      return;
    }
    final rivalLabel = _rivalTeamName ?? 'Rival';
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
              : 'Saque inicial: $rivalLabel',
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

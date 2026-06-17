import 'dart:math';

import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
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

  List<MatchPassOption> get passOptions {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
        current.possession != MatchTeamSide.user) {
      return const [];
    }
    return MatchPossessionEngine.passOptions(current);
  }

  int? get advanceChancePercent {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
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

  void passTo(int targetIndex) {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
        current.possession != MatchTeamSide.user) {
      return;
    }
    _state = MatchPossessionEngine.executePass(current, targetIndex, _chance);
    notifyListeners();
  }

  void advance() {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
        current.possession != MatchTeamSide.user) {
      return;
    }
    _state = MatchPossessionEngine.executeAdvance(current, _chance);
    notifyListeners();
  }

  void simulateRivalAction() {
    final current = _state;
    if (current == null ||
        current.status != MatchStatus.playing ||
        current.isFinished ||
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
        current.isFinished) {
      return;
    }
    _state = MatchRules.applyGoal(current, scorer);
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
}

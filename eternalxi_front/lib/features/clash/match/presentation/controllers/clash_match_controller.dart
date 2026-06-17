import 'dart:math';

import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/foundation.dart';

/// Controlador local del shell de partido 7vs7 (Fase 7).
class ClashMatchController extends ChangeNotifier {
  ClashMatchController({Random? random}) : _random = random ?? Random();

  final Random _random;

  MatchState? _state;

  MatchState? get state => _state;

  void startMatch({
    required String levelId,
    List<String> userPlayerNames = const [],
  }) {
    final userMarkers = userPlayerNames.isEmpty
        ? MatchPitchLayout.defaultUserMarkers()
        : MatchPitchLayout.userMarkersFromNames(userPlayerNames);
    _state = MatchState(
      levelId: levelId,
      status: MatchStatus.awaitingCoinToss,
      score: const MatchScore(),
      possession: MatchTeamSide.user,
      ballHolderIndex: 3,
      userMarkers: userMarkers,
      rivalMarkers: MatchPitchLayout.defaultRivalMarkers(),
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

    _state = current.copyWith(
      status: MatchStatus.playing,
      coinToss: result,
      possession: result.kickoffSide,
      ballHolderIndex: 3,
    );
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
}

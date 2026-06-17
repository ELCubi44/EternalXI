import 'dart:math';

import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

enum CoinTossChoice {
  heads,
  tails;

  bool get isHeads => this == CoinTossChoice.heads;
}

enum CoinTossOutcome {
  heads,
  tails;

  static CoinTossOutcome random(Random random) =>
      random.nextBool() ? CoinTossOutcome.heads : CoinTossOutcome.tails;
}

class CoinTossResult {
  const CoinTossResult({
    required this.userChoice,
    required this.outcome,
    required this.userWonToss,
    required this.kickoffSide,
  });

  final CoinTossChoice userChoice;
  final CoinTossOutcome outcome;
  final bool userWonToss;
  final MatchTeamSide kickoffSide;

  static CoinTossResult resolve({
    required CoinTossChoice userChoice,
    required CoinTossOutcome outcome,
  }) {
    final userWon =
        (userChoice.isHeads && outcome == CoinTossOutcome.heads) ||
        (!userChoice.isHeads && outcome == CoinTossOutcome.tails);
    return CoinTossResult(
      userChoice: userChoice,
      outcome: outcome,
      userWonToss: userWon,
      kickoffSide: userWon ? MatchTeamSide.user : MatchTeamSide.rival,
    );
  }
}

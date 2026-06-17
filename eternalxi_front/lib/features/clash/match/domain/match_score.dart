import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Marcador de un partido Clash 7vs7.
class MatchScore {
  const MatchScore({this.user = 0, this.rival = 0});

  final int user;
  final int rival;

  static const int winTarget = 3;

  int goalsFor(MatchTeamSide side) => side == MatchTeamSide.user ? user : rival;

  bool hasWinner() => user >= winTarget || rival >= winTarget;

  MatchTeamSide? winner() {
    if (user >= winTarget) {
      return MatchTeamSide.user;
    }
    if (rival >= winTarget) {
      return MatchTeamSide.rival;
    }
    return null;
  }

  MatchScore increment(MatchTeamSide scorer) {
    return MatchScore(
      user: user + (scorer == MatchTeamSide.user ? 1 : 0),
      rival: rival + (scorer == MatchTeamSide.rival ? 1 : 0),
    );
  }
}

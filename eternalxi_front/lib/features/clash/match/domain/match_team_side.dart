/// Lado del partido Clash 7vs7.
enum MatchTeamSide {
  user,
  rival;

  MatchTeamSide opposite() =>
      this == MatchTeamSide.user ? MatchTeamSide.rival : MatchTeamSide.user;
}

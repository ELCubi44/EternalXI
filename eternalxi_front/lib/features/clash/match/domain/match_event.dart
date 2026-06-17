/// Evento breve del historial de partido.
enum MatchEventType {
  kickoff,
  passSuccess,
  passFail,
  advanceSuccess,
  advanceFail,
  duelStarted,
  duelSuccess,
  duelFail,
  shotDuelStarted,
  saveMade,
  possessionLost,
  rivalAction,
  goal,
}

class MatchEvent {
  const MatchEvent({required this.type, required this.message});

  final MatchEventType type;
  final String message;
}

/// Evento breve del historial de partido.
enum MatchEventType {
  kickoff,
  passSuccess,
  passFail,
  advanceSuccess,
  advanceFail,
  possessionLost,
  rivalAction,
  goal,
}

class MatchEvent {
  const MatchEvent({required this.type, required this.message});

  final MatchEventType type;
  final String message;
}

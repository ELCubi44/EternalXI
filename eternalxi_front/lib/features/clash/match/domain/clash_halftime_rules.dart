import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';

/// Reglas del descanso único de partido (Fase 12).
class ClashHalftimeRules {
  const ClashHalftimeRules._();

  static const int halftimeGoalTotal = 2;

  static bool shouldTriggerHalftime(MatchState state, MatchScore nextScore) {
    if (state.hasHalftimeOccurred || nextScore.hasWinner()) {
      return false;
    }
    return nextScore.user + nextScore.rival >= halftimeGoalTotal;
  }
}

import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';

/// Transiciones de descanso en partido Clash.
class ClashHalftimeEngine {
  const ClashHalftimeEngine._();

  static MatchState continueFromHalftime(MatchState state) {
    if (!state.isHalftime || state.status != MatchStatus.halftime) {
      return state;
    }
    return state.copyWith(
      status: MatchStatus.playing,
      isHalftime: false,
      clearLastItemEffectResult: true,
      eventLog: [
        ...state.eventLog,
        const MatchEvent(
          type: MatchEventType.halftimeEnded,
          message: 'Segunda parte',
        ),
      ],
    );
  }
}

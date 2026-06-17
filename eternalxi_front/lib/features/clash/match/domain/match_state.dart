import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Estado completo de un partido Clash 7vs7 (shell local Fase 7).
class MatchState {
  const MatchState({
    required this.levelId,
    required this.status,
    required this.score,
    required this.possession,
    required this.ballHolderIndex,
    required this.userMarkers,
    required this.rivalMarkers,
    this.coinToss,
  });

  final String levelId;
  final MatchStatus status;
  final MatchScore score;
  final MatchTeamSide possession;
  final int ballHolderIndex;
  final List<MatchPlayerMarker> userMarkers;
  final List<MatchPlayerMarker> rivalMarkers;
  final CoinTossResult? coinToss;

  bool get isFinished => status == MatchStatus.finished;

  MatchTeamSide? get winner => score.winner();

  List<MatchPlayerMarker> markersFor(MatchTeamSide side) =>
      side == MatchTeamSide.user ? userMarkers : rivalMarkers;

  MatchPlayerMarker? ballHolder() {
    final markers = markersFor(possession);
    if (ballHolderIndex < 0 || ballHolderIndex >= markers.length) {
      return markers.isNotEmpty ? markers.first : null;
    }
    return markers[ballHolderIndex];
  }

  MatchState copyWith({
    MatchStatus? status,
    MatchScore? score,
    MatchTeamSide? possession,
    int? ballHolderIndex,
    CoinTossResult? coinToss,
  }) {
    return MatchState(
      levelId: levelId,
      status: status ?? this.status,
      score: score ?? this.score,
      possession: possession ?? this.possession,
      ballHolderIndex: ballHolderIndex ?? this.ballHolderIndex,
      userMarkers: userMarkers,
      rivalMarkers: rivalMarkers,
      coinToss: coinToss ?? this.coinToss,
    );
  }
}

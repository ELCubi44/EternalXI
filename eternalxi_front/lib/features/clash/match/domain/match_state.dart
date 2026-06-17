import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Estado completo de un partido Clash 7vs7.
class MatchState {
  const MatchState({
    required this.levelId,
    required this.status,
    required this.score,
    required this.possession,
    required this.ballHolderIndex,
    required this.ballZone,
    required this.userSquad,
    required this.rivalSquad,
    required this.pressure,
    required this.possessionRisk,
    required this.eventLog,
    this.coinToss,
    this.activeDuel,
    this.lastDuelResolution,
  });

  final String levelId;
  final MatchStatus status;
  final MatchScore score;
  final MatchTeamSide possession;
  final int ballHolderIndex;
  final MatchBallZone ballZone;
  final List<MatchSquadPlayer> userSquad;
  final List<MatchSquadPlayer> rivalSquad;
  final int pressure;
  final int possessionRisk;
  final List<MatchEvent> eventLog;
  final CoinTossResult? coinToss;
  final ClashDuelState? activeDuel;
  final ClashDuelResolution? lastDuelResolution;

  bool get hasPendingDuel => activeDuel?.isPending ?? false;

  List<MatchPlayerMarker> get userMarkers =>
      MatchSquadBuilder.markersFromSquad(userSquad);

  List<MatchPlayerMarker> get rivalMarkers =>
      MatchSquadBuilder.markersFromSquad(rivalSquad);

  bool get isFinished => status == MatchStatus.finished;

  MatchTeamSide? get winner => score.winner();

  List<MatchSquadPlayer> squadFor(MatchTeamSide side) =>
      side == MatchTeamSide.user ? userSquad : rivalSquad;

  List<MatchSquadPlayer> squadInPossession() => squadFor(possession);

  List<MatchPlayerMarker> markersFor(MatchTeamSide side) =>
      side == MatchTeamSide.user ? userMarkers : rivalMarkers;

  MatchSquadPlayer? ballHolderPlayer() {
    final squad = squadInPossession();
    for (final player in squad) {
      if (player.index == ballHolderIndex) {
        return player;
      }
    }
    return squad.isNotEmpty ? squad.first : null;
  }

  MatchPlayerMarker? ballHolder() {
    final holder = ballHolderPlayer();
    if (holder == null) {
      return null;
    }
    return MatchPlayerMarker(
      side: holder.side,
      index: holder.index,
      label: holder.label,
      x: holder.homeX,
      y: holder.homeY,
      cardId: holder.cardId,
    );
  }

  MatchState copyWith({
    MatchStatus? status,
    MatchScore? score,
    MatchTeamSide? possession,
    int? ballHolderIndex,
    MatchBallZone? ballZone,
    List<MatchSquadPlayer>? userSquad,
    List<MatchSquadPlayer>? rivalSquad,
    int? pressure,
    int? possessionRisk,
    List<MatchEvent>? eventLog,
    CoinTossResult? coinToss,
    ClashDuelState? activeDuel,
    ClashDuelResolution? lastDuelResolution,
    bool clearActiveDuel = false,
    bool clearLastDuelResolution = false,
  }) {
    return MatchState(
      levelId: levelId,
      status: status ?? this.status,
      score: score ?? this.score,
      possession: possession ?? this.possession,
      ballHolderIndex: ballHolderIndex ?? this.ballHolderIndex,
      ballZone: ballZone ?? this.ballZone,
      userSquad: userSquad ?? this.userSquad,
      rivalSquad: rivalSquad ?? this.rivalSquad,
      pressure: pressure ?? this.pressure,
      possessionRisk: possessionRisk ?? this.possessionRisk,
      eventLog: eventLog ?? this.eventLog,
      coinToss: coinToss ?? this.coinToss,
      activeDuel: clearActiveDuel ? null : (activeDuel ?? this.activeDuel),
      lastDuelResolution: clearLastDuelResolution
          ? null
          : (lastDuelResolution ?? this.lastDuelResolution),
    );
  }

  MatchState copyWithSquad(MatchTeamSide side, List<MatchSquadPlayer> squad) {
    if (side == MatchTeamSide.user) {
      return copyWith(userSquad: squad);
    }
    return copyWith(rivalSquad: squad);
  }

  /// Estado mínimo para tests de Fase 7/8.
  factory MatchState.testing({
    MatchScore score = const MatchScore(),
    MatchTeamSide possession = MatchTeamSide.user,
    int ballHolderIndex = 3,
    MatchBallZone ballZone = MatchBallZone.ownMidfield,
    int pressure = 25,
    int possessionRisk = 20,
  }) {
    return MatchState(
      levelId: 'test',
      status: MatchStatus.playing,
      score: score,
      possession: possession,
      ballHolderIndex: ballHolderIndex,
      ballZone: ballZone,
      userSquad: MatchSquadBuilder.buildUserSquad(
        lineup: null,
        catalogById: const {},
      ),
      rivalSquad: MatchSquadBuilder.buildRivalSquad(),
      pressure: pressure,
      possessionRisk: possessionRisk,
      eventLog: const [],
    );
  }
}

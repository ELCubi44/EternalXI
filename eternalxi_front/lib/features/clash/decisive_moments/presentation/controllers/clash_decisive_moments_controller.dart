import 'dart:math';

import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moment.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moments_engine.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moments_phase.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:flutter/foundation.dart';

/// Controlador del modo �Momentos decisivos� (partido resumido sin minicampo).
class ClashDecisiveMomentsController extends ChangeNotifier {
  ClashDecisiveMomentsController({Random? random, MatchChanceResolver? chance})
    : _chance = chance ?? RandomMatchChanceResolver(random ?? Random());

  final MatchChanceResolver _chance;

  String? _levelId;
  String? _rivalTeamName;
  List<ClashDecisiveMoment> _moments = ClashDecisiveMomentScript.defaultMoments;
  List<MatchSquadPlayer> _userSquad = const [];
  List<MatchSquadPlayer> _rivalSquad = const [];
  Map<String, ClashCardCatalogEntry> _catalogById = const {};

  int _momentIndex = 0;
  ClashDecisiveMomentsPhase _phase = ClashDecisiveMomentsPhase.intro;
  MatchScore _score = const MatchScore();
  MatchSquadPlayer? _selectedPlayer;
  MatchSquadPlayer? _rivalPlayer;
  ClashDuelResolution? _lastResolution;
  final List<String> _chronicle = [];

  String? get levelId => _levelId;
  String? get rivalTeamName => _rivalTeamName;
  List<ClashDecisiveMoment> get moments => _moments;
  List<MatchSquadPlayer> get userSquad => _userSquad;
  List<MatchSquadPlayer> get rivalSquad => _rivalSquad;
  Map<String, ClashCardCatalogEntry> get catalogById => _catalogById;
  int get momentIndex => _momentIndex;
  ClashDecisiveMomentsPhase get phase => _phase;
  MatchScore get score => _score;
  MatchSquadPlayer? get selectedPlayer => _selectedPlayer;
  MatchSquadPlayer? get rivalPlayer => _rivalPlayer;
  ClashDuelResolution? get lastResolution => _lastResolution;
  List<String> get chronicle => List.unmodifiable(_chronicle);

  ClashDecisiveMoment? get currentMoment =>
      _momentIndex < _moments.length ? _moments[_momentIndex] : null;

  double get progress =>
      _moments.isEmpty ? 0 : (_momentIndex + (_phase == finished ? 1 : 0)) / _moments.length;

  bool get isFinished => _phase == ClashDecisiveMomentsPhase.finished;

  bool get userWon =>
      _score.user > _score.rival ||
      (_score.user == _score.rival && _score.user > 0);

  static const finished = ClashDecisiveMomentsPhase.finished;

  void startMatch({
    required String levelId,
    ClashLineup7v7? lineup,
    Map<String, ClashCardCatalogEntry> catalogById = const {},
    List<MatchSquadPlayer>? rivalSquad,
    String? rivalTeamName,
    int rivalPower = 120,
  }) {
    _levelId = levelId;
    _rivalTeamName = rivalTeamName;
    _catalogById = catalogById;
    _userSquad = MatchSquadBuilder.buildUserSquad(
      lineup: lineup,
      catalogById: catalogById,
    );
    _rivalSquad =
        rivalSquad ?? MatchSquadBuilder.buildRivalSquad(basePower: rivalPower);
    _moments = ClashDecisiveMomentScript.defaultMoments;
    _momentIndex = 0;
    _phase = ClashDecisiveMomentsPhase.intro;
    _score = const MatchScore();
    _selectedPlayer = null;
    _rivalPlayer = null;
    _lastResolution = null;
    _chronicle.clear();
    notifyListeners();
  }

  void reset() {
    _levelId = null;
    _rivalTeamName = null;
    _momentIndex = 0;
    _phase = ClashDecisiveMomentsPhase.intro;
    _score = const MatchScore();
    _selectedPlayer = null;
    _rivalPlayer = null;
    _lastResolution = null;
    _chronicle.clear();
    notifyListeners();
  }

  void continueFromIntro() {
    if (_phase != ClashDecisiveMomentsPhase.intro) {
      return;
    }
    _phase = ClashDecisiveMomentsPhase.pickCard;
    notifyListeners();
  }

  void selectPlayer(int squadIndex) {
    if (_phase != ClashDecisiveMomentsPhase.pickCard) {
      return;
    }
    final moment = currentMoment;
    if (moment == null) {
      return;
    }

    final squad = moment.isUserAttacking ? _userSquad : _userSquad;
    if (squadIndex < 0 || squadIndex >= squad.length) {
      return;
    }

    _selectedPlayer = squad[squadIndex];
    _rivalPlayer = moment.isUserAttacking
        ? ClashDecisiveMomentsEngine.pickRivalDefender(
            rivalSquad: _rivalSquad,
            moment: moment,
          )
        : ClashDecisiveMomentsEngine.pickRivalAttacker(
            rivalSquad: _rivalSquad,
            moment: moment,
          );
    _phase = ClashDecisiveMomentsPhase.duel;
    notifyListeners();
  }

  void resolveDuel({String? techniqueId}) {
    final moment = currentMoment;
    final userCard = _selectedPlayer;
    final rivalCard = _rivalPlayer;
    if (_phase != ClashDecisiveMomentsPhase.duel ||
        moment == null ||
        userCard == null ||
        rivalCard == null) {
      return;
    }

    final userTechnique = ClashDuelTechniqueRules.findTechnique(
      userCard,
      techniqueId,
    );

    final attacker = moment.isUserAttacking ? userCard : rivalCard;
    final defender = moment.isUserAttacking ? rivalCard : userCard;

    final resolution = ClashDecisiveMomentsEngine.resolve(
      moment: moment,
      attacker: attacker,
      defender: defender,
      score: _score,
      chance: _chance,
      userTechnique: userTechnique,
      userIsDefender: !moment.isUserAttacking,
    );

    if (resolution.isGoal) {
      _score = _score.increment(resolution.attackerSide);
    }

    _lastResolution = resolution;
    _chronicle.add(ClashDecisiveMomentsEngine.chronicleFor(resolution));
    _phase = ClashDecisiveMomentsPhase.result;
    notifyListeners();
  }

  void continueFromResult() {
    if (_phase != ClashDecisiveMomentsPhase.result) {
      return;
    }

    _lastResolution = null;
    _selectedPlayer = null;
    _rivalPlayer = null;

    if (_momentIndex >= _moments.length - 1) {
      _phase = ClashDecisiveMomentsPhase.finished;
      notifyListeners();
      return;
    }

    _momentIndex++;
    _phase = ClashDecisiveMomentsPhase.intro;
    notifyListeners();
  }

  ClashCardCatalogEntry? catalogFor(MatchSquadPlayer player) =>
      _catalogById[player.cardId];

  List<MatchSquadPlayer> pickableSquadForCurrentMoment() {
    final moment = currentMoment;
    if (moment == null) {
      return const [];
    }
    return _userSquad;
  }

  bool isPreferredPick(MatchSquadPlayer player) {
    final moment = currentMoment;
    if (moment == null || moment.preferredPositions.isEmpty) {
      return false;
    }
    return moment.preferredPositions.contains(player.position);
  }

  /// Estado m�nimo compatible con recompensas de historia.
  MatchState buildFinalMatchState() {
    final events = <MatchEvent>[
      for (final line in _chronicle)
        MatchEvent(type: MatchEventType.duelSuccess, message: line),
    ];

    return MatchState(
      levelId: _levelId ?? 'decisive',
      status: MatchStatus.finished,
      score: _score,
      possession: MatchTeamSide.user,
      ballHolderIndex: 0,
      ballZone: currentMoment?.ballZone ?? MatchBallZone.midfield,
      userSquad: _userSquad,
      rivalSquad: _rivalSquad,
      pressure: 0,
      possessionRisk: 0,
      eventLog: events,
      matchInventory: const [],
    );
  }

  ClashDuelType? get currentDuelType => currentMoment?.duelType;
}

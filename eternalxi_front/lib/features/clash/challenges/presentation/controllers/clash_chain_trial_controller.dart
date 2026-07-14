import 'dart:math';

import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_chain_draw_engine.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial_line.dart';
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

/// Controlador de partido Cadena XI: robo por l�nea + duelos con supert�cnicas.
class ClashChainTrialController extends ChangeNotifier {
  ClashChainTrialController({Random? random, MatchChanceResolver? chance})
    : _random = random ?? Random(),
      _chance = chance ?? RandomMatchChanceResolver(random ?? Random());

  final Random _random;
  final MatchChanceResolver _chance;

  String? _trialId;
  String? _floorId;
  String? _rivalTeamName;
  ClashTrialLine? _trialLine;
  ClashTrialFloor? _floor;
  List<ClashDecisiveMoment> _moments = ClashDecisiveMomentScript.defaultMoments;
  List<MatchSquadPlayer> _userSquad = const [];
  List<MatchSquadPlayer> _rivalSquad = const [];
  List<MatchSquadPlayer> _drawCandidates = const [];
  Map<String, ClashCardCatalogEntry> _catalogById = const {};

  int _momentIndex = 0;
  ClashDecisiveMomentsPhase _phase = ClashDecisiveMomentsPhase.intro;
  MatchScore _score = const MatchScore();
  MatchSquadPlayer? _selectedPlayer;
  MatchSquadPlayer? _rivalPlayer;
  ClashDuelResolution? _lastResolution;
  final List<String> _chronicle = [];
  int _techniqueUses = 0;

  String? get trialId => _trialId;
  String? get floorId => _floorId;
  String? get rivalTeamName => _rivalTeamName;
  ClashTrialLine? get trialLine => _trialLine;
  ClashTrialFloor? get floor => _floor;
  List<ClashDecisiveMoment> get moments => _moments;
  List<MatchSquadPlayer> get userSquad => _userSquad;
  List<MatchSquadPlayer> get rivalSquad => _rivalSquad;
  List<MatchSquadPlayer> get drawCandidates => _drawCandidates;
  Map<String, ClashCardCatalogEntry> get catalogById => _catalogById;
  int get momentIndex => _momentIndex;
  ClashDecisiveMomentsPhase get phase => _phase;
  MatchScore get score => _score;
  MatchSquadPlayer? get selectedPlayer => _selectedPlayer;
  MatchSquadPlayer? get rivalPlayer => _rivalPlayer;
  ClashDuelResolution? get lastResolution => _lastResolution;
  List<String> get chronicle => List.unmodifiable(_chronicle);
  int get techniqueUses => _techniqueUses;

  ClashDecisiveMoment? get currentMoment =>
      _momentIndex < _moments.length ? _moments[_momentIndex] : null;

  double get progress => _moments.isEmpty
      ? 0
      : (_momentIndex + (_phase == ClashDecisiveMomentsPhase.finished ? 1 : 0)) /
            _moments.length;

  bool get isFinished => _phase == ClashDecisiveMomentsPhase.finished;

  bool get userWon =>
      _score.user > _score.rival ||
      (_score.user == _score.rival && _score.user > 0);

  int get techniqueBonusTarget => _floor?.techniqueBonusTarget ?? 0;

  bool get techniqueBonusAchieved =>
      techniqueBonusTarget > 0 && _techniqueUses >= techniqueBonusTarget;

  void startFloor({
    required String trialId,
    required ClashTrialFloor floor,
    required ClashTrialLine trialLine,
    ClashLineup7v7? lineup,
    Map<String, ClashCardCatalogEntry> catalogById = const {},
    List<MatchSquadPlayer>? rivalSquad,
    String? rivalTeamName,
    int rivalPower = 120,
  }) {
    _trialId = trialId;
    _floorId = floor.id;
    _floor = floor;
    _trialLine = trialLine;
    _rivalTeamName = rivalTeamName;
    _catalogById = catalogById;
    _userSquad = MatchSquadBuilder.buildUserSquad(
      lineup: lineup,
      catalogById: catalogById,
    );
    _rivalSquad =
        rivalSquad ?? MatchSquadBuilder.buildRivalSquad(basePower: rivalPower);
    _moments = floor.moments;
    _momentIndex = 0;
    _phase = ClashDecisiveMomentsPhase.intro;
    _score = const MatchScore();
    _selectedPlayer = null;
    _rivalPlayer = null;
    _lastResolution = null;
    _drawCandidates = const [];
    _techniqueUses = 0;
    _chronicle.clear();
    notifyListeners();
  }

  void reset() {
    _trialId = null;
    _floorId = null;
    _floor = null;
    _trialLine = null;
    _rivalTeamName = null;
    _momentIndex = 0;
    _phase = ClashDecisiveMomentsPhase.intro;
    _score = const MatchScore();
    _selectedPlayer = null;
    _rivalPlayer = null;
    _lastResolution = null;
    _drawCandidates = const [];
    _techniqueUses = 0;
    _chronicle.clear();
    notifyListeners();
  }

  void continueFromIntro() {
    if (_phase != ClashDecisiveMomentsPhase.intro) {
      return;
    }
    final moment = currentMoment;
    if (moment != null) {
      _rivalPlayer = moment.isUserAttacking
          ? ClashDecisiveMomentsEngine.pickRivalDefender(
              rivalSquad: _rivalSquad,
              moment: moment,
            )
          : ClashDecisiveMomentsEngine.pickRivalAttacker(
              rivalSquad: _rivalSquad,
              moment: moment,
            );
    }
    _refreshDrawCandidates();
    _phase = ClashDecisiveMomentsPhase.pickCard;
    notifyListeners();
  }

  void _refreshDrawCandidates() {
    final moment = currentMoment;
    final line = _trialLine;
    if (moment == null || line == null) {
      _drawCandidates = const [];
      return;
    }
    _drawCandidates = ClashChainDrawEngine.drawCandidates(
      squad: _userSquad,
      trialPositions: line.positions,
      preferredPositions: moment.preferredPositions,
      random: _random,
    );
  }

  void selectDrawnPlayer(int candidateIndex) {
    if (_phase != ClashDecisiveMomentsPhase.pickCard) {
      return;
    }
    final moment = currentMoment;
    if (moment == null) {
      return;
    }
    if (candidateIndex < 0 || candidateIndex >= _drawCandidates.length) {
      return;
    }

    _selectedPlayer = _drawCandidates[candidateIndex];
    if (moment != null) {
      _rivalPlayer = moment.isUserAttacking
          ? ClashDecisiveMomentsEngine.pickRivalDefender(
              rivalSquad: _rivalSquad,
              moment: moment,
            )
          : ClashDecisiveMomentsEngine.pickRivalAttacker(
              rivalSquad: _rivalSquad,
              moment: moment,
            );
    }
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
    if (userTechnique != null) {
      _techniqueUses++;
    }

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
    _drawCandidates = const [];

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

  bool isPreferredPick(MatchSquadPlayer player) {
    final moment = currentMoment;
    if (moment == null || moment.preferredPositions.isEmpty) {
      return false;
    }
    return moment.preferredPositions.contains(player.position);
  }

  bool hasStyleAdvantageAgainstRival(MatchSquadPlayer player) {
    final rival = _rivalPlayer;
    final moment = currentMoment;
    if (rival == null || moment == null) {
      return false;
    }
    return ClashChainDrawEngine.hasStyleAdvantage(
      userStyle: player.style,
      rivalStyle: rival.style,
      userIsAttacker: moment.isUserAttacking,
    );
  }

  MatchState buildFinalMatchState() {
    final events = <MatchEvent>[
      for (final line in _chronicle)
        MatchEvent(type: MatchEventType.duelSuccess, message: line),
    ];

    return MatchState(
      levelId: _floorId ?? 'chain-trial',
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

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

MatchSquadPlayer _player({
  required int index,
  required MatchTeamSide side,
  ClashPosition? position,
  int pass = 40,
  int dribble = 40,
  int defense = 40,
  int shot = 40,
  int save = 40,
  int power = 200,
  int stamina = 100,
  int pt = 10,
  String label = 'P',
  List<ClashSuperTechnique> techniques = const [],
}) {
  final pos = position ?? ClashPosition.values[index];
  final (x, y) = MatchPitchLayout.coordsForIndex(index, side);
  final stats = ClashStats(
    save: save,
    defense: defense,
    pass: pass,
    dribble: dribble,
    shot: shot,
    techniquePoints: pt,
    stamina: 100,
  );
  return MatchSquadPlayer(
    index: index,
    side: side,
    cardId: 'card-$index',
    playerId: index,
    position: pos,
    label: label,
    homeX: x,
    homeY: y,
    baseStats: stats,
    power: power,
    currentStamina: stamina,
    style: ClashPlayerStyle.valiente,
    superTechniques: techniques,
    maxPt: pt,
    currentPt: pt,
  );
}

ClashSuperTechnique _technique({
  required String id,
  required ClashTechniqueType type,
  int ptCost = 5,
  int power = 40,
}) {
  return ClashSuperTechnique(
    id: id,
    name: 'Técnica $id',
    description: 'Test',
    type: type,
    style: ClashPlayerStyle.valiente,
    basePower: power,
    ptCost: ptCost,
    level: ClashTechniqueLevel.normal,
  );
}

MatchState _rivalAdvanceState({
  MatchBallZone zone = MatchBallZone.ownMidfield,
  int holderIndex = 5,
  List<MatchSquadPlayer>? userSquad,
  List<MatchSquadPlayer>? rivalSquad,
}) {
  return MatchState(
    levelId: 'test',
    status: MatchStatus.playing,
    score: const MatchScore(),
    possession: MatchTeamSide.rival,
    ballHolderIndex: holderIndex,
    ballZone: zone,
    userSquad:
        userSquad ??
        List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            defense: 55,
            label: 'U${i + 1}',
          ),
        ),
    rivalSquad:
        rivalSquad ??
        List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            dribble: 70,
            label: 'R${i + 1}',
          ),
        ),
    pressure: 30,
    possessionRisk: 20,
    eventLog: const [],
    matchInventory: const [],
  );
}

MatchState _prepareManualDefense(MatchState state, {int? defenderIndex}) {
  final duel = state.activeDuel;
  if (duel?.needsDefenderSelection != true) {
    return state;
  }
  final index = defenderIndex ?? duel!.defenderCandidateIndices!.first;
  return ClashDuelEngine.selectUserDefender(state, index);
}

List<MatchSquadPlayer> _singleDefenderUserSquad({
  required MatchSquadPlayer defender,
}) {
  return List.generate(7, (i) {
    if (i == defender.index) {
      return defender;
    }
    return _player(
      index: i,
      side: MatchTeamSide.user,
      position: ClashPosition.striker,
      defense: 20,
      label: 'U${i + 1}',
    );
  });
}

void main() {
  group('Defensa manual dominio', () {
    test('rival avanza genera duelo pendiente de defensa manual', () {
      final defender = _player(
        index: 1,
        side: MatchTeamSide.user,
        position: ClashPosition.centreBack,
        defense: 55,
        label: 'U2',
      );
      final next = ClashDuelEngine.beginRivalAdvance(
        _rivalAdvanceState(
          userSquad: _singleDefenderUserSquad(defender: defender),
        ),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      expect(next.activeDuel, isNotNull);
      expect(next.activeDuel!.isUserDefending, isTrue);
      expect(
        next.activeDuel!.status,
        ClashDuelStatus.pendingUserDefensiveChoice,
      );
    });

    test('varios defensores requieren selección', () {
      final next = ClashDuelEngine.beginRivalAdvance(
        _rivalAdvanceState(zone: MatchBallZone.midfield),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      expect(next.activeDuel!.needsDefenderSelection, isTrue);
      expect(next.activeDuel!.defenderCandidateIndices, isNotNull);
      expect(next.activeDuel!.defenderCandidateIndices!.length, greaterThan(1));
    });

    test('seleccionar defensor crea duelo defensivo', () {
      final pending = ClashDuelEngine.beginRivalAdvance(
        _rivalAdvanceState(zone: MatchBallZone.midfield),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      final defenderIndex = pending.activeDuel!.defenderCandidateIndices!.last;

      final selected = ClashDuelEngine.selectUserDefender(
        pending,
        defenderIndex,
      );

      expect(
        selected.activeDuel!.status,
        ClashDuelStatus.pendingUserDefensiveChoice,
      );
      expect(selected.activeDuel!.defender.squadIndex, defenderIndex);
    });

    test('defensa normal resuelve y usuario recupera', () {
      final defender = _player(
        index: 1,
        side: MatchTeamSide.user,
        position: ClashPosition.centreBack,
        defense: 95,
        label: 'U2',
      );
      final pending = _prepareManualDefense(
        ClashDuelEngine.beginRivalAdvance(
          _rivalAdvanceState(
            userSquad: _singleDefenderUserSquad(defender: defender),
            rivalSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.rival,
                dribble: 20,
                label: 'R${i + 1}',
              ),
            ),
          ),
          const FixedMatchChanceResolver(alwaysSucceed: true),
        ),
      );

      final resolved = ClashDuelEngine.resolveManualDefense(
        pending,
        const FixedMatchChanceResolver(
          alwaysSucceed: false,
          coinFavorsUser: true,
        ),
      );

      expect(resolved.possession, MatchTeamSide.user);
      expect(resolved.activeDuel, isNull);
      expect(resolved.lastDuelResolution, isNotNull);
    });

    test('rival gana regate y avanza zona', () {
      final pending = ClashDuelEngine.beginRivalAdvance(
        _rivalAdvanceState(
          zone: MatchBallZone.midfield,
          userSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.user,
              defense: 10,
              label: 'U${i + 1}',
            ),
          ),
          rivalSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.rival,
              dribble: 95,
              label: 'R${i + 1}',
            ),
          ),
        ),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      final selected = pending.activeDuel!.needsDefenderSelection
          ? ClashDuelEngine.selectUserDefender(
              pending,
              pending.activeDuel!.defenderCandidateIndices!.first,
            )
          : pending;

      final resolved = ClashDuelEngine.resolveManualDefense(
        selected,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      expect(resolved.possession, MatchTeamSide.rival);
      expect(resolved.ballZone, MatchBallZone.ownMidfield);
    });

    test('supertécnica de Defensa resta PT', () {
      final defender = _player(
        index: 1,
        side: MatchTeamSide.user,
        position: ClashPosition.centreBack,
        defense: 80,
        pt: 10,
        label: 'U2',
        techniques: [
          _technique(id: 'def-1', type: ClashTechniqueType.defense, ptCost: 4),
        ],
      );
      final pending = ClashDuelEngine.beginRivalAdvance(
        _rivalAdvanceState(
          userSquad: _singleDefenderUserSquad(defender: defender),
        ),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      final resolved = ClashDuelEngine.resolveManualDefense(
        pending,
        const FixedMatchChanceResolver(alwaysSucceed: false),
        defenderChoice: const ClashDuelActionChoice.technique('def-1'),
      );

      final updatedDefender = resolved.userSquad.firstWhere(
        (p) => p.index == 1,
      );
      expect(updatedDefender.currentPt, 6);
    });

    test('rival tira genera parada manual', () {
      final state = MatchState(
        levelId: 'test',
        status: MatchStatus.playing,
        score: const MatchScore(),
        possession: MatchTeamSide.rival,
        ballHolderIndex: 6,
        ballZone: MatchBallZone.ownDefense,
        userSquad: List.generate(
          7,
          (i) => _player(index: i, side: MatchTeamSide.user, save: 60),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            shot: 80,
            label: 'R${i + 1}',
          ),
        ),
        pressure: 30,
        possessionRisk: 20,
        eventLog: const [],
        matchInventory: const [],
      );

      final pending = ClashDuelEngine.beginRivalShot(state);
      expect(pending.activeDuel!.type, ClashDuelType.shotVsSave);
      expect(
        pending.activeDuel!.status,
        ClashDuelStatus.pendingUserDefensiveChoice,
      );
    });

    test('parada normal devuelve posesión al usuario', () {
      final state = MatchState(
        levelId: 'test',
        status: MatchStatus.playing,
        score: const MatchScore(),
        possession: MatchTeamSide.rival,
        ballHolderIndex: 6,
        ballZone: MatchBallZone.ownDefense,
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            save: 90,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            shot: 40,
            label: 'R${i + 1}',
          ),
        ),
        pressure: 30,
        possessionRisk: 20,
        eventLog: const [],
        matchInventory: const [],
      );

      final pending = ClashDuelEngine.beginRivalShot(state);
      final resolved = ClashDuelEngine.resolveManualDefense(
        pending,
        const FixedMatchChanceResolver(alwaysSucceed: false),
      );

      expect(resolved.score.rival, 0);
      expect(resolved.possession, MatchTeamSide.user);
    });

    test('rival marca y marcador sube', () {
      final state = MatchState(
        levelId: 'test',
        status: MatchStatus.playing,
        score: const MatchScore(),
        possession: MatchTeamSide.rival,
        ballHolderIndex: 6,
        ballZone: MatchBallZone.ownDefense,
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            save: 5,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            shot: 95,
            label: 'R${i + 1}',
          ),
        ),
        pressure: 30,
        possessionRisk: 20,
        eventLog: const [],
        matchInventory: const [],
      );

      final pending = ClashDuelEngine.beginRivalShot(state);
      final resolved = ClashDuelEngine.resolveManualDefense(
        pending,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      expect(resolved.score.rival, 1);
      expect(resolved.possession, MatchTeamSide.user);
    });
  });

  group('Defensa manual UI', () {
    Widget _app(ClashMatchController match) {
      return ChangeNotifierProvider<ClashMatchController>.value(
        value: match,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  if (match.state != null) ClashMiniPitch(state: match.state!),
                  const ClashMatchDuelPanel(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('panel defensivo al avance rival', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final defender = _player(
        index: 1,
        side: MatchTeamSide.user,
        position: ClashPosition.centreBack,
        defense: 55,
        label: 'U2',
      );
      final match = ClashMatchController();
      final state = ClashDuelEngine.beginRivalAdvance(
        _rivalAdvanceState(
          userSquad: _singleDefenderUserSquad(defender: defender),
        ),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.setStateForTesting(state);

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      expect(find.text('Defiende el avance'), findsOneWidget);
      expect(find.text('Defensa normal'), findsOneWidget);
    });

    testWidgets('panel de parada al tiro rival', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final match = ClashMatchController();
      final pending = ClashDuelEngine.beginRivalShot(
        MatchState(
          levelId: 'test',
          status: MatchStatus.playing,
          score: const MatchScore(),
          possession: MatchTeamSide.rival,
          ballHolderIndex: 6,
          ballZone: MatchBallZone.ownDefense,
          userSquad: List.generate(
            7,
            (i) => _player(index: i, side: MatchTeamSide.user, save: 60),
          ),
          rivalSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.rival,
              shot: 80,
              label: 'R${i + 1}',
            ),
          ),
          pressure: 30,
          possessionRisk: 20,
          eventLog: const [],
          matchInventory: const [],
        ),
      );
      match.setStateForTesting(pending);

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      expect(find.text('Detén el tiro'), findsOneWidget);
      expect(find.text('Parada normal'), findsOneWidget);
    });
  });
}

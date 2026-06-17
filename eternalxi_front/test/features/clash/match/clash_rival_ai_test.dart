import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_action.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_technique_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_turn_panel.dart';
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

MatchState _rivalState({
  MatchBallZone zone = MatchBallZone.rivalMidfield,
  int holderIndex = 3,
  int pressure = 25,
  List<MatchSquadPlayer>? rivalSquad,
  List<MatchSquadPlayer>? userSquad,
  MatchScore score = const MatchScore(),
}) {
  return MatchState(
    levelId: 'test',
    status: MatchStatus.playing,
    score: score,
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
            defense: 30,
            label: 'U${i + 1}',
          ),
        ),
    rivalSquad:
        rivalSquad ??
        List.generate(
          7,
          (i) =>
              _player(index: i, side: MatchTeamSide.rival, label: 'R${i + 1}'),
        ),
    pressure: pressure,
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

void main() {
  group('ClashRivalAiEngine decide', () {
    test('IA tira cuando está en área', () {
      final state = _rivalState(
        zone: MatchBallZone.ownDefense,
        holderIndex: 6,
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            shot: 80,
            label: 'R${i + 1}',
          ),
        ),
      );

      final decision = ClashRivalAiEngine.decide(state);
      expect(decision.action, ClashRivalAiAction.shoot);
    });

    test('IA no tira fuera de área', () {
      final decision = ClashRivalAiEngine.decide(
        _rivalState(zone: MatchBallZone.midfield),
      );
      expect(decision.action, isNot(ClashRivalAiAction.shoot));
    });

    test('IA pasa si hay pase seguro y buena posición', () {
      final rivalSquad = List.generate(7, (i) {
        if (i == 3) {
          return _player(
            index: i,
            side: MatchTeamSide.rival,
            pass: 85,
            label: 'R4',
          );
        }
        if (i == 4) {
          return _player(
            index: i,
            side: MatchTeamSide.rival,
            pass: 70,
            power: 240,
            label: 'R5',
          );
        }
        return _player(index: i, side: MatchTeamSide.rival, label: 'R${i + 1}');
      });

      final decision = ClashRivalAiEngine.decide(
        _rivalState(
          zone: MatchBallZone.rivalMidfield,
          holderIndex: 3,
          rivalSquad: rivalSquad,
          userSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.user,
              defense: 15,
              label: 'U${i + 1}',
            ),
          ),
        ),
      );

      expect(decision.action, ClashRivalAiAction.pass);
      expect(decision.passTargetIndex, isNotNull);
    });

    test('IA evita pase largo malo defensa → delantero', () {
      final rivalSquad = List.generate(7, (i) {
        if (i == 0) {
          return _player(
            index: i,
            side: MatchTeamSide.rival,
            position: ClashPosition.goalkeeper,
            pass: 55,
            label: 'R1',
          );
        }
        if (i == 6) {
          return _player(
            index: i,
            side: MatchTeamSide.rival,
            position: ClashPosition.striker,
            power: 120,
            label: 'R7',
          );
        }
        return _player(
          index: i,
          side: MatchTeamSide.rival,
          pass: 55,
          label: 'R${i + 1}',
        );
      });

      final decision = ClashRivalAiEngine.decide(
        _rivalState(
          zone: MatchBallZone.rivalMidfield,
          holderIndex: 0,
          pressure: 70,
          rivalSquad: rivalSquad,
        ),
      );

      if (decision.action == ClashRivalAiAction.pass) {
        expect(decision.passTargetIndex, isNot(6));
      } else {
        expect(decision.action, ClashRivalAiAction.advance);
      }
    });

    test('IA avanza si no hay pase claro y puede progresar', () {
      final rivalSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.rival,
          pass: 1,
          dribble: 95,
          power: 120,
          label: 'R${i + 1}',
        ),
      );

      final decision = ClashRivalAiEngine.decide(
        _rivalState(
          zone: MatchBallZone.midfield,
          holderIndex: 5,
          pressure: 20,
          rivalSquad: rivalSquad,
        ),
      );

      expect(decision.action, ClashRivalAiAction.advance);
    });
  });

  group('ClashRivalAiEngine executeTurn', () {
    test('pase rival exitoso mantiene posesión rival', () {
      final state = _rivalState(
        zone: MatchBallZone.rivalMidfield,
        holderIndex: 3,
        rivalSquad: List.generate(7, (i) {
          if (i == 3) {
            return _player(
              index: i,
              side: MatchTeamSide.rival,
              pass: 90,
              label: 'R4',
            );
          }
          if (i == 4) {
            return _player(
              index: i,
              side: MatchTeamSide.rival,
              pass: 80,
              power: 250,
              label: 'R5',
            );
          }
          return _player(
            index: i,
            side: MatchTeamSide.rival,
            label: 'R${i + 1}',
          );
        }),
      );

      final decision = ClashRivalAiEngine.decide(state);
      expect(decision.action, ClashRivalAiAction.pass);

      final result = ClashRivalAiEngine.executeTurn(
        state,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      expect(result.state.possession, MatchTeamSide.rival);
      expect(result.state.ballHolderIndex, decision.passTargetIndex);
    });

    test('pase rival fallido da posesión al usuario', () {
      final state = _rivalState(
        zone: MatchBallZone.rivalMidfield,
        holderIndex: 3,
        rivalSquad: List.generate(7, (i) {
          if (i == 3) {
            return _player(
              index: i,
              side: MatchTeamSide.rival,
              pass: 90,
              label: 'R4',
            );
          }
          if (i == 4) {
            return _player(
              index: i,
              side: MatchTeamSide.rival,
              pass: 80,
              label: 'R5',
            );
          }
          return _player(
            index: i,
            side: MatchTeamSide.rival,
            label: 'R${i + 1}',
          );
        }),
      );

      final result = ClashRivalAiEngine.executeTurn(
        state,
        const FixedMatchChanceResolver(alwaysSucceed: false),
      );

      expect(result.state.possession, MatchTeamSide.user);
    });

    test('avance rival en zona libre progresa zona', () {
      final state = _rivalState(
        zone: MatchBallZone.rivalMidfield,
        holderIndex: 3,
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            dribble: 70,
            label: 'R${i + 1}',
          ),
        ),
      );

      final next = ClashDuelEngine.beginRivalAdvance(
        state,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      expect(next.activeDuel, isNull);
      expect(next.ballZone, MatchBallZone.midfield);
      expect(next.possession, MatchTeamSide.rival);
    });

    test('avance rival genera duelo cuando hay defensor usuario', () {
      final state = _rivalState(
        zone: MatchBallZone.ownMidfield,
        holderIndex: 5,
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            pass: 10,
            dribble: 70,
            label: 'R${i + 1}',
          ),
        ),
      );

      final pending = ClashDuelEngine.beginRivalAdvance(
        state,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      expect(pending.activeDuel, isNotNull);
      expect(pending.activeDuel!.type, ClashDuelType.dribbleVsDefense);
      expect(pending.activeDuel!.defender.teamSide, MatchTeamSide.user);
      expect(pending.activeDuel!.isUserDefending, isTrue);
    });

    test('avance rival perdido da posesión al usuario', () {
      final state = _rivalState(
        zone: MatchBallZone.ownMidfield,
        holderIndex: 5,
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            dribble: 10,
            label: 'R${i + 1}',
          ),
        ),
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            defense: 95,
            label: 'U${i + 1}',
          ),
        ),
      );

      final turn = _prepareManualDefense(
        ClashDuelEngine.beginRivalAdvance(
          state,
          const FixedMatchChanceResolver(alwaysSucceed: true),
        ),
      );
      expect(turn.activeDuel?.isUserDefending, isTrue);

      final resolved = ClashDuelEngine.resolveManualDefense(
        turn,
        const FixedMatchChanceResolver(
          alwaysSucceed: false,
          coinFavorsUser: true,
        ),
      );

      expect(resolved.possession, MatchTeamSide.user);
    });

    test('tiro rival puede acabar en gol', () {
      final state = _rivalState(
        zone: MatchBallZone.ownDefense,
        holderIndex: 6,
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            shot: 95,
            label: 'R${i + 1}',
          ),
        ),
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            save: 5,
            label: 'U${i + 1}',
          ),
        ),
      );

      final turn = ClashRivalAiEngine.executeTurn(
        state,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      expect(turn.state.activeDuel?.type, ClashDuelType.shotVsSave);

      final resolved = ClashDuelEngine.resolveManualDefense(
        turn.state,
        const FixedMatchChanceResolver(
          alwaysSucceed: true,
          coinFavorsUser: false,
        ),
      );

      expect(resolved.score.rival, 1);
      expect(resolved.possession, MatchTeamSide.user);
    });

    test('parada usuario cambia posesión al usuario', () {
      final state = _rivalState(
        zone: MatchBallZone.ownDefense,
        holderIndex: 6,
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            shot: 40,
            label: 'R${i + 1}',
          ),
        ),
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            save: 95,
            label: 'U${i + 1}',
          ),
        ),
      );

      final turn = ClashRivalAiEngine.executeTurn(
        state,
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );

      final resolved = ClashDuelEngine.resolveManualDefense(
        turn.state,
        const FixedMatchChanceResolver(
          alwaysSucceed: false,
          coinFavorsUser: true,
        ),
      );

      expect(resolved.score.rival, 0);
      expect(resolved.possession, MatchTeamSide.user);
      expect(
        resolved.eventLog.any((e) => e.type == MatchEventType.saveMade),
        isTrue,
      );
    });
  });

  group('ClashRivalTechniqueSelector', () {
    test('IA usa supertécnica si tiene PT y mejora score', () {
      final player = _player(
        index: 6,
        side: MatchTeamSide.rival,
        shot: 50,
        pt: 10,
        techniques: [
          _technique(id: 'shot-1', type: ClashTechniqueType.shot, power: 50),
        ],
      );

      final choice = ClashRivalTechniqueSelector.selectAttacker(
        player: player,
        duelType: ClashDuelType.shotVsSave,
        effectiveBaseStat: player.effectiveShot,
        opponentStyle: ClashPlayerStyle.valiente,
        ballZone: MatchBallZone.ownDefense,
      );

      expect(choice.usesTechnique, isTrue);
    });

    test('IA no usa supertécnica si no tiene PT', () {
      final player = _player(
        index: 6,
        side: MatchTeamSide.rival,
        shot: 50,
        pt: 0,
        techniques: [
          _technique(id: 'shot-1', type: ClashTechniqueType.shot, ptCost: 5),
        ],
      );

      final choice = ClashRivalTechniqueSelector.selectAttacker(
        player: player,
        duelType: ClashDuelType.shotVsSave,
        effectiveBaseStat: player.effectiveShot,
        opponentStyle: ClashPlayerStyle.valiente,
        ballZone: MatchBallZone.ownDefense,
      );

      expect(choice.isNormal, isTrue);
    });

    test('IA no gasta técnica innecesaria si va sobrada', () {
      final player = _player(
        index: 5,
        side: MatchTeamSide.rival,
        dribble: 90,
        pt: 10,
        techniques: [
          _technique(id: 'drib-1', type: ClashTechniqueType.dribble, power: 12),
        ],
      );

      final choice = ClashRivalTechniqueSelector.selectAttacker(
        player: player,
        duelType: ClashDuelType.dribbleVsDefense,
        effectiveBaseStat: player.effectiveDribble,
        opponentStyle: ClashPlayerStyle.valiente,
        ballZone: MatchBallZone.midfield,
        score: const MatchScore(user: 0, rival: 2),
        playerSide: MatchTeamSide.rival,
      );

      expect(choice.isNormal, isTrue);
    });
  });

  group('UI turno rival', () {
    void _tallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
    }

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
                  ClashMiniPitch(state: match.state!),
                  const ClashMatchRivalTurnPanel(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('muestra Continuar acción rival con posesión rival', (
      tester,
    ) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final match = ClashMatchController();
      match.setStateForTesting(_rivalState());

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      expect(find.text('Turno rival'), findsOneWidget);
      expect(find.text('Continuar acción rival'), findsOneWidget);
    });

    testWidgets('pulsar botón ejecuta acción real', (tester) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.setStateForTesting(
        _rivalState(
          zone: MatchBallZone.rivalMidfield,
          rivalSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.rival,
              pass: 10,
              dribble: 90,
              label: 'R${i + 1}',
            ),
          ),
        ),
      );

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar acción rival'));
      await tester.pumpAndSettle();

      expect(match.lastRivalAiDecision, isNotNull);
      expect(
        match.state!.eventLog.any((e) => e.message.contains('Rival')),
        isTrue,
      );
    });

    testWidgets('si usuario recupera desaparece panel rival', (tester) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: false),
      );
      match.setStateForTesting(
        _rivalState(
          rivalSquad: List.generate(7, (i) {
            if (i == 3) {
              return _player(
                index: i,
                side: MatchTeamSide.rival,
                pass: 90,
                label: 'R4',
              );
            }
            if (i == 4) {
              return _player(
                index: i,
                side: MatchTeamSide.rival,
                pass: 80,
                label: 'R5',
              );
            }
            return _player(
              index: i,
              side: MatchTeamSide.rival,
              label: 'R${i + 1}',
            );
          }),
        ),
      );

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar acción rival'));
      await tester.pumpAndSettle();

      expect(match.state!.possession, MatchTeamSide.user);
      expect(find.text('Turno rival'), findsNothing);
    });
  });
}

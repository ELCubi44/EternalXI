import 'dart:math';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_pass_sheet.dart';
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
  int power = 200,
  int stamina = 100,
  String label = 'P',
  ClashPlayerStyle style = ClashPlayerStyle.valiente,
}) {
  final pos = position ?? ClashPosition.values[index];
  final (x, y) = MatchPitchLayout.coordsForIndex(index, side);
  final stats = ClashStats(
    save: 20,
    defense: defense,
    pass: pass,
    dribble: dribble,
    shot: 30,
    techniquePoints: 10,
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
    style: style,
    superTechniques: const [],
    maxPt: 10,
    currentPt: 10,
  );
}

MatchState _stateWith({
  int holderIndex = 3,
  MatchBallZone zone = MatchBallZone.ownMidfield,
  int pressure = 25,
  List<MatchSquadPlayer>? userSquad,
}) {
  final squad =
      userSquad ??
      List.generate(
        7,
        (i) => _player(index: i, side: MatchTeamSide.user, label: 'U${i + 1}'),
      );
  return MatchState(
    levelId: 'test',
    status: MatchState.testing().status,
    score: MatchState.testing().score,
    possession: MatchTeamSide.user,
    ballHolderIndex: holderIndex,
    ballZone: zone,
    userSquad: squad,
    rivalSquad: List.generate(
      7,
      (i) => _player(
        index: i,
        side: MatchTeamSide.rival,
        defense: 35,
        label: 'R${i + 1}',
      ),
    ),
    pressure: pressure,
    possessionRisk: 20,
    eventLog: const [],
    matchInventory: const [],
  );
}

void main() {
  group('MatchPossessionMath', () {
    test('pase corto tiene porcentaje alto', () {
      final passer = _player(index: 3, side: MatchTeamSide.user, pass: 55);
      final receiver = _player(index: 4, side: MatchTeamSide.user, power: 220);
      final percent = MatchPossessionMath.passSuccessPercent(
        passer: passer,
        receiver: receiver,
        ballZone: MatchBallZone.ownMidfield,
        pressure: 20,
        rivalDefenseQuality: 35,
      );
      expect(percent, greaterThan(70));
      expect(percent, lessThanOrEqualTo(95));
    });

    test('pase defensa a delantero es bajo', () {
      final passer = _player(
        index: 1,
        side: MatchTeamSide.user,
        position: ClashPosition.centreBack,
        pass: 40,
      );
      final receiver = _player(
        index: 6,
        side: MatchTeamSide.user,
        position: ClashPosition.striker,
        power: 180,
      );
      final shortPass = MatchPossessionMath.passSuccessPercent(
        passer: passer,
        receiver: _player(index: 2, side: MatchTeamSide.user, pass: 40),
        ballZone: MatchBallZone.ownDefense,
        pressure: 20,
        rivalDefenseQuality: 40,
      );
      final longPass = MatchPossessionMath.passSuccessPercent(
        passer: passer,
        receiver: receiver,
        ballZone: MatchBallZone.ownDefense,
        pressure: 20,
        rivalDefenseQuality: 40,
      );
      expect(longPass, lessThan(shortPass));
      expect(longPass, lessThan(55));
    });

    test('presión reduce pase', () {
      final passer = _player(index: 4, side: MatchTeamSide.user, pass: 50);
      final receiver = _player(index: 5, side: MatchTeamSide.user);
      final low = MatchPossessionMath.passSuccessPercent(
        passer: passer,
        receiver: receiver,
        ballZone: MatchBallZone.midfield,
        pressure: 15,
        rivalDefenseQuality: 35,
      );
      final high = MatchPossessionMath.passSuccessPercent(
        passer: passer,
        receiver: receiver,
        ballZone: MatchBallZone.midfield,
        pressure: 75,
        rivalDefenseQuality: 35,
      );
      expect(high, lessThan(low));
    });

    test('avanzar cerca del área rival es más difícil', () {
      final carrier = _player(index: 5, side: MatchTeamSide.user, dribble: 50);
      final midfield = MatchPossessionMath.advanceSuccessPercent(
        carrier: carrier,
        ballZone: MatchBallZone.midfield,
        pressure: 30,
        rivalDefenseQuality: 35,
      );
      final area = MatchPossessionMath.advanceSuccessPercent(
        carrier: carrier,
        ballZone: MatchBallZone.rivalArea,
        pressure: 30,
        rivalDefenseQuality: 35,
      );
      expect(area, lessThan(midfield));
    });

    test('porcentaje siempre entre 5 y 95', () {
      final weak = _player(
        index: 0,
        side: MatchTeamSide.user,
        pass: 5,
        dribble: 5,
      );
      final strong = _player(
        index: 6,
        side: MatchTeamSide.user,
        pass: 99,
        dribble: 99,
        power: 400,
      );
      final low = MatchPossessionMath.passSuccessPercent(
        passer: weak,
        receiver: weak,
        ballZone: MatchBallZone.rivalArea,
        pressure: 95,
        rivalDefenseQuality: 90,
      );
      final high = MatchPossessionMath.advanceSuccessPercent(
        carrier: strong,
        ballZone: MatchBallZone.ownDefense,
        pressure: 5,
        rivalDefenseQuality: 10,
      );
      expect(low, greaterThanOrEqualTo(5));
      expect(high, lessThanOrEqualTo(95));
    });

    test('resistencia menor a 100 penaliza pase efectivo', () {
      const stats = ClashStats(
        save: 10,
        defense: 10,
        pass: 50,
        dribble: 50,
        shot: 10,
        techniquePoints: 10,
        stamina: 100,
      );
      expect(stats.effectivePass(100), 50);
      expect(stats.effectivePass(80), lessThan(50));
    });
  });

  group('MatchPossessionEngine', () {
    const succeed = FixedMatchChanceResolver(alwaysSucceed: true);
    const fail = FixedMatchChanceResolver(alwaysSucceed: false);

    test('éxito de pase cambia poseedor', () {
      final state = _stateWith(holderIndex: 3);
      final next = MatchPossessionEngine.executePass(state, 4, succeed);
      expect(next.ballHolderIndex, 4);
      expect(next.possession, MatchTeamSide.user);
      expect(next.eventLog.last.type, MatchEventType.passSuccess);
    });

    test('fallo de pase cambia posesión', () {
      final state = _stateWith(holderIndex: 3);
      final next = MatchPossessionEngine.executePass(state, 4, fail);
      expect(next.possession, MatchTeamSide.rival);
      expect(next.eventLog.last.type, MatchEventType.passFail);
    });

    test('avanzar sube zona si éxito', () {
      final state = _stateWith(holderIndex: 4, zone: MatchBallZone.midfield);
      final next = MatchPossessionEngine.executeAdvance(state, succeed);
      expect(next.ballZone, MatchBallZone.rivalMidfield);
      expect(next.possession, MatchTeamSide.user);
    });

    test('avanzar falla y cambia posesión', () {
      final state = _stateWith(zone: MatchBallZone.midfield);
      final next = MatchPossessionEngine.executeAdvance(state, fail);
      expect(next.possession, MatchTeamSide.rival);
      expect(next.eventLog.last.type, MatchEventType.advanceFail);
    });

    test('resistencia baja al pasar', () {
      final state = _stateWith(holderIndex: 3);
      final before = state.ballHolderPlayer()!.currentStamina;
      final next = MatchPossessionEngine.executePass(state, 4, succeed);
      final after = next.userSquad[3].currentStamina;
      expect(after, before - MatchPossessionEngine.passStaminaCost);
    });

    test('resistencia baja más al avanzar', () {
      final state = _stateWith(holderIndex: 4);
      final before = state.ballHolderPlayer()!.currentStamina;
      final next = MatchPossessionEngine.executeAdvance(state, succeed);
      final after = next.userSquad[4].currentStamina;
      expect(before - after, MatchPossessionEngine.advanceStaminaCost);
      expect(
        MatchPossessionEngine.advanceStaminaCost,
        greaterThan(MatchPossessionEngine.passStaminaCost),
      );
    });
  });

  group('UI posesión', () {
    Widget _app(ClashMatchController match, Widget child) {
      return ChangeNotifierProvider<ClashMatchController>.value(
        value: match,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      );
    }

    testWidgets('panel muestra Pasar y Avanzar con posesión usuario', (
      tester,
    ) async {
      final match = ClashMatchController(
        random: Random(1),
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.user);

      await tester.pumpWidget(_app(match, const _UserPossessionActionsProbe()));
      await tester.pumpAndSettle();

      expect(find.text('Pasar'), findsOneWidget);
      expect(find.text('Avanzar'), findsOneWidget);
    });

    testWidgets('abrir lista de pases muestra compañeros y porcentajes', (
      tester,
    ) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.user);

      await tester.pumpWidget(
        _app(
          match,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showClashMatchPassSheet(context),
                  child: const Text('Abrir pases'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir pases'));
      await tester.pumpAndSettle();

      expect(find.text('Elegir compañero'), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('ejecutar pase exitoso actualiza jugador con balón', (
      tester,
    ) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.user);
      final options = match.passOptions;
      expect(options, isNotEmpty);

      match.passTo(options.first.targetIndex);
      expect(match.state!.ballHolderIndex, options.first.targetIndex);
    });

    testWidgets('acción rival visible con posesión rival', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.rival);

      await tester.pumpWidget(
        _app(match, const _RivalPossessionActionsProbe()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar acción rival'), findsOneWidget);
    });

    testWidgets('minicampo destaca poseedor', (tester) async {
      final state = _stateWith(holderIndex: 3);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClashMiniPitch(state: state)),
        ),
      );
      expect(find.text('U4'), findsOneWidget);
      expect(find.byType(ClashMiniPitch), findsOneWidget);
    });

    test('historial registra pase exitoso', () {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.user);
      final target = match.passOptions.first.targetIndex;
      match.passTo(target);

      expect(
        match.state!.eventLog.any((e) => e.message.contains('Pase exitoso')),
        isTrue,
      );
    });
  });
}

class _UserPossessionActionsProbe extends StatelessWidget {
  const _UserPossessionActionsProbe();

  @override
  Widget build(BuildContext context) {
    final match = context.watch<ClashMatchController>();
    final state = match.state;
    if (state == null || state.possession != MatchTeamSide.user) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      body: Row(
        children: [
          FilledButton(
            onPressed: () => showClashMatchPassSheet(context),
            child: const Text('Pasar'),
          ),
          FilledButton(onPressed: match.advance, child: const Text('Avanzar')),
        ],
      ),
    );
  }
}

class _RivalPossessionActionsProbe extends StatelessWidget {
  const _RivalPossessionActionsProbe();

  @override
  Widget build(BuildContext context) {
    final match = context.watch<ClashMatchController>();
    final state = match.state;
    if (state == null || state.possession != MatchTeamSide.rival) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      body: FilledButton(
        onPressed: match.continueRivalTurn,
        child: const Text('Continuar acción rival'),
      ),
    );
  }
}

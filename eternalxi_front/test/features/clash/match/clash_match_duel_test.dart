import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
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
  int dribble = 40,
  int defense = 40,
  int stamina = 100,
  String label = 'P',
  ClashPlayerStyle style = ClashPlayerStyle.valiente,
}) {
  final pos = position ?? ClashPosition.values[index];
  final (x, y) = MatchPitchLayout.coordsForIndex(index, side);
  final stats = ClashStats(
    save: 20,
    defense: defense,
    pass: 40,
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
    style: style,
    label: label,
    homeX: x,
    homeY: y,
    baseStats: stats,
    power: 200,
    currentStamina: stamina,
  );
}

MatchState _stateWith({
  int holderIndex = 5,
  MatchBallZone zone = MatchBallZone.midfield,
  List<MatchSquadPlayer>? userSquad,
  List<MatchSquadPlayer>? rivalSquad,
}) {
  return MatchState(
    levelId: 'test',
    status: MatchStatus.playing,
    score: MatchState.testing().score,
    possession: MatchTeamSide.user,
    ballHolderIndex: holderIndex,
    ballZone: zone,
    userSquad:
        userSquad ??
        List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            dribble: 55,
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
            defense: 30,
            label: 'R${i + 1}',
          ),
        ),
    pressure: 25,
    possessionRisk: 20,
    eventLog: const [],
  );
}

void main() {
  const succeed = FixedMatchChanceResolver(alwaysSucceed: true);

  group('ClashDuelDefenderSelector', () {
    test('selecciona mediocentro en zona midfield', () {
      final state = _stateWith(zone: MatchBallZone.midfield);
      final attacker = state.ballHolderPlayer()!;
      final defender = ClashDuelDefenderSelector.selectForAdvance(
        state,
        attacker,
      );
      expect(defender?.position, ClashPosition.defensiveMidfielder);
    });

    test('selecciona defensa central en área rival', () {
      final state = _stateWith(zone: MatchBallZone.rivalArea, holderIndex: 6);
      final attacker = state.ballHolderPlayer()!;
      final defender = ClashDuelDefenderSelector.selectForAdvance(
        state,
        attacker,
      );
      expect(defender?.position, ClashPosition.centreBack);
    });

    test('no hay defensor en medio propio', () {
      final state = _stateWith(zone: MatchBallZone.ownMidfield);
      final attacker = state.ballHolderPlayer()!;
      expect(
        ClashDuelDefenderSelector.selectForAdvance(state, attacker),
        isNull,
      );
    });
  });

  group('ClashDuelEngine', () {
    test('avanzar crea duelo pendiente cuando hay defensor', () {
      final state = _stateWith(zone: MatchBallZone.midfield);
      final next = ClashDuelEngine.beginAdvance(state, succeed);
      expect(next.activeDuel, isNotNull);
      expect(next.activeDuel!.isPending, isTrue);
      expect(next.eventLog.last.type, MatchEventType.duelStarted);
    });

    test('fallback de avance libre sin defensor cercano', () {
      final state = _stateWith(zone: MatchBallZone.ownMidfield);
      final next = ClashDuelEngine.beginAdvance(state, succeed);
      expect(next.activeDuel, isNull);
      expect(next.ballZone, MatchBallZone.midfield);
    });

    test('atacante gana y avanza zona', () {
      final userSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.user,
          dribble: 90,
          label: 'U${i + 1}',
        ),
      );
      final rivalSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.rival,
          defense: 5,
          label: 'R${i + 1}',
        ),
      );
      final state = _stateWith(
        zone: MatchBallZone.midfield,
        userSquad: userSquad,
        rivalSquad: rivalSquad,
      );
      final pending = ClashDuelEngine.beginAdvance(state, succeed);
      final resolved = ClashDuelEngine.resolveNormalDribble(
        pending,
        succeed,
        attackerVariance: 0,
        defenderVariance: 0,
      );
      expect(resolved.ballZone, MatchBallZone.rivalMidfield);
      expect(resolved.possession, MatchTeamSide.user);
      expect(resolved.lastDuelResolution?.winner, MatchTeamSide.user);
    });

    test('defensor gana y recupera posesión', () {
      final userSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.user,
          dribble: 5,
          label: 'U${i + 1}',
        ),
      );
      final rivalSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.rival,
          defense: 90,
          label: 'R${i + 1}',
        ),
      );
      final state = _stateWith(
        zone: MatchBallZone.midfield,
        userSquad: userSquad,
        rivalSquad: rivalSquad,
      );
      final pending = ClashDuelEngine.beginAdvance(state, succeed);
      final resolved = ClashDuelEngine.resolveNormalDribble(
        pending,
        succeed,
        attackerVariance: 0,
        defenderVariance: 0,
      );
      expect(resolved.possession, MatchTeamSide.rival);
      expect(resolved.lastDuelResolution?.winner, MatchTeamSide.rival);
    });

    test('empate exacto usa moneda a favor del usuario', () {
      final attacker = ClashDuelParticipant(
        teamSide: MatchTeamSide.user,
        cardId: 'a',
        playerId: 1,
        position: ClashPosition.striker,
        style: ClashPlayerStyle.valiente,
        label: 'A',
        squadIndex: 6,
        baseStat: 50,
        effectiveStat: 50,
        stamina: 100,
        power: 200,
      );
      final defender = ClashDuelParticipant(
        teamSide: MatchTeamSide.rival,
        cardId: 'd',
        playerId: 2,
        position: ClashPosition.centreBack,
        style: ClashPlayerStyle.valiente,
        label: 'D',
        squadIndex: 1,
        baseStat: 50,
        effectiveStat: 50,
        stamina: 100,
        power: 200,
      );
      final resolution = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        attackerStyleResult: ClashDuelStyleResult.neutral,
        ballZone: MatchBallZone.ownMidfield,
        pressure: 0,
        chance: const FixedMatchChanceResolver(
          alwaysSucceed: true,
          coinFavorsUser: true,
        ),
      );
      expect(resolution.resolvedByCoin, isTrue);
      expect(resolution.winner, MatchTeamSide.user);
    });

    test('empate exacto usa moneda a favor del rival', () {
      final attacker = ClashDuelParticipant(
        teamSide: MatchTeamSide.user,
        cardId: 'a',
        playerId: 1,
        position: ClashPosition.striker,
        style: ClashPlayerStyle.valiente,
        label: 'A',
        squadIndex: 6,
        baseStat: 50,
        effectiveStat: 50,
        stamina: 100,
        power: 200,
      );
      final defender = ClashDuelParticipant(
        teamSide: MatchTeamSide.rival,
        cardId: 'd',
        playerId: 2,
        position: ClashPosition.centreBack,
        style: ClashPlayerStyle.valiente,
        label: 'D',
        squadIndex: 1,
        baseStat: 50,
        effectiveStat: 50,
        stamina: 100,
        power: 200,
      );
      final resolution = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        attackerStyleResult: ClashDuelStyleResult.neutral,
        ballZone: MatchBallZone.ownMidfield,
        pressure: 0,
        chance: const FixedMatchChanceResolver(
          alwaysSucceed: true,
          coinFavorsUser: false,
        ),
      );
      expect(resolution.resolvedByCoin, isTrue);
      expect(resolution.winner, MatchTeamSide.rival);
    });

    test('resistencia baja tras duelo', () {
      final state = _stateWith(zone: MatchBallZone.midfield);
      final pending = ClashDuelEngine.beginAdvance(state, succeed);
      final attackerIndex = pending.activeDuel!.attacker.squadIndex;
      final defenderIndex = pending.activeDuel!.defender.squadIndex;
      final attackerStaminaBefore =
          pending.userSquad[attackerIndex].currentStamina;
      final defenderStaminaBefore =
          pending.rivalSquad[defenderIndex].currentStamina;

      final resolved = ClashDuelEngine.resolveNormalDribble(
        pending,
        succeed,
        attackerVariance: 20,
        defenderVariance: -20,
      );

      expect(
        resolved.userSquad[attackerIndex].currentStamina,
        attackerStaminaBefore - MatchPossessionEngine.advanceStaminaCost,
      );
      expect(
        resolved.rivalSquad[defenderIndex].currentStamina,
        defenderStaminaBefore - ClashDuelEngine.defenderStaminaCost,
      );
    });

    test('historial registra superación o freno', () {
      final state = _stateWith(zone: MatchBallZone.midfield);
      final pending = ClashDuelEngine.beginAdvance(state, succeed);
      final resolved = ClashDuelEngine.resolveNormalDribble(
        pending,
        succeed,
        attackerVariance: 20,
        defenderVariance: -20,
      );
      final hasOutcome = resolved.eventLog.any(
        (event) =>
            event.type == MatchEventType.duelSuccess ||
            event.type == MatchEventType.duelFail,
      );
      expect(hasOutcome, isTrue);
      expect(resolved.lastDuelResolution?.eventText, isNotEmpty);
    });
  });

  group('ClashDuelMath', () {
    test('regate efectivo usa resistencia', () {
      final fresh = _player(
        index: 5,
        side: MatchTeamSide.user,
        dribble: 50,
        stamina: 100,
      );
      final tired = fresh.copyWith(currentStamina: 60);
      expect(fresh.effectiveDribble, greaterThan(tired.effectiveDribble));
    });

    test('defensa efectiva usa resistencia', () {
      final fresh = _player(
        index: 1,
        side: MatchTeamSide.rival,
        defense: 50,
        stamina: 100,
      );
      final tired = fresh.copyWith(currentStamina: 60);
      expect(fresh.effectiveDefense, greaterThan(tired.effectiveDefense));
    });

    test('ventaja de estilo aumenta puntuación del atacante', () {
      final attacker = ClashDuelParticipant(
        teamSide: MatchTeamSide.user,
        cardId: 'a',
        playerId: 1,
        position: ClashPosition.striker,
        style: ClashPlayerStyle.picaro,
        label: 'A',
        squadIndex: 6,
        baseStat: 40,
        effectiveStat: 40,
        stamina: 100,
        power: 200,
      );
      final defender = ClashDuelParticipant(
        teamSide: MatchTeamSide.rival,
        cardId: 'd',
        playerId: 2,
        position: ClashPosition.centreBack,
        style: ClashPlayerStyle.potente,
        label: 'D',
        squadIndex: 1,
        baseStat: 40,
        effectiveStat: 40,
        stamina: 100,
        power: 200,
      );
      final withAdvantage = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        attackerStyleResult: ClashDuelStyleResult.advantage,
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: succeed,
      );
      final neutral = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        attackerStyleResult: ClashDuelStyleResult.neutral,
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: succeed,
      );
      expect(
        withAdvantage.attackerScore,
        neutral.attackerScore + ClashDuelMath.styleAdvantageBonus,
      );
      expect(withAdvantage.styleBonusApplied, isTrue);
    });
  });

  group('UI duelo', () {
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

    testWidgets('pulsa Avanzar muestra panel de duelo', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(_stateWith(zone: MatchBallZone.midfield));

      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );

      match.advance();
      await tester.pumpAndSettle();

      expect(find.text('Duelo'), findsOneWidget);
      expect(find.text('Regate normal'), findsOneWidget);
    });

    testWidgets('panel muestra atacante y defensor con estilos', (
      tester,
    ) async {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      final userSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.user,
          style: i == 5 ? ClashPlayerStyle.picaro : ClashPlayerStyle.valiente,
          label: 'U${i + 1}',
        ),
      );
      final rivalSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.rival,
          style: i == 3 ? ClashPlayerStyle.potente : ClashPlayerStyle.valiente,
          label: 'R${i + 1}',
        ),
      );
      match.setStateForTesting(
        ClashDuelEngine.beginAdvance(
          _stateWith(
            zone: MatchBallZone.midfield,
            userSquad: userSquad,
            rivalSquad: rivalSquad,
          ),
          succeed,
        ),
      );

      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('U6'), findsWidgets);
      expect(find.text('R4'), findsWidgets);
      expect(find.text('Ventaja de estilo'), findsOneWidget);
    });

    testWidgets('Regate normal resuelve y permite continuar', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        ClashDuelEngine.beginAdvance(
          _stateWith(zone: MatchBallZone.midfield),
          succeed,
        ),
      );

      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regate normal'));
      await tester.pumpAndSettle();

      expect(find.text('Continuar'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(match.state!.lastDuelResolution, isNull);
    });

    testWidgets('al ganar atacante vuelve a acciones normales', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        ClashDuelEngine.beginAdvance(
          _stateWith(
            zone: MatchBallZone.midfield,
            userSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.user,
                dribble: 90,
                label: 'U${i + 1}',
              ),
            ),
            rivalSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.rival,
                defense: 5,
                label: 'R${i + 1}',
              ),
            ),
          ),
          succeed,
        ),
      );

      await tester.pumpWidget(
        _app(
          match,
          const Scaffold(body: ClashMatchDuelPanel()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regate normal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(match.state!.possession, MatchTeamSide.user);
      expect(match.state!.hasPendingDuel, isFalse);
      expect(match.state!.lastDuelResolution, isNull);
    });

    testWidgets('al perder atacante cambia posesión', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      final pending = ClashDuelEngine.beginAdvance(
        _stateWith(
          zone: MatchBallZone.midfield,
          userSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.user,
              dribble: 5,
              label: 'U${i + 1}',
            ),
          ),
          rivalSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.rival,
              defense: 90,
              label: 'R${i + 1}',
            ),
          ),
        ),
        succeed,
      );
      match.setStateForTesting(pending);

      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regate normal'));
      await tester.pumpAndSettle();

      expect(match.state!.possession, MatchTeamSide.rival);
    });

    testWidgets('minicampo destaca duelo', (tester) async {
      final state = ClashDuelEngine.beginAdvance(
        _stateWith(zone: MatchBallZone.midfield),
        succeed,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClashMiniPitch(state: state)),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('U6'), findsOneWidget);
      expect(find.text('R4'), findsOneWidget);
    });
  });
}

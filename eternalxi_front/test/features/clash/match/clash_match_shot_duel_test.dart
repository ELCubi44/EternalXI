import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_defender_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
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
  int shot = 40,
  int save = 40,
  int stamina = 100,
  String label = 'P',
  ClashPlayerStyle style = ClashPlayerStyle.valiente,
  List<ClashSuperTechnique> superTechniques = const [],
  int techniquePoints = 10,
  int currentPt = 10,
}) {
  final pos = position ?? ClashPosition.values[index];
  final (x, y) = MatchPitchLayout.coordsForIndex(index, side);
  final stats = ClashStats(
    save: save,
    defense: defense,
    pass: 40,
    dribble: dribble,
    shot: shot,
    techniquePoints: techniquePoints,
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
    superTechniques: superTechniques,
    maxPt: techniquePoints,
    currentPt: currentPt,
  );
}

MatchState _stateWith({
  int holderIndex = 6,
  MatchBallZone zone = MatchBallZone.rivalArea,
  MatchTeamSide possession = MatchTeamSide.user,
  MatchScore score = const MatchScore(),
  List<MatchSquadPlayer>? userSquad,
  List<MatchSquadPlayer>? rivalSquad,
}) {
  return MatchState(
    levelId: 'test',
    status: MatchStatus.playing,
    score: score,
    possession: possession,
    ballHolderIndex: holderIndex,
    ballZone: zone,
    userSquad:
        userSquad ??
        List.generate(
          7,
          (i) =>
              _player(index: i, side: MatchTeamSide.user, label: 'U${i + 1}'),
        ),
    rivalSquad:
        rivalSquad ??
        List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            save: 30,
            label: 'R${i + 1}',
          ),
        ),
    pressure: 25,
    possessionRisk: 20,
    eventLog: const [],
    matchInventory: const [],
  );
}

void main() {
  const succeed = FixedMatchChanceResolver(alwaysSucceed: true);

  group('ClashDuelEngine shot', () {
    test('tirar no disponible fuera de rivalArea', () {
      final state = _stateWith(zone: MatchBallZone.midfield);
      expect(ClashDuelEngine.canShoot(state), isFalse);
    });

    test('tirar disponible en rivalArea con posesión usuario', () {
      final state = _stateWith(zone: MatchBallZone.rivalArea);
      expect(ClashDuelEngine.canShoot(state), isTrue);
    });

    test('crear duelo shotVsSave selecciona portero rival', () {
      final state = _stateWith(zone: MatchBallZone.rivalArea);
      final pending = ClashDuelEngine.beginShot(state);
      expect(pending.activeDuel?.type, ClashDuelType.shotVsSave);
      expect(pending.activeDuel?.defender.position, ClashPosition.goalkeeper);
      expect(pending.activeDuel?.defender.label, 'R1');
    });

    test('atacante gana marca gol', () {
      final state = _stateWith(
        zone: MatchBallZone.rivalArea,
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            shot: 95,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            save: 5,
            label: 'R${i + 1}',
          ),
        ),
      );
      final pending = ClashDuelEngine.beginShot(state);
      final resolved = ClashDuelEngine.resolveNormalShot(
        pending,
        succeed,
        attackerVariance: 0,
        defenderVariance: 0,
      );
      expect(resolved.score.user, 1);
      expect(resolved.lastDuelResolution?.isGoal, isTrue);
      expect(
        resolved.eventLog.any((e) => e.message.contains('marca ante')),
        isTrue,
      );
    });

    test('portero gana parada y cambia posesión', () {
      final state = _stateWith(
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            shot: 5,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            save: 95,
            label: 'R${i + 1}',
          ),
        ),
      );
      final pending = ClashDuelEngine.beginShot(state);
      final resolved = ClashDuelEngine.resolveNormalShot(
        pending,
        succeed,
        attackerVariance: 0,
        defenderVariance: 0,
      );
      expect(resolved.possession, MatchTeamSide.rival);
      expect(resolved.ballHolderIndex, 0);
      expect(resolved.lastDuelResolution?.isSave, isTrue);
      expect(resolved.eventLog.last.type, MatchEventType.saveMade);
    });

    test('gol asigna saque al equipo que recibió gol', () {
      final state = _stateWith(
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            shot: 95,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            save: 5,
            label: 'R${i + 1}',
          ),
        ),
      );
      final pending = ClashDuelEngine.beginShot(state);
      final resolved = ClashDuelEngine.resolveNormalShot(
        pending,
        succeed,
        attackerVariance: 10,
        defenderVariance: -10,
      );
      expect(resolved.possession, MatchTeamSide.rival);
      expect(resolved.ballZone, MatchBallZone.rivalMidfield);
    });

    test('primer equipo en llegar a 3 finaliza partido', () {
      final state = _stateWith(
        score: const MatchScore(user: 2, rival: 0),
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            shot: 95,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            save: 5,
            label: 'R${i + 1}',
          ),
        ),
      );
      final pending = ClashDuelEngine.beginShot(state);
      final resolved = ClashDuelEngine.resolveNormalShot(
        pending,
        succeed,
        attackerVariance: 10,
        defenderVariance: -10,
      );
      expect(resolved.isFinished, isTrue);
      expect(resolved.winner, MatchTeamSide.user);
      expect(resolved.score.user, 3);
    });

    test('resistencia baja tras tiro y parada', () {
      final state = _stateWith(
        userSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            shot: 95,
            label: 'U${i + 1}',
          ),
        ),
        rivalSquad: List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.rival,
            save: 5,
            label: 'R${i + 1}',
          ),
        ),
      );
      final pending = ClashDuelEngine.beginShot(state);
      final shooterBefore = pending.userSquad[6].currentStamina;
      final keeperBefore = pending.rivalSquad[0].currentStamina;
      final resolved = ClashDuelEngine.resolveNormalShot(
        pending,
        succeed,
        attackerVariance: 5,
        defenderVariance: -5,
      );
      expect(
        resolved.userSquad[6].currentStamina,
        shooterBefore - ClashDuelEngine.shotStaminaCost,
      );
      expect(
        resolved.rivalSquad[0].currentStamina,
        keeperBefore - ClashDuelEngine.goalkeeperStaminaCost,
      );
    });
  });

  group('ClashDuelMath shot', () {
    test('tiro efectivo usa resistencia', () {
      final fresh = _player(
        index: 6,
        side: MatchTeamSide.user,
        shot: 50,
        stamina: 100,
      );
      final tired = fresh.copyWith(currentStamina: 60);
      expect(fresh.effectiveShot, greaterThan(tired.effectiveShot));
    });

    test('parada efectiva usa resistencia', () {
      final fresh = _player(
        index: 0,
        side: MatchTeamSide.rival,
        save: 50,
        stamina: 100,
      );
      final tired = fresh.copyWith(currentStamina: 60);
      expect(fresh.effectiveSave, greaterThan(tired.effectiveSave));
    });

    test('ventaja de estilo afecta puntuación del tirador', () {
      final shooter = ClashDuelParticipant(
        teamSide: MatchTeamSide.user,
        cardId: 's',
        playerId: 1,
        position: ClashPosition.striker,
        style: ClashPlayerStyle.picaro,
        label: 'S',
        squadIndex: 6,
        baseStat: 40,
        effectiveStat: 40,
        stamina: 100,
        power: 200,
      );
      final keeper = ClashDuelParticipant(
        teamSide: MatchTeamSide.rival,
        cardId: 'k',
        playerId: 2,
        position: ClashPosition.goalkeeper,
        style: ClashPlayerStyle.potente,
        label: 'K',
        squadIndex: 0,
        baseStat: 40,
        effectiveStat: 40,
        stamina: 100,
        power: 200,
      );
      final withAdvantage = ClashDuelMath.resolveShotVsSave(
        shooter: shooter,
        goalkeeper: keeper,
        ballZone: MatchBallZone.rivalArea,
        pressure: 0,
        chance: succeed,
      );
      final neutralShooter = ClashDuelParticipant(
        teamSide: MatchTeamSide.user,
        cardId: 's2',
        playerId: 3,
        position: ClashPosition.striker,
        style: ClashPlayerStyle.valiente,
        label: 'S2',
        squadIndex: 6,
        baseStat: 40,
        effectiveStat: 40,
        stamina: 100,
        power: 200,
      );
      final neutralKeeper = ClashDuelParticipant(
        teamSide: MatchTeamSide.rival,
        cardId: 'k2',
        playerId: 4,
        position: ClashPosition.goalkeeper,
        style: ClashPlayerStyle.valiente,
        label: 'K2',
        squadIndex: 0,
        baseStat: 40,
        effectiveStat: 40,
        stamina: 100,
        power: 200,
      );
      final neutral = ClashDuelMath.resolveShotVsSave(
        shooter: neutralShooter,
        goalkeeper: neutralKeeper,
        ballZone: MatchBallZone.rivalArea,
        pressure: 0,
        chance: succeed,
      );
      expect(
        withAdvantage.attackerScore,
        neutral.attackerScore + ClashDuelMath.styleAdvantageBonus,
      );
    });

    test('empate exacto usa moneda', () {
      final shooter = ClashDuelParticipant(
        teamSide: MatchTeamSide.user,
        cardId: 's',
        playerId: 1,
        position: ClashPosition.striker,
        style: ClashPlayerStyle.valiente,
        label: 'S',
        squadIndex: 6,
        baseStat: 46,
        effectiveStat: 46,
        stamina: 100,
        power: 200,
      );
      final keeper = ClashDuelParticipant(
        teamSide: MatchTeamSide.rival,
        cardId: 'k',
        playerId: 2,
        position: ClashPosition.goalkeeper,
        style: ClashPlayerStyle.valiente,
        label: 'K',
        squadIndex: 0,
        baseStat: 50,
        effectiveStat: 50,
        stamina: 100,
        power: 200,
      );
      final resolution = ClashDuelMath.resolveShotVsSave(
        shooter: shooter,
        goalkeeper: keeper,
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
  });

  group('ClashDuelDefenderSelector goalkeeper', () {
    test('selecciona portero rival', () {
      final state = _stateWith();
      final keeper = ClashDuelDefenderSelector.selectGoalkeeper(
        state,
        MatchTeamSide.user,
      );
      expect(keeper?.position, ClashPosition.goalkeeper);
      expect(keeper?.side, MatchTeamSide.rival);
    });
  });

  group('UI tiro', () {
    Widget app(ClashMatchController match, Widget child) {
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

    testWidgets('botón Tirar aparece en rivalArea', (tester) async {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(_stateWith(zone: MatchBallZone.rivalArea));

      await tester.pumpWidget(
        app(
          match,
          Builder(
            builder: (context) {
              final m = context.watch<ClashMatchController>();
              return Scaffold(
                body: FilledButton(
                  onPressed: m.canUserShoot ? m.shoot : null,
                  child: Text(
                    m.canUserShoot ? 'Tirar' : 'Llega al área para tirar',
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tirar'), findsOneWidget);
    });

    testWidgets('panel Tiro vs Parada y resolución', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        ClashDuelEngine.beginShot(
          _stateWith(
            userSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.user,
                shot: 95,
                label: 'U${i + 1}',
              ),
            ),
            rivalSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.rival,
                save: 5,
                label: 'R${i + 1}',
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duelo de tiro'), findsOneWidget);
      expect(find.text('U7'), findsWidgets);
      expect(find.text('R1'), findsWidgets);
      expect(find.text('Tiro normal'), findsOneWidget);

      await tester.tap(find.text('Tiro normal'));
      await tester.pumpAndSettle();

      expect(find.text('¡GOL!'), findsOneWidget);
      expect(match.state!.score.user, 1);
    });

    testWidgets('parada cambia posesión tras continuar', (tester) async {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        ClashDuelEngine.beginShot(
          _stateWith(
            userSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.user,
                shot: 5,
                label: 'U${i + 1}',
              ),
            ),
            rivalSquad: List.generate(
              7,
              (i) => _player(
                index: i,
                side: MatchTeamSide.rival,
                save: 95,
                label: 'R${i + 1}',
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiro normal'));
      await tester.pumpAndSettle();

      expect(find.text('PARADA'), findsOneWidget);
      expect(match.state!.possession, MatchTeamSide.rival);
    });

    testWidgets('minicampo destaca duelo de tiro', (tester) async {
      final state = ClashDuelEngine.beginShot(_stateWith());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClashMiniPitch(state: state)),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('U7'), findsOneWidget);
      expect(find.text('R1'), findsOneWidget);
    });
  });

  group('Controller', () {
    test('canUserShoot false fuera del área', () {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(_stateWith(zone: MatchBallZone.midfield));
      expect(match.canUserShoot, isFalse);
    });

    test('derrota deja partido jugable sin victoria', () {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        _stateWith(
          score: const MatchScore(user: 0, rival: 2),
          possession: MatchTeamSide.rival,
          zone: MatchBallZone.ownDefense,
          holderIndex: 6,
          userSquad: List.generate(
            7,
            (i) => _player(index: i, side: MatchTeamSide.user, save: 5),
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
        ),
      );
      match.simulateRivalAction();
      expect(match.state!.hasPendingManualDefense, isTrue);
      match.resolveManualDefense();
      expect(match.state!.isFinished, isTrue);
      expect(match.state!.winner, MatchTeamSide.rival);
    });
  });
}

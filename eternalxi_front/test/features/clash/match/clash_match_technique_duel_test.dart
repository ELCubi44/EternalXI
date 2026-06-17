import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_action_choice.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_technique_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _succeed = FixedMatchChanceResolver(alwaysSucceed: true);

ClashSuperTechnique _technique({
  String id = 'st1',
  String? name,
  ClashTechniqueType type = ClashTechniqueType.dribble,
  int basePower = 40,
  int ptCost = 10,
  ClashTechniqueLevel level = ClashTechniqueLevel.normal,
  ClashPlayerStyle style = ClashPlayerStyle.valiente,
}) {
  return ClashSuperTechnique(
    id: id,
    name: name ?? 'Técnica $id',
    description: 'Test',
    type: type,
    style: style,
    basePower: basePower,
    ptCost: ptCost,
    level: level,
  );
}

MatchSquadPlayer _player({
  required int index,
  required MatchTeamSide side,
  ClashPosition? position,
  int dribble = 40,
  int defense = 40,
  int shot = 40,
  int save = 40,
  int techniquePoints = 20,
  int currentPt = 20,
  List<ClashSuperTechnique> superTechniques = const [],
  String label = 'P',
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
    style: ClashPlayerStyle.valiente,
    label: label,
    homeX: x,
    homeY: y,
    baseStats: stats,
    power: 200,
    currentStamina: 100,
    superTechniques: superTechniques,
    maxPt: techniquePoints,
    currentPt: currentPt,
  );
}

MatchState _matchState({
  required int holderIndex,
  required MatchBallZone zone,
  required List<MatchSquadPlayer> userSquad,
  List<MatchSquadPlayer>? rivalSquad,
}) {
  return MatchState(
    levelId: 'test',
    status: MatchStatus.playing,
    score: MatchState.testing().score,
    possession: MatchTeamSide.user,
    ballHolderIndex: holderIndex,
    ballZone: zone,
    userSquad: userSquad,
    rivalSquad:
        rivalSquad ??
        List.generate(
          7,
          (i) => _player(index: i, side: MatchTeamSide.rival, label: 'R${i + 1}'),
        ),
    pressure: 20,
    possessionRisk: 15,
    eventLog: const [],
  );
}

void main() {
  group('PT en partido', () {
    test('currentPt inicia con stats.techniquePoints', () {
      final squad = MatchSquadBuilder.buildRivalSquad();
      for (final player in squad) {
        expect(player.currentPt, player.maxPt);
        expect(player.currentPt, player.baseStats.techniquePoints);
      }
    });
  });

  group('ClashDuelTechniqueRules', () {
    test('técnica compatible aparece en duelo correcto', () {
      final dribbler = _player(
        index: 6,
        side: MatchTeamSide.user,
        superTechniques: [_technique(type: ClashTechniqueType.dribble)],
      );
      final compatible = ClashDuelTechniqueRules.compatibleForAttacker(
        dribbler,
        ClashDuelType.dribbleVsDefense,
      );
      expect(compatible, hasLength(1));
      expect(compatible.first.type, ClashTechniqueType.dribble);
    });

    test('técnica incompatible no aparece', () {
      final striker = _player(
        index: 6,
        side: MatchTeamSide.user,
        superTechniques: [_technique(type: ClashTechniqueType.shot)],
      );
      final compatible = ClashDuelTechniqueRules.compatibleForAttacker(
        striker,
        ClashDuelType.dribbleVsDefense,
      );
      expect(compatible, isEmpty);
    });

    test('técnica no se puede usar sin PT', () {
      final technique = _technique(ptCost: 15);
      expect(technique.canBeUsed(14), isFalse);
      expect(technique.canBeUsed(15), isTrue);
    });
  });

  group('ClashSuperTechnique nivel y coste', () {
    test('ptCost no cambia por nivel', () {
      final normal = _technique(level: ClashTechniqueLevel.normal, ptCost: 12);
      final plus = _technique(level: ClashTechniqueLevel.i, ptCost: 12);
      expect(normal.ptCost, plus.ptCost);
    });

    test('nivel aumenta potencia efectiva', () {
      final normal = _technique(
        basePower: 40,
        level: ClashTechniqueLevel.normal,
      );
      final plus = _technique(basePower: 40, level: ClashTechniqueLevel.i);
      expect(plus.effectivePower, greaterThan(normal.effectivePower));
    });
  });

  group('Fórmulas con supertécnicas', () {
    final attacker = ClashDuelParticipant(
      teamSide: MatchTeamSide.user,
      cardId: 'a',
      playerId: 1,
      position: ClashPosition.striker,
      style: ClashPlayerStyle.valiente,
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
      style: ClashPlayerStyle.valiente,
      label: 'D',
      squadIndex: 1,
      baseStat: 40,
      effectiveStat: 40,
      stamina: 100,
      power: 200,
    );

    test('técnica de Regate aumenta score atacante', () {
      final normal = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
      );
      final technique = _technique(type: ClashTechniqueType.dribble);
      final withTech = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
        attackerTechnique: technique,
      );
      expect(
        withTech.attackerScore,
        normal.attackerScore + technique.effectivePower,
      );
    });

    test('técnica de Defensa aumenta score defensor', () {
      final normal = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
      );
      final technique = _technique(type: ClashTechniqueType.defense);
      final withTech = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender,
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
        defenderTechnique: technique,
      );
      expect(
        withTech.defenderScore,
        normal.defenderScore + technique.effectivePower,
      );
    });

    test('técnica de Tiro puede producir gol', () {
      final shooter = attacker.copyWith(effectiveStat: 80, baseStat: 80);
      final keeper = defender.copyWith(effectiveStat: 10, baseStat: 10);
      final resolution = ClashDuelMath.resolveShotVsSave(
        shooter: shooter,
        goalkeeper: keeper,
        ballZone: MatchBallZone.rivalArea,
        pressure: 0,
        chance: _succeed,
        shooterTechnique: _technique(
          type: ClashTechniqueType.shot,
          basePower: 50,
        ),
      );
      expect(resolution.isGoal, isTrue);
    });

    test('técnica de Parada puede producir parada', () {
      final shooter = attacker;
      final keeper = defender;
      final resolution = ClashDuelMath.resolveShotVsSave(
        shooter: shooter,
        goalkeeper: keeper,
        ballZone: MatchBallZone.rivalArea,
        pressure: 0,
        chance: _succeed,
        goalkeeperTechnique: _technique(
          type: ClashTechniqueType.save,
          basePower: 80,
        ),
      );
      expect(resolution.isSave, isTrue);
    });

    test('estilo de técnica aplica rueda', () {
      final technique = _technique(
        type: ClashTechniqueType.dribble,
        style: ClashPlayerStyle.picaro,
      );
      final withTechniqueStyle = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender.copyWith(style: ClashPlayerStyle.potente),
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
        attackerTechnique: technique,
      );
      final withPlayerStyle = ClashDuelMath.resolveDribbleVsDefense(
        attacker: attacker,
        defender: defender.copyWith(style: ClashPlayerStyle.potente),
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
      );
      expect(
        withTechniqueStyle.attackerScore,
        withPlayerStyle.attackerScore +
            technique.effectivePower +
            ClashDuelMath.styleAdvantageBonus,
      );
    });
  });

  group('ClashRivalTechniqueSelector', () {
    test('elige mejor técnica compatible pagable', () {
      final player = _player(
        index: 1,
        side: MatchTeamSide.rival,
        currentPt: 20,
        superTechniques: [
          _technique(
            id: 'weak',
            type: ClashTechniqueType.defense,
            basePower: 20,
          ),
          _technique(
            id: 'strong',
            type: ClashTechniqueType.defense,
            basePower: 60,
          ),
        ],
      );
      final choice = ClashRivalTechniqueSelector.selectDefender(
        player: player,
        duelType: ClashDuelType.dribbleVsDefense,
        effectiveBaseStat: 30,
        opponentStyle: ClashPlayerStyle.valiente,
        pressure: 0,
      );
      expect(choice.techniqueId, 'strong');
    });

    test('usa normal si no tiene PT', () {
      final player = _player(
        index: 1,
        side: MatchTeamSide.rival,
        currentPt: 0,
        superTechniques: [
          _technique(type: ClashTechniqueType.defense, ptCost: 10),
        ],
      );
      final choice = ClashRivalTechniqueSelector.selectDefender(
        player: player,
        duelType: ClashDuelType.dribbleVsDefense,
        effectiveBaseStat: 30,
        opponentStyle: ClashPlayerStyle.valiente,
        pressure: 0,
      );
      expect(choice.isNormal, isTrue);
    });
  });

  group('ClashDuelEngine PT y resolución', () {
    test('usar técnica resta PT', () {
      final dribbleTech = _technique(
        id: 'drib',
        type: ClashTechniqueType.dribble,
        ptCost: 8,
      );
      final userSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.user,
          label: 'U${i + 1}',
          superTechniques: i == 5 ? [dribbleTech] : const [],
        ),
      );
      final state = _matchState(
        holderIndex: 5,
        zone: MatchBallZone.midfield,
        userSquad: userSquad,
      );
      final pending = ClashDuelEngine.beginAdvance(state, _succeed);
      final ptBefore = pending.userSquad[5].currentPt;

      final resolved = ClashDuelEngine.resolveDuel(
        pending,
        _succeed,
        attackerChoice: ClashDuelActionChoice.technique('drib'),
        defenderChoice: const ClashDuelActionChoice.normal(),
        attackerVariance: 50,
        defenderVariance: -50,
      );

      expect(resolved.userSquad[5].currentPt, ptBefore - 8);
      expect(
        resolved.lastDuelResolution?.attackerTechniqueName,
        'Técnica drib',
      );
      expect(resolved.lastDuelResolution?.attackerPtSpent, 8);
    });

    test('resolución registra técnicas y PT gastados', () {
      final resolution = ClashDuelMath.resolveDribbleVsDefense(
        attacker: ClashDuelParticipant(
          teamSide: MatchTeamSide.user,
          cardId: 'a',
          playerId: 1,
          position: ClashPosition.striker,
          style: ClashPlayerStyle.valiente,
          label: 'A',
          squadIndex: 6,
          baseStat: 40,
          effectiveStat: 40,
          stamina: 100,
          power: 200,
        ),
        defender: ClashDuelParticipant(
          teamSide: MatchTeamSide.rival,
          cardId: 'd',
          playerId: 2,
          position: ClashPosition.centreBack,
          style: ClashPlayerStyle.valiente,
          label: 'D',
          squadIndex: 1,
          baseStat: 40,
          effectiveStat: 40,
          stamina: 100,
          power: 200,
        ),
        ballZone: MatchBallZone.midfield,
        pressure: 0,
        chance: _succeed,
        attackerTechnique: _technique(
          id: 'atk',
          type: ClashTechniqueType.dribble,
          ptCost: 9,
        ),
        defenderTechnique: _technique(
          id: 'def',
          type: ClashTechniqueType.defense,
          ptCost: 11,
        ),
      );
      expect(resolution.attackerTechniqueName, isNotNull);
      expect(resolution.defenderTechniqueName, isNotNull);
      expect(resolution.attackerPtSpent, 9);
      expect(resolution.defenderPtSpent, 11);
      expect(resolution.attackerUsedNormal, isFalse);
      expect(resolution.defenderUsedNormal, isFalse);
    });
  });

  group('UI supertécnicas', () {
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

    testWidgets('panel muestra técnicas compatibles', (tester) async {
      final dribbleTech = _technique(
        id: 'ui-drib',
        type: ClashTechniqueType.dribble,
        name: 'Regate UI',
      );
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        _matchState(
          holderIndex: 5,
          zone: MatchBallZone.midfield,
          userSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.user,
              label: 'U${i + 1}',
              superTechniques: i == 5 ? [dribbleTech] : const [],
            ),
          ),
        ),
      );
      match.advance();

      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Supertécnicas'), findsOneWidget);
      expect(find.text('Regate UI'), findsOneWidget);
    });

    testWidgets('técnica con PT insuficiente aparece deshabilitada', (
      tester,
    ) async {
      final expensive = _technique(
        id: 'expensive',
        type: ClashTechniqueType.dribble,
        ptCost: 50,
        name: 'Costosa',
      );
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        _matchState(
          holderIndex: 5,
          zone: MatchBallZone.midfield,
          userSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.user,
              currentPt: 5,
              superTechniques: i == 5 ? [expensive] : const [],
            ),
          ),
        ),
      );
      match.advance();

      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('PT insuficientes'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Costosa'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('pulsar técnica resuelve duelo y muestra nombre', (
      tester,
    ) async {
      final dribbleTech = _technique(
        id: 'resolve-drib',
        type: ClashTechniqueType.dribble,
        name: 'Mega Regate',
      );
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        _matchState(
          holderIndex: 5,
          zone: MatchBallZone.midfield,
          userSquad: List.generate(
            7,
            (i) => _player(
              index: i,
              side: MatchTeamSide.user,
              dribble: 90,
              superTechniques: i == 5 ? [dribbleTech] : const [],
            ),
          ),
          rivalSquad: List.generate(
            7,
            (i) => _player(index: i, side: MatchTeamSide.rival, defense: 10),
          ),
        ),
      );
      match.advance();
      await tester.pumpWidget(
        _app(match, const Scaffold(body: ClashMatchDuelPanel())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mega Regate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mega Regate'), findsWidgets);
    });
  });
}

extension on ClashDuelParticipant {
  ClashDuelParticipant copyWith({
    int? effectiveStat,
    int? baseStat,
    ClashPlayerStyle? style,
  }) {
    return ClashDuelParticipant(
      teamSide: teamSide,
      cardId: cardId,
      playerId: playerId,
      position: position,
      style: style ?? this.style,
      label: label,
      squadIndex: squadIndex,
      baseStat: baseStat ?? this.baseStat,
      effectiveStat: effectiveStat ?? this.effectiveStat,
      stamina: stamina,
      power: power,
    );
  }
}

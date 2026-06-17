import 'dart:io';

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_turn_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_status_banner.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_requirements.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _matchLevel = ClashStoryLevel(
  id: 'chapter_01_level_04',
  chapterId: 'chapter-01',
  title: 'La primera pachanga',
  description: 'Tutorial match',
  order: 4,
  type: ClashStoryLevelType.match,
  energyCost: 8,
  recommendedPower: 120,
  rewards: ClashStoryReward(gems: 1, coins: 500),
  scenes: const [],
  requirements: ClashStoryLevelRequirements(
    clashTeamUnlocked: true,
    completeActiveLineup: true,
  ),
);

MatchSquadPlayer _player({
  required int index,
  required MatchTeamSide side,
  ClashPosition? position,
  int pass = 40,
  int dribble = 40,
  int defense = 40,
  int shot = 40,
  int save = 40,
  String label = 'P',
}) {
  final pos = position ?? ClashPosition.values[index];
  final (x, y) = MatchPitchLayout.coordsForIndex(index, side);
  final stats = ClashStats(
    save: save,
    defense: defense,
    pass: pass,
    dribble: dribble,
    shot: shot,
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
    power: 200,
    currentStamina: 100,
    style: ClashPlayerStyle.valiente,
    superTechniques: const [],
    maxPt: 10,
    currentPt: 10,
  );
}

MatchState _playingState({
  MatchBallZone zone = MatchBallZone.ownMidfield,
  int holderIndex = 3,
  MatchTeamSide possession = MatchTeamSide.user,
  MatchScore score = const MatchScore(),
  bool isHalftime = false,
  List<MatchEvent>? eventLog,
  List<MatchSquadPlayer>? userSquad,
  List<MatchSquadPlayer>? rivalSquad,
}) {
  return MatchState(
    levelId: 'test',
    status: isHalftime ? MatchStatus.halftime : MatchStatus.playing,
    score: score,
    possession: possession,
    ballHolderIndex: holderIndex,
    ballZone: zone,
    userSquad:
        userSquad ??
        List.generate(
          7,
          (i) => _player(
            index: i,
            side: MatchTeamSide.user,
            shot: 90,
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
            save: 5,
            label: 'R${i + 1}',
          ),
        ),
    pressure: 30,
    possessionRisk: 20,
    eventLog: eventLog ?? const [],
    matchInventory: const [],
    isHalftime: isHalftime,
    hasHalftimeOccurred: isHalftime,
  );
}

Widget _app(ClashMatchController match, Widget child) {
  return ChangeNotifierProvider<ClashMatchController>.value(
    value: match,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Fase 15 pulido', () {
    test('pantalla de partido no incluye botones dev de gol', () {
      final source = File(
        'lib/features/clash/match/presentation/screens/clash_match_screen.dart',
      ).readAsStringSync();
      expect(source.contains('clashMatchDevGoalUser'), isFalse);
      expect(source.contains('clashMatchDevGoalRival'), isFalse);
      expect(source.contains('ExpansionTile'), isFalse);
      expect(source.contains('simulateUserGoal'), isFalse);
    });

    test('partido puede llegar a victoria sin botones dev via tiro', () {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(
          alwaysSucceed: true,
          coinFavorsUser: true,
        ),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        _playingState(
          zone: MatchBallZone.rivalArea,
          holderIndex: 6,
          score: const MatchScore(user: 2, rival: 0),
        ),
      );
      match.shoot();
      match.resolvePendingDuel();
      expect(match.state!.isFinished, isTrue);
      expect(match.state!.winner, MatchTeamSide.user);
      expect(match.state!.score.user, 3);
    });

    test('partido puede llegar a derrota sin botones dev via IA rival', () {
      final match = ClashMatchController(
        chanceResolver: const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.startMatch(levelId: 'test');
      match.setStateForTesting(
        _playingState(
          zone: MatchBallZone.ownDefense,
          holderIndex: 6,
          possession: MatchTeamSide.rival,
          score: const MatchScore(user: 0, rival: 2),
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
      match.continueRivalTurn();
      expect(match.state!.hasPendingManualDefense, isTrue);
      match.resolveManualDefense();
      expect(match.state!.isFinished, isTrue);
      expect(match.state!.winner, MatchTeamSide.rival);
    });

    test('no se puede actuar durante descanso', () {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      final before = _playingState(isHalftime: true);
      match.setStateForTesting(before);
      match.advance();
      match.passTo(4);
      match.shoot();
      expect(match.state, before);
    });

    test('no se puede actuar con duelo pendiente', () {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      final pending = ClashDuelEngine.beginAdvance(
        _playingState(),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      match.setStateForTesting(pending);
      match.advance();
      match.passTo(4);
      expect(match.state!.hasPendingDuel, isTrue);
    });

    test('reintentar reinicia partido', () {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.user);
      match.restartMatch();
      expect(match.state!.status, MatchStatus.awaitingCoinToss);
      expect(match.state!.score.user, 0);
    });

    test('historial conserva eventos recientes', () {
      var state = _playingState();
      state = MatchRules.applyGoal(state, MatchTeamSide.user);
      expect(state.eventLog.any((e) => e.type == MatchEventType.goal), isTrue);
      expect(state.eventLog.last.message, isNotEmpty);
    });
  });

  group('Fase 15 UI', () {
    testWidgets('no aparece botón dev de gol en flujo jugable', (tester) async {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.beginPlayingWithKickoff(MatchTeamSide.user);

      await tester.pumpWidget(
        _app(match, ClashMatchStatusBanner(state: _playingState())),
      );

      expect(find.textContaining('Gol Eternal'), findsNothing);
      expect(find.textContaining('provisional'), findsNothing);
      expect(find.textContaining('Herramientas dev'), findsNothing);
    });

    testWidgets('fuera del área muestra explicación sin botón Tirar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchStatusBanner(
              state: _playingState(zone: MatchBallZone.midfield),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Avanza hasta el área rival para poder tirar'),
        findsOneWidget,
      );
    });

    testWidgets('en área rival puede tirar', (tester) async {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(_playingState(zone: MatchBallZone.rivalArea));

      expect(match.canUserShoot, isTrue);
    });

    testWidgets('victoria muestra marcador y recompensas', (tester) async {
      final state = _playingState(
        score: const MatchScore(user: 3, rival: 1),
      ).copyWith(status: MatchStatus.finished);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: const [],
              previewRewards: const ClashStoryReward(gems: 1, coins: 500),
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(find.text('Marcador final: 3 - 1'), findsOneWidget);
      expect(find.text('Ver recompensas'), findsOneWidget);
      expect(find.text('Gemas: +1'), findsOneWidget);
      expect(find.text('Monedas: +500'), findsOneWidget);
    });

    testWidgets('derrota muestra marcador sin recompensas', (tester) async {
      final state = _playingState(
        score: const MatchScore(user: 1, rival: 3),
      ).copyWith(status: MatchStatus.finished);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchEndPanel(
              state: state,
              level: _matchLevel,
              objectiveResults: const [],
              previewRewards: const ClashStoryReward(),
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Derrota'), findsOneWidget);
      expect(
        find.text(
          'Debes ganar el partido para recibir recompensas de objetivos',
        ),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Ver recompensas'), findsNothing);
    });

    testWidgets('continuar rival solo con posesión rival', (tester) async {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(_playingState(possession: MatchTeamSide.rival));

      await tester.pumpWidget(_app(match, const ClashMatchRivalTurnPanel()));
      await tester.pumpAndSettle();
      expect(find.text('Continuar acción rival'), findsOneWidget);

      match.setStateForTesting(_playingState(possession: MatchTeamSide.user));
      await tester.pumpWidget(_app(match, const ClashMatchRivalTurnPanel()));
      await tester.pumpAndSettle();
      expect(find.text('Continuar acción rival'), findsNothing);
    });

    testWidgets('defensa manual bloquea acciones de posesión usuario', (
      tester,
    ) async {
      final match = ClashMatchController();
      final pending = ClashDuelEngine.beginRivalShot(
        _playingState(
          zone: MatchBallZone.ownDefense,
          holderIndex: 6,
          possession: MatchTeamSide.rival,
        ),
      );
      match.setStateForTesting(pending);

      expect(match.canUserShoot, isFalse);
      expect(match.passOptions, isEmpty);
      expect(pending.activeDuel!.isUserDefending, isTrue);
      expect(
        pending.activeDuel!.status,
        ClashDuelStatus.pendingUserDefensiveChoice,
      );
    });

    testWidgets('banner muestra mensaje de defensa manual', (tester) async {
      final pending = ClashDuelEngine.beginRivalShot(
        _playingState(
          zone: MatchBallZone.ownDefense,
          holderIndex: 6,
          possession: MatchTeamSide.rival,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ClashMatchStatusBanner(state: pending)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detén el tiro'), findsOneWidget);
      expect(
        find.text('El rival se aproxima: elige cómo defender'),
        findsOneWidget,
      );
    });
  });
}

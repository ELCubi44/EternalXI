import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_match_end_panel.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_status.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_type.dart';
import 'package:eternal_xi/features/clash/match/domain/coin_toss.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_action_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_active_player_card.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_duel_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_end_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_halftime_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_header.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_history_panel.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_mini_pitch.dart';
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
  scenes: [],
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
  int currentPt = 10,
  int maxPt = 10,
  String label = 'P',
  List<ClashSuperTechnique> superTechniques = const [],
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
    currentStamina: 80,
    style: ClashPlayerStyle.valiente,
    superTechniques: superTechniques,
    maxPt: maxPt,
    currentPt: currentPt,
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
    coinToss: const CoinTossResult(
      userChoice: CoinTossChoice.heads,
      outcome: CoinTossOutcome.heads,
      userWonToss: true,
      kickoffSide: MatchTeamSide.user,
    ),
  );
}

Widget _app(ClashMatchController match, Widget child) {
  return ChangeNotifierProvider<ClashMatchController>.value(
    value: match,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(360, 740)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('Fase 46 match UI', () {
    testWidgets('header muestra marcador y objetivo primero a 3', (
      tester,
    ) async {
      final state = _playingState(score: const MatchScore(user: 2, rival: 1));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchHeader(
              matchTitle: 'Nivel test',
              state: state,
              rivalName: 'Rival FC',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Objetivo: primero a 3 goles'), findsOneWidget);
      expect(find.text('vs Rival FC'), findsOneWidget);
    });

    testWidgets('chip muestra posesión usuario y rival', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchHeader(
              matchTitle: 'Test',
              state: _playingState(possession: MatchTeamSide.user),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu posesión'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchHeader(
              matchTitle: 'Test',
              state: _playingState(possession: MatchTeamSide.rival),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Posesión rival'), findsOneWidget);
    });

    testWidgets('jugador activo muestra PT y resistencia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashMatchActivePlayerCard(
              state: _playingState(holderIndex: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tu jugador activo'), findsOneWidget);
      expect(find.text('U4'), findsWidgets);
      expect(find.textContaining('PT 10/10'), findsOneWidget);
      expect(find.textContaining('80/100'), findsOneWidget);
    });

    testWidgets('mini pitch renderiza sin overflow en móvil', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 640)),
            child: Scaffold(body: ClashMiniPitch(state: _playingState())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Balón'), findsOneWidget);
      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Rival'), findsOneWidget);
    });

    testWidgets('acciones muestran motivo disabled fuera de área', (
      tester,
    ) async {
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(_playingState(zone: MatchBallZone.midfield));

      await tester.pumpWidget(_app(match, const ClashMatchActionPanel()));
      await tester.pumpAndSettle();

      expect(
        find.text('Avanza hasta el área rival para poder tirar'),
        findsOneWidget,
      );
      expect(find.text('Tirar'), findsNothing);
    });

    testWidgets('duelo muestra atacante/defensor y técnicas', (tester) async {
      final expensiveTechnique = ClashSuperTechnique(
        id: 'st-expensive',
        name: 'Mega ST',
        description: 'Test',
        type: ClashTechniqueType.dribble,
        style: ClashPlayerStyle.valiente,
        level: ClashTechniqueLevel.xi,
        basePower: 80,
        ptCost: 99,
      );
      final userSquad = List.generate(
        7,
        (i) => _player(
          index: i,
          side: MatchTeamSide.user,
          dribble: 90,
          label: 'U${i + 1}',
          superTechniques: i == 5 ? [expensiveTechnique] : const [],
        ),
      );
      final pending = ClashDuelEngine.beginAdvance(
        _playingState(
          zone: MatchBallZone.rivalMidfield,
          holderIndex: 5,
          userSquad: userSquad,
        ),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      expect(pending.activeDuel, isNotNull);
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(pending);

      await tester.pumpWidget(_app(match, const ClashMatchDuelPanel()));
      await tester.pumpAndSettle();

      expect(find.text('Duelo'), findsWidgets);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('Supertécnicas'), findsOneWidget);
      expect(find.text('Mega ST'), findsOneWidget);
      expect(find.text('PT insuficientes'), findsOneWidget);
    });

    testWidgets('defensa manual muestra candidatos', (tester) async {
      final pending = ClashDuelEngine.beginRivalAdvance(
        _playingState(
          zone: MatchBallZone.midfield,
          possession: MatchTeamSide.rival,
        ),
        const FixedMatchChanceResolver(alwaysSucceed: true),
      );
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(pending);

      await tester.pumpWidget(_app(match, const ClashMatchDuelPanel()));
      await tester.pumpAndSettle();

      expect(find.text('Elige quién defiende'), findsOneWidget);
    });

    testWidgets('descanso muestra items y explicación', (tester) async {
      final item = ClashMatchItem(
        id: 'energy-drink',
        name: 'Bebida energética',
        description: 'Recupera resistencia',
        type: ClashMatchItemType.recoverStaminaSingle,
        amount: 25,
        targetCount: 1,
      );
      final state = _playingState(isHalftime: true).copyWith(
        matchInventory: [ClashMatchItemInventoryEntry(item: item, quantity: 2)],
      );
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(state);

      await tester.pumpWidget(_app(match, const ClashMatchHalftimePanel()));
      await tester.pumpAndSettle();

      expect(
        find.text('Solo puedes usar objetos en el descanso'),
        findsOneWidget,
      );
      expect(find.text('Bebida energética'), findsOneWidget);
      expect(find.text('Continuar partido'), findsOneWidget);
    });

    testWidgets('fin story muestra victoria objetivos y recompensas', (
      tester,
    ) async {
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
              previewCardXp: const [],
              onViewRewards: () {},
              onRetry: () {},
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(find.text('Tú 3 - 1 Rival'), findsOneWidget);
      expect(find.text('Gemas: +1'), findsOneWidget);
    });

    testWidgets('fin evento sigue funcionando', (tester) async {
      final state = _playingState(
        score: const MatchScore(user: 0, rival: 3),
      ).copyWith(status: MatchStatus.finished);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashEventMatchEndPanel(
              state: state,
              stageTitle: 'Stage 1',
              previewReward: const ClashCharacterEventReward(),
              previewCardXp: const [],
              onViewRewards: () {},
              onRetry: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Derrota'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('historial muestra eventos', (tester) async {
      final state = _playingState(
        eventLog: [
          const MatchEvent(type: MatchEventType.goal, message: 'Gol de U4'),
          const MatchEvent(
            type: MatchEventType.passSuccess,
            message: 'Pase completado',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ClashMatchHistoryPanel(state: state)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Últimos eventos'), findsOneWidget);
      expect(find.text('Gol de U4'), findsOneWidget);
      expect(find.text('Pase completado'), findsOneWidget);
    });

    testWidgets('defensa manual shot muestra elige parada', (tester) async {
      final pending = ClashDuelEngine.beginRivalShot(
        _playingState(
          zone: MatchBallZone.ownDefense,
          holderIndex: 6,
          possession: MatchTeamSide.rival,
        ),
      );
      final match = ClashMatchController();
      match.startMatch(levelId: 'test');
      match.setStateForTesting(pending);

      await tester.pumpWidget(_app(match, const ClashMatchDuelPanel()));
      await tester.pumpAndSettle();

      expect(find.text('Detén el tiro'), findsOneWidget);
      expect(find.text('Elige parada'), findsOneWidget);
      expect(
        pending.activeDuel!.status,
        ClashDuelStatus.pendingUserDefensiveChoice,
      );
    });
  });
}

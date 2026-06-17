import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/match/data/datasources/clash_match_items_local_datasource.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_halftime_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_halftime_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_halftime_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _kitJson = '''
{
  "items": [
    {
      "id": "pt-single",
      "name": "Bebida técnica pequeña",
      "description": "Recupera PT de un jugador.",
      "type": "recoverPtSingle",
      "amount": 20,
      "targetCount": 1,
      "category": "pt"
    },
    {
      "id": "pt-triple",
      "name": "Charla táctica",
      "description": "Recupera PT de hasta tres jugadores.",
      "type": "recoverPtTriple",
      "amount": 15,
      "targetCount": 3,
      "category": "pt"
    },
    {
      "id": "pt-all",
      "name": "Ánimo del equipo",
      "description": "Recupera pocos PT de todo el equipo.",
      "type": "recoverPtAllSmall",
      "amount": 5,
      "targetCount": 7,
      "category": "pt"
    },
    {
      "id": "sta-single",
      "name": "Venda rápida",
      "description": "Recupera resistencia de un jugador.",
      "type": "recoverStaminaSingle",
      "amount": 15,
      "targetCount": 1,
      "category": "stamina"
    },
    {
      "id": "sta-triple",
      "name": "Preparación física",
      "description": "Recupera resistencia de hasta tres jugadores.",
      "type": "recoverStaminaTriple",
      "amount": 12,
      "targetCount": 3,
      "category": "stamina"
    },
    {
      "id": "sta-all",
      "name": "Grito de equipo",
      "description": "Recupera poca resistencia de todo el equipo.",
      "type": "recoverStaminaAllSmall",
      "amount": 5,
      "targetCount": 7,
      "category": "stamina"
    }
  ],
  "defaultKit": {
    "pt-single": 2,
    "pt-triple": 1,
    "pt-all": 2,
    "sta-single": 2,
    "sta-triple": 1,
    "sta-all": 2
  }
}
''';

List<ClashMatchItemInventoryEntry> _testKit() {
  return ClashMatchItemsLocalDataSource().parseDefaultKitJson(_kitJson);
}

ClashMatchItemInventoryEntry _entry(String id) {
  return _testKit().firstWhere((entry) => entry.item.id == id);
}

MatchState _halftimeState({
  MatchScore score = const MatchScore(user: 1, rival: 1),
  List<MatchSquadPlayer>? userSquad,
  List<ClashMatchItemInventoryEntry>? inventory,
}) {
  final squad = userSquad ?? MatchState.testing().userSquad;
  return MatchState(
    levelId: 'test',
    status: MatchStatus.halftime,
    score: score,
    possession: MatchTeamSide.user,
    ballHolderIndex: 3,
    ballZone: MatchBallZone.ownMidfield,
    userSquad: squad,
    rivalSquad: MatchState.testing().rivalSquad,
    pressure: 20,
    possessionRisk: 15,
    eventLog: const [],
    matchInventory: inventory ?? _testKit(),
    hasHalftimeOccurred: true,
    isHalftime: true,
    halftimeTriggeredAtScore: score,
  );
}

MatchSquadPlayer _lowPtPlayer(MatchSquadPlayer player) {
  return player.copyWith(currentPt: 2);
}

MatchSquadPlayer _lowStaminaPlayer(MatchSquadPlayer player) {
  return player.copyWith(currentStamina: 40);
}

void main() {
  group('ClashHalftimeRules', () {
    test('descanso se activa al total de 2 goles', () {
      final state = MatchState.testing(
        score: const MatchScore(user: 1, rival: 0),
      );
      expect(
        ClashHalftimeRules.shouldTriggerHalftime(
          state,
          const MatchScore(user: 2, rival: 0),
        ),
        isTrue,
      );
    });

    test('descanso solo se activa una vez', () {
      final state = MatchState.testing(
        score: const MatchScore(user: 1, rival: 1),
        hasHalftimeOccurred: true,
      );
      expect(
        ClashHalftimeRules.shouldTriggerHalftime(
          state,
          const MatchScore(user: 2, rival: 1),
        ),
        isFalse,
      );
    });
  });

  group('MatchRules descanso', () {
    test('applyGoal activa descanso con 2 goles totales', () {
      final state = MatchState.testing(
        score: const MatchScore(user: 1, rival: 0),
      );
      final next = MatchRules.applyGoal(state, MatchTeamSide.rival);

      expect(next.isPausedForHalftime, isTrue);
      expect(next.hasHalftimeOccurred, isTrue);
      expect(next.score.user, 1);
      expect(next.score.rival, 1);
      expect(next.possession, MatchTeamSide.user);
    });

    test('continuar descanso reanuda partido', () {
      final paused = _halftimeState();
      final resumed = ClashHalftimeEngine.continueFromHalftime(paused);

      expect(resumed.isPausedForHalftime, isFalse);
      expect(resumed.status, MatchStatus.playing);
      expect(resumed.score, paused.score);
      expect(resumed.possession, paused.possession);
      expect(resumed.ballZone, paused.ballZone);
    });
  });

  group('ClashMatchItemEngine', () {
    test('objeto no se puede usar fuera del descanso', () {
      final playing = MatchState.testing(matchInventory: _testKit());
      final result = ClashMatchItemEngine.preview(
        playing,
        itemId: 'pt-single',
        targetIndices: const [0],
      );
      expect(result.used, isFalse);
      expect(result.errorMessage, 'Solo en descanso');
    });

    test('objeto falla con cantidad 0', () {
      final emptyKit = [_entry('pt-single').copyWith(quantity: 0)];
      final state = _halftimeState(inventory: emptyKit);
      final result = ClashMatchItemEngine.preview(
        state,
        itemId: 'pt-single',
        targetIndices: const [0],
      );
      expect(result.used, isFalse);
      expect(result.errorMessage, 'Sin unidades disponibles');
    });

    test('PT single recupera sin superar máximo', () {
      final squad = MatchState.testing().userSquad.map(_lowPtPlayer).toList();
      final state = _halftimeState(userSquad: squad);

      final next = ClashMatchItemEngine.useItem(
        state,
        itemId: 'pt-single',
        targetIndices: const [0],
      );

      expect(next.userSquad.first.currentPt, 10);
      expect(
        next.matchInventory
            .firstWhere((e) => e.item.id == 'pt-single')
            .quantity,
        1,
      );
    });

    test('PT triple afecta hasta 3 jugadores', () {
      final squad = MatchState.testing().userSquad.map(_lowPtPlayer).toList();
      final state = _halftimeState(userSquad: squad);

      final next = ClashMatchItemEngine.useItem(
        state,
        itemId: 'pt-triple',
        targetIndices: const [0, 1, 2],
      );

      expect(next.userSquad[0].currentPt, 10);
      expect(next.userSquad[1].currentPt, 10);
      expect(next.userSquad[2].currentPt, 10);
    });

    test('PT all small afecta a todos', () {
      final squad = MatchState.testing().userSquad.map(_lowPtPlayer).toList();
      final state = _halftimeState(userSquad: squad);

      final next = ClashMatchItemEngine.useItem(state, itemId: 'pt-all');

      for (final player in next.userSquad) {
        expect(player.currentPt, 7);
      }
    });

    test('resistencia single recupera sin superar máximo', () {
      final squad = MatchState.testing().userSquad
          .map(_lowStaminaPlayer)
          .toList();
      final state = _halftimeState(userSquad: squad);
      final max = squad.first.maxStamina;

      final next = ClashMatchItemEngine.useItem(
        state,
        itemId: 'sta-single',
        targetIndices: const [0],
      );

      expect(next.userSquad.first.currentStamina, 55);
      expect(next.userSquad.first.currentStamina, lessThanOrEqualTo(max));
    });

    test('resistencia triple afecta hasta 3', () {
      final squad = MatchState.testing().userSquad
          .map(_lowStaminaPlayer)
          .toList();
      final state = _halftimeState(userSquad: squad);

      final next = ClashMatchItemEngine.useItem(
        state,
        itemId: 'sta-triple',
        targetIndices: const [0, 1, 2],
      );

      expect(next.userSquad[0].currentStamina, 52);
      expect(next.userSquad[1].currentStamina, 52);
      expect(next.userSquad[2].currentStamina, 52);
    });

    test('resistencia all small afecta a todos', () {
      final squad = MatchState.testing().userSquad
          .map(_lowStaminaPlayer)
          .toList();
      final state = _halftimeState(userSquad: squad);

      final next = ClashMatchItemEngine.useItem(state, itemId: 'sta-all');

      for (final player in next.userSquad) {
        expect(player.currentStamina, 45);
      }
    });

    test('no gastar objeto si no tiene efecto', () {
      final squad = MatchState.testing().userSquad
          .map((player) => player.copyWith(currentPt: player.maxPt))
          .toList();
      final state = _halftimeState(userSquad: squad);
      final qtyBefore = state.matchInventory
          .firstWhere((e) => e.item.id == 'pt-single')
          .quantity;

      final next = ClashMatchItemEngine.useItem(
        state,
        itemId: 'pt-single',
        targetIndices: const [0],
      );

      expect(next.matchInventory.first.quantity, qtyBefore);
      expect(next.lastItemEffectResult?.used, isFalse);
    });
  });

  group('ClashMatchController descanso', () {
    test('durante descanso no se puede pasar ni avanzar ni tirar', () {
      final controller = ClashMatchController();
      controller.setStateForTesting(_halftimeState());

      controller.passTo(4);
      controller.advance();
      controller.shoot();

      expect(controller.state!.isPausedForHalftime, isTrue);
    });
  });

  group('UI descanso', () {
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
            body: SingleChildScrollView(child: const ClashMatchHalftimePanel()),
          ),
        ),
      );
    }

    testWidgets('descanso muestra marcador y objetos', (tester) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final match = ClashMatchController();
      match.setStateForTesting(_halftimeState());

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      expect(find.text('Descanso'), findsOneWidget);
      expect(find.text('1 - 1'), findsOneWidget);
      expect(find.text('Bebida técnica pequeña'), findsOneWidget);
      expect(find.textContaining('x2'), findsWidgets);
      expect(find.textContaining('PT '), findsWidgets);
      expect(find.textContaining('RES '), findsWidgets);
    });

    testWidgets('indicadores PT/resistencia visibles en partido', (
      tester,
    ) async {
      final state = MatchState.testing(status: MatchStatus.playing);
      final holder = state.ballHolderPlayer()!;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Text(
                  l10n.clashMatchPtStaminaLabel(
                    holder.currentPt,
                    holder.maxPt,
                    holder.currentStamina,
                    holder.maxStamina,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('PT '), findsOneWidget);
      expect(find.textContaining('Resistencia '), findsOneWidget);
    });

    testWidgets('usar objeto single permite elegir jugador', (tester) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final squad = MatchState.testing().userSquad.map(_lowPtPlayer).toList();
      final match = ClashMatchController();
      match.setStateForTesting(_halftimeState(userSquad: squad));

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bebida técnica pequeña'));
      await tester.pumpAndSettle();
      expect(find.text('Elige hasta 1 jugadores'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'U1'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Usar objeto'));
      await tester.tap(find.text('Usar objeto'));
      await tester.pumpAndSettle();

      expect(match.state!.userSquad.first.currentPt, 10);
    });

    testWidgets('usar objeto all aplica efecto', (tester) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final squad = MatchState.testing().userSquad.map(_lowPtPlayer).toList();
      final match = ClashMatchController();
      match.setStateForTesting(_halftimeState(userSquad: squad));

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ánimo del equipo'));
      await tester.pumpAndSettle();

      expect(match.state!.userSquad.first.currentPt, 7);
    });

    testWidgets('botón continuar vuelve al partido', (tester) async {
      _tallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      final match = ClashMatchController();
      match.setStateForTesting(_halftimeState());

      await tester.pumpWidget(_app(match));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuar partido'));
      await tester.tap(find.text('Continuar partido'));
      await tester.pumpAndSettle();

      expect(match.state!.status, MatchStatus.playing);
      expect(match.isHalftime, isFalse);
    });
  });
}

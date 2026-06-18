import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/team/presentation/screens/clash_lineup_7v7_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/widgets/clash_lineup_card_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

const _cardsJson = '''
{
  "cards": [
    {
      "id": "gk-1",
      "playerId": 1,
      "name": "Portero Test",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "valiente",
      "position": "goalkeeper",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 40, "defense": 10, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "gk-1-st", "name": "Parada", "description": "T", "type": "save", "style": "valiente", "basePower": 40, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "st-1",
      "playerId": 2,
      "name": "Delantero Test",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "potente",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 10, "shot": 35, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st-1-st", "name": "Tiro", "description": "T", "type": "shot", "style": "potente", "basePower": 40, "ptCost": 10, "level": "normal"}]
    }
  ]
}
''';

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  _FakeCardsDataSource(this._cards);

  final List<ClashCardCatalogEntry> _cards;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _cards;
}

Future<ClashLineupsController> _readyController({
  List<String> ownedIds = const ['gk-1', 'st-1'],
}) async {
  final cards = ClashCardsLocalDataSource().parseCardsJson(_cardsJson);
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(cards));
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
  );
  await collectionRepo.grantMissingCardIds(ownedIds);
  final lineupsRepo = ClashLineupsRepository(
    storage: InMemoryClashLineupsBackend(),
    cardsRepository: cardsRepo,
  );
  final controller = ClashLineupsController(
    lineupsRepository: lineupsRepo,
    collectionRepository: collectionRepo,
  );
  await controller.load();
  return controller;
}

Future<Widget> _lineupScreen(ClashLineupsController controller) async {
  return ChangeNotifierProvider<ClashLineupsController>.value(
    value: controller,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: ClashLineup7v7Screen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('ClashLineup7v7Screen', () {
    testWidgets('muestra cabecera potencia y posiciones', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await tester.pumpWidget(await _lineupScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Alineación 7vs7'), findsOneWidget);
      expect(find.textContaining('0/7 posiciones'), findsOneWidget);
      expect(find.textContaining('Potencia total'), findsOneWidget);
      expect(find.text('Sin portero'), findsOneWidget);
    });

    testWidgets('muestra selector de alineaciones y activar', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await tester.pumpWidget(await _lineupScreen(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alineación 1'), findsWidgets);
      expect(find.text('Alineación 2'), findsOneWidget);
      expect(find.text('Alineación 3'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Establecer como activa'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Establecer como activa'), findsOneWidget);
    });

    testWidgets('slot vacío muestra Elegir y abre selector', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await tester.pumpWidget(await _lineupScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Elegir'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Portería'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Elegir').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Elegir carta'), findsOneWidget);
      expect(find.text('Compatibles'), findsOneWidget);
      expect(find.text('Portero Test'), findsOneWidget);
    });

    testWidgets('asignar carta muestra nombre y potencia en slot', (
      tester,
    ) async {
      configureViewport(tester);
      final controller = await _readyController();
      await controller.assignCard(
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );

      await tester.pumpWidget(await _lineupScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Portero Test'), findsOneWidget);
      expect(find.textContaining('PWR'), findsWidgets);
      expect(find.text('1/7 posiciones'), findsOneWidget);
    });

    testWidgets('cambiar alineación conserva datos', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await controller.assignCard(
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );

      await tester.pumpWidget(await _lineupScreen(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alineación 2'));
      await tester.pumpAndSettle();
      expect(find.text('Portero Test'), findsNothing);

      await tester.tap(find.textContaining('Alineación 1'));
      await tester.pumpAndSettle();
      expect(find.text('Portero Test'), findsOneWidget);
    });
  });

  group('ClashLineupCardPicker', () {
    testWidgets('etiqueta Ya usada si carta está en otro slot', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await controller.assignCard(
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showClashLineupCardPicker(
                      context: context,
                      controller: controller,
                      slot: ClashPosition.striker,
                      onSelected: (_) async {},
                    ),
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();

      expect(find.text('Ya usada'), findsOneWidget);
    });

    testWidgets('estado vacío sin cartas poseídas', (tester) async {
      configureViewport(tester);
      final controller = await _readyController(ownedIds: const []);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showClashLineupCardPicker(
                      context: context,
                      controller: controller,
                      slot: ClashPosition.goalkeeper,
                      onSelected: (_) async {},
                    ),
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('No tienes cartas en tu colección.'), findsOneWidget);
    });

    testWidgets('permite limpiar posición asignada', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await controller.assignCard(
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );

      await tester.pumpWidget(await _lineupScreen(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Portero Test'));
      await tester.pumpAndSettle();
      expect(find.text('Quitar carta'), findsOneWidget);

      await tester.tap(find.text('Quitar carta'));
      await tester.pumpAndSettle();
      expect(find.text('Portero Test'), findsNothing);
      expect(find.text('Elegir'), findsWidgets);
    });
  });
}

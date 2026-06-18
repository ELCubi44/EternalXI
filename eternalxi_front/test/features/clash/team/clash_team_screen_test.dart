import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/clash_team_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => const [];
}

Future<Widget> _teamApp(ClashLineupsController controller) async {
  return ChangeNotifierProvider<ClashLineupsController>.value(
    value: controller,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: ClashTeamScreen()),
    ),
  );
}

Future<ClashLineupsController> _readyController() async {
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource());
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
  );
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('ClashTeamScreen', () {
    testWidgets('muestra resumen de alineación activa', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await tester.pumpWidget(await _teamApp(controller));
      await tester.pumpAndSettle();

      expect(find.text('Resumen del equipo'), findsOneWidget);
      expect(find.text('Alineación activa'), findsOneWidget);
      expect(find.textContaining('Alineación 1'), findsWidgets);
      expect(find.textContaining('0/7 posiciones'), findsWidgets);
    });

    testWidgets('muestra accesos principales', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await tester.pumpWidget(await _teamApp(controller));
      await tester.pumpAndSettle();

      expect(find.text('Alineación 7vs7'), findsOneWidget);
      expect(find.text('Personajes'), findsOneWidget);
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Mejorar cartas'), findsOneWidget);
    });

    testWidgets('muestra sección Próximamente', (tester) async {
      configureViewport(tester);
      final controller = await _readyController();
      await tester.pumpWidget(await _teamApp(controller));
      await tester.pumpAndSettle();

      expect(find.text('Próximamente'), findsWidgets);
      expect(find.text('Alineación 11vs11'), findsOneWidget);
      expect(find.text('Tácticas'), findsOneWidget);
      expect(find.text('Formaciones avanzadas'), findsOneWidget);
    });
  });
}

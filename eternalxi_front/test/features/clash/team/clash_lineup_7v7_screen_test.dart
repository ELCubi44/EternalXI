import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/team/presentation/screens/clash_lineup_7v7_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cards/clash_test_support.dart';
import 'package:provider/provider.dart';

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  _FakeCardsDataSource(this._cards);

  final List<ClashCardCatalogEntry> _cards;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _cards;
}

Future<Widget> _lineupScreen({
  required ClashLineupsController controller,
}) async {
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

  testWidgets('pantalla 7vs7 smoke test', (tester) async {
    final cards = ClashCardsLocalDataSource().parseCardsJson('''
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
    }
  ]
}
''');

    final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(cards));
    final collectionRepo = createTestCollectionRepository(
      cardsRepository: cardsRepo,
    );
    await collectionRepo.grantMissingCardIds(['gk-1']);

    final lineupsRepo = ClashLineupsRepository(
      storage: InMemoryClashLineupsBackend(),
      cardsRepository: cardsRepo,
    );
    final controller = ClashLineupsController(
      lineupsRepository: lineupsRepo,
      collectionRepository: collectionRepo,
    );
    await controller.load();

    await tester.pumpWidget(await _lineupScreen(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Alineación 7vs7'), findsOneWidget);
    expect(find.textContaining('Alineación 1'), findsOneWidget);
    expect(find.text('Alineación 2'), findsOneWidget);
    expect(find.text('Alineación 3'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Potencia total'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Potencia total'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Establecer como activa'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Establecer como activa'), findsOneWidget);
    expect(find.text('Portero'), findsWidgets);
  });
}

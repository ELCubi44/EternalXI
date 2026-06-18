import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_collection_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'clash_test_support.dart';

const _sampleJson = '''
{
  "cards": [
    {
      "id": "ui-test-1",
      "playerId": 101,
      "name": "Marco Reyes",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "valiente",
      "position": "goalkeeper",
      "basicPortraitPath": "placeholder",
      "stats": {
        "save": 42,
        "defense": 18,
        "pass": 14,
        "dribble": 8,
        "shot": 6,
        "techniquePoints": 20,
        "stamina": 105
      },
      "superTechniques": [
        {
          "id": "ui-test-1-st",
          "name": "Muralla Eterna",
          "description": "Parada contundente.",
          "type": "save",
          "style": "valiente",
          "basePower": 48,
          "ptCost": 12,
          "level": "normal"
        }
      ]
    }
  ]
}
''';

class _FakeDataSource extends ClashCardsLocalDataSource {
  _FakeDataSource(this._cards);

  final List<ClashCardCatalogEntry> _cards;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _cards;
}

Future<
  (
    ClashCardsController,
    ClashPlayerCollectionRepository,
    ClashExpMaterialsRepository,
    ClashTechniqueBooksRepository,
    ClashEvolutionMaterialsRepository,
  )
>
_readyController() async {
  final cards = ClashCardsLocalDataSource().parseCardsJson(_sampleJson);
  final cardsRepo = ClashCardsRepository(_FakeDataSource(cards));
  final materialsRepo = createTestExpMaterialsRepository();
  final techniqueBooksRepo = createTestTechniqueBooksRepository();
  final evolutionMaterialsRepo = createTestEvolutionMaterialsRepository();
  final collectionRepo = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    expMaterialsRepository: materialsRepo,
    techniqueBooksRepository: techniqueBooksRepo,
    evolutionMaterialsRepository: evolutionMaterialsRepo,
  );
  await collectionRepo.grantMissingCardIds(['ui-test-1']);
  final controller = ClashCardsController(cardsRepo, collectionRepo);
  await controller.load();
  return (
    controller,
    collectionRepo,
    materialsRepo,
    techniqueBooksRepo,
    evolutionMaterialsRepo,
  );
}

GoRouter _cardsRouter(ClashCardsController controller) {
  return GoRouter(
    initialLocation: AppRoutes.clashCards,
    routes: [
      GoRoute(
        path: AppRoutes.clashCards,
        builder: (context, state) =>
            const Scaffold(body: ClashCardCollectionScreen()),
        routes: [
          GoRoute(
            path: ':cardId',
            builder: (context, state) => Scaffold(
              body: ClashCardDetailScreen(
                cardId: state.pathParameters['cardId'] ?? '',
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _routerApp(
  GoRouter router,
  ClashCardsController controller,
  ClashPlayerCollectionRepository collectionRepo,
  ClashExpMaterialsRepository materialsRepo,
  ClashTechniqueBooksRepository techniqueBooksRepo,
  ClashEvolutionMaterialsRepository evolutionMaterialsRepo,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ClashCardsController>.value(value: controller),
      Provider<ClashPlayerCollectionRepository>.value(value: collectionRepo),
      Provider<ClashExpMaterialsRepository>.value(value: materialsRepo),
      Provider<ClashTechniqueBooksRepository>.value(value: techniqueBooksRepo),
      Provider<ClashEvolutionMaterialsRepository>.value(
        value: evolutionMaterialsRepo,
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashCardCollectionScreen', () {
    testWidgets('renderiza cartas cargadas', (tester) async {
      final (controller, _, __, ___, ____) = await _readyController();
      await tester.pumpWidget(
        ChangeNotifierProvider<ClashCardsController>.value(
          value: controller,
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashCardCollectionScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marco Reyes'), findsOneWidget);
      expect(find.textContaining('PWR'), findsOneWidget);
    });

    testWidgets('pulsar carta abre detalle', (tester) async {
      final (
        controller,
        collectionRepo,
        materialsRepo,
        techniqueBooksRepo,
        evolutionMaterialsRepo,
      ) = await _readyController();
      final router = _cardsRouter(controller);
      await tester.pumpWidget(
        _routerApp(
          router,
          controller,
          collectionRepo,
          materialsRepo,
          techniqueBooksRepo,
          evolutionMaterialsRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ClashCardTile));
      await tester.pumpAndSettle();

      expect(find.text('Muralla Eterna'), findsOneWidget);
      expect(find.text('Parada'), findsWidgets);
      expect(find.text('Resistencia'), findsOneWidget);
    });
  });

  group('ClashCardDetailScreen', () {
    testWidgets('carta inexistente muestra error seguro', (tester) async {
      final (
        controller,
        collectionRepo,
        materialsRepo,
        techniqueBooksRepo,
        evolutionMaterialsRepo,
      ) = await _readyController();
      final router = GoRouter(
        initialLocation: AppRoutes.clashCardDetail('missing-id'),
        routes: [
          GoRoute(
            path: '/clash/cards/:cardId',
            builder: (context, state) => Scaffold(
              body: ClashCardDetailScreen(
                cardId: state.pathParameters['cardId'] ?? '',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        _routerApp(
          router,
          controller,
          collectionRepo,
          materialsRepo,
          techniqueBooksRepo,
          evolutionMaterialsRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carta no encontrada.'), findsOneWidget);
    });
  });
}

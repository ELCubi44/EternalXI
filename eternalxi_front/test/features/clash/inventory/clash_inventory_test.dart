import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/screens/clash_inventory_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

void main() {
  group('ClashInventoryRepository', () {
    late ClashInventoryRepository repository;

    setUp(() {
      repository = createTestInventoryRepository();
    });

    test('carga materiales EXP', () async {
      final items = await repository.fetchAllItems();
      final exp = items.where(
        (item) => item.category == ClashInventoryCategory.exp,
      );
      expect(exp, hasLength(3));
      expect(exp.first.name, contains('Manual'));
    });

    test('carga libros de técnica', () async {
      final items = await repository.fetchAllItems();
      final books = items.where(
        (item) => item.category == ClashInventoryCategory.technique,
      );
      expect(books, hasLength(3));
      expect(books.first.name, contains('Libro'));
    });

    test('carga materiales evolución', () async {
      final items = await repository.fetchAllItems();
      final evolution = items.where(
        (item) => item.category == ClashInventoryCategory.evolution,
      );
      expect(evolution, hasLength(2));
      expect(evolution.map((e) => e.name), contains('Insignia R'));
    });

    test('carga objetos de partido', () async {
      final items = await repository.fetchAllItems();
      final match = items.where(
        (item) => item.category == ClashInventoryCategory.match,
      );
      expect(match, hasLength(2));
      expect(match.every((item) => item.isProvisionalMatchKit), isTrue);
    });

    test('combina categorías', () async {
      final items = await repository.fetchAllItems();
      final categories = items.map((item) => item.category).toSet();
      expect(categories, contains(ClashInventoryCategory.exp));
      expect(categories, contains(ClashInventoryCategory.technique));
      expect(categories, contains(ClashInventoryCategory.evolution));
      expect(categories, contains(ClashInventoryCategory.match));
      expect(categories, contains(ClashInventoryCategory.tickets));
    });

    test('carga tickets de invocación', () async {
      final items = await repository.fetchAllItems();
      final tickets = items.where(
        (item) => item.category == ClashInventoryCategory.tickets,
      );
      expect(tickets, hasLength(1));
      expect(tickets.single.quantity, 3);
    });

    test('respeta cantidades persistidas', () async {
      final expInventory = InMemoryClashExpMaterialInventoryBackend();
      await expInventory.writeSnapshot(
        const ClashExpMaterialInventorySnapshot(
          quantities: {'basic-training-manual': 9},
        ),
      );
      repository = createTestInventoryRepository(
        expMaterialsRepository: createTestExpMaterialsRepository(
          inventoryStorage: expInventory,
        ),
      );
      final items = await repository.fetchAllItems();
      final basic = items.firstWhere(
        (item) => item.id == 'basic-training-manual',
      );
      expect(basic.quantity, 9);
    });

    test('muestra 0 si no hay cantidad', () async {
      final booksInventory = InMemoryClashTechniqueBookInventoryBackend();
      await booksInventory.writeSnapshot(
        const ClashTechniqueBookInventorySnapshot(
          quantities: {'master-technique-book': 0},
        ),
      );
      repository = createTestInventoryRepository(
        techniqueBooksRepository: createTestTechniqueBooksRepository(
          inventoryStorage: booksInventory,
        ),
      );
      final items = await repository.fetchAllItems();
      final master = items.firstWhere(
        (item) => item.id == 'master-technique-book',
      );
      expect(master.quantity, 0);
    });

    test('totaliza correctamente', () async {
      final summary = await repository.fetchSummary();
      final items = await repository.fetchAllItems();
      final manualTotal = items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );
      expect(summary.totalQuantity, manualTotal);
      expect(summary.quantityFor(ClashInventoryCategory.match), 3);
    });

    test('no duplica items', () async {
      final first = await repository.fetchAllItems();
      final second = await repository.fetchAllItems();
      expect(first.map((item) => item.id).toSet().length, first.length);
      expect(
        second.map((item) => item.id).toList(),
        first.map((e) => e.id).toList(),
      );
    });
  });

  group('UI inventario', () {
    Widget inventoryApp(ClashInventoryRepository repository) {
      return Provider<ClashInventoryRepository>.value(
        value: repository,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ClashInventoryScreen(),
        ),
      );
    }

    Future<void> pumpInventory(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(inventoryApp(createTestInventoryRepository()));
      await tester.pumpAndSettle();
    }

    Future<void> scrollTo(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(
        find.text(text),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapFilter(WidgetTester tester, String label) async {
      final chip = find.widgetWithText(FilterChip, label);
      final filterScroll = find.descendant(
        of: find.byType(SingleChildScrollView).first,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(chip, 120, scrollable: filterScroll);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    testWidgets('pantalla inventario muestra título', (tester) async {
      await pumpInventory(tester);
      expect(find.text('Inventario'), findsOneWidget);
    });

    testWidgets('muestra categorías', (tester) async {
      await pumpInventory(tester);
      expect(find.text('Materiales EXP'), findsWidgets);
      expect(find.text('Libros de técnica'), findsWidgets);
      expect(find.text('Materiales de evolución'), findsWidgets);
      expect(find.text('Objetos de partido'), findsWidgets);
      expect(find.text('Tickets'), findsWidgets);
    });

    testWidgets('muestra materiales EXP', (tester) async {
      await pumpInventory(tester);
      expect(find.text('Manual básico de entrenamiento'), findsOneWidget);
    });

    testWidgets('muestra libros de técnica', (tester) async {
      await pumpInventory(tester);
      await scrollTo(tester, 'Libro técnico básico');
      expect(find.text('Libro técnico básico'), findsOneWidget);
    });

    testWidgets('muestra insignias evolución', (tester) async {
      await pumpInventory(tester);
      await scrollTo(tester, 'Insignia R');
      expect(find.text('Insignia R'), findsOneWidget);
      expect(find.text('Insignia SR'), findsOneWidget);
    });

    testWidgets('muestra objetos de partido como kit provisional', (
      tester,
    ) async {
      await pumpInventory(tester);
      await scrollTo(tester, 'Bebida técnica test');
      expect(find.text('Bebida técnica test'), findsOneWidget);
      expect(find.text('Kit provisional por partido'), findsWidgets);
    });

    testWidgets('filtro EXP solo muestra EXP', (tester) async {
      await pumpInventory(tester);
      await tapFilter(tester, 'Materiales EXP');
      await tester.pumpAndSettle();
      expect(find.text('Manual básico de entrenamiento'), findsOneWidget);
      expect(find.text('Libro técnico básico'), findsNothing);
      expect(find.text('Insignia R'), findsNothing);
      expect(find.text('Bebida técnica test'), findsNothing);
    });

    testWidgets('filtro Técnicas solo muestra libros', (tester) async {
      await pumpInventory(tester);
      await tapFilter(tester, 'Libros de técnica');
      await tester.pumpAndSettle();
      expect(find.text('Libro técnico básico'), findsOneWidget);
      expect(find.text('Manual básico de entrenamiento'), findsNothing);
    });

    testWidgets('filtro Evolución solo muestra insignias', (tester) async {
      await pumpInventory(tester);
      await tapFilter(tester, 'Materiales de evolución');
      await tester.pumpAndSettle();
      expect(find.text('Insignia R'), findsOneWidget);
      expect(find.text('Manual básico de entrenamiento'), findsNothing);
    });

    testWidgets('filtro Partido solo muestra objetos de partido', (
      tester,
    ) async {
      await pumpInventory(tester);
      await tapFilter(tester, 'Objetos de partido');
      await tester.pumpAndSettle();
      expect(find.text('Bebida técnica test'), findsOneWidget);
      expect(find.text('Manual básico de entrenamiento'), findsNothing);
    });

    testWidgets('muestra total de ítems en resumen', (tester) async {
      await pumpInventory(tester);
      expect(find.textContaining('Total de unidades:'), findsOneWidget);
    });

    testWidgets('muestra chips de categorías en resumen', (tester) async {
      await pumpInventory(tester);
      expect(find.textContaining('Materiales EXP:'), findsOneWidget);
      expect(find.textContaining('Tickets:'), findsWidgets);
    });

    testWidgets('filtro Tickets funciona', (tester) async {
      await pumpInventory(tester);
      await tapFilter(tester, 'Tickets');
      await tester.pumpAndSettle();
      expect(find.text('Ticket de invocación inicial'), findsOneWidget);
      expect(find.text('Manual básico de entrenamiento'), findsNothing);
    });

    testWidgets('item tile muestra cantidad y uso', (tester) async {
      await pumpInventory(tester);
      expect(find.textContaining('×'), findsWidgets);
      expect(find.text('Usar desde detalle de carta'), findsWidgets);
      expect(find.text('Usar en Invocar'), findsOneWidget);
    });

    testWidgets('cantidad 0 se muestra atenuada', (tester) async {
      final booksInventory = InMemoryClashTechniqueBookInventoryBackend();
      await booksInventory.writeSnapshot(
        const ClashTechniqueBookInventorySnapshot(
          quantities: {'master-technique-book': 0},
        ),
      );
      await tester.pumpWidget(
        inventoryApp(
          createTestInventoryRepository(
            techniqueBooksRepository: createTestTechniqueBooksRepository(
              inventoryStorage: booksInventory,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Libro técnico maestro'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Libro técnico maestro'), findsOneWidget);
      expect(find.text('Sin stock'), findsOneWidget);
    });

    testWidgets('filtro vacío muestra empty state y CTA va a tienda', (
      tester,
    ) async {
      final nav = ClashNavigationController();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ClashNavigationController>.value(value: nav),
            Provider<ClashInventoryRepository>.value(
              value: _ExpOnlyInventoryRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashInventoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapFilter(tester, 'Libros de técnica');
      expect(find.text('No hay ítems en esta categoría'), findsOneWidget);
      expect(find.text('Ir a tienda'), findsOneWidget);
      await tester.tap(find.text('Ir a tienda'));
      await tester.pump();
      expect(nav.tabIndex, 3);
    });

    testWidgets('no overflow en viewport móvil', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(inventoryApp(createTestInventoryRepository()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _ExpOnlyInventoryRepository extends ClashInventoryRepository {
  _ExpOnlyInventoryRepository()
    : super(
        expMaterialsRepository: createTestExpMaterialsRepository(),
        techniqueBooksRepository: createTestTechniqueBooksRepository(),
        evolutionMaterialsRepository: createTestEvolutionMaterialsRepository(),
        ticketRepository: createTestTicketRepository(),
      );

  @override
  Future<List<ClashInventoryItem>> fetchAllItems() async {
    final all = await super.fetchAllItems();
    return all
        .where((item) => item.category == ClashInventoryCategory.exp)
        .toList(growable: false);
  }
}

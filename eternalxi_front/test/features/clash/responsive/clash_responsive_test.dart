import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clash_responsive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({
      ClashSharedPreferencesKeys.schemaVersion: 1,
      ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
    });
  });

  Future<void> runResponsiveCase(
    WidgetTester tester, {
    required String label,
    required Size viewport,
    required Future<Widget> Function() buildWidget,
    Duration asyncWait = const Duration(milliseconds: 400),
    Future<void> Function(WidgetTester tester)? afterPump,
  }) async {
    await resetResponsiveTestSurface(tester);

    configureClashResponsiveViewport(tester, viewport);
    await applyClashResponsiveSurface(tester, viewport);

    final result = await pumpResponsiveWidget(
      tester,
      buildWidget,
      asyncWait: asyncWait,
    );
    if (afterPump != null) {
      await afterPump(tester);
    }
    await pumpUntilSettled(tester);
    expectNoFlutterLayoutErrors(tester, pumpResult: result);
  }

  group('Clash responsive Fase 63', () {
    for (final viewport in ClashResponsiveViewports.all) {
      testWidgets('A) Home ${viewportLabel(viewport)}', (tester) async {
        await runResponsiveCase(
          tester,
          label: 'Home',
          viewport: viewport,
          buildWidget: buildClashHomeScreen,
          asyncWait: const Duration(milliseconds: 600),
        );
        expect(find.text('Eternal Clash'), findsOneWidget);
      });
    }

    testWidgets('B) Story map and reward smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Story map',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashStoryMapScreen,
        asyncWait: const Duration(milliseconds: 800),
        afterPump: (tester) async {
          await pumpUntilFinder(tester, find.text('Historia'));
        },
      );
      expect(find.byType(ClashStoryMapScreen), findsOneWidget);
      expect(find.text('Historia'), findsWidgets);

      await runResponsiveCase(
        tester,
        label: 'Story reward',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashStoryRewardScreen,
        asyncWait: const Duration(milliseconds: 600),
      );
      expect(find.text('Nivel completado'), findsWidgets);
    });

    for (final viewport in ClashResponsiveViewports.denseScreens) {
      testWidgets('C) Events list ${viewportLabel(viewport)}', (tester) async {
        await runResponsiveCase(
          tester,
          label: 'Events list',
          viewport: viewport,
          buildWidget: buildClashEventsListScreen,
          asyncWait: const Duration(milliseconds: 800),
        );
        expect(find.text('Entrenamiento de Arin'), findsOneWidget);
      });

      testWidgets('C) Events detail Mika ${viewportLabel(viewport)}', (
        tester,
      ) async {
        await runResponsiveCase(
          tester,
          label: 'Events detail',
          viewport: viewport,
          buildWidget: buildClashMikaDetailScreen,
          asyncWait: const Duration(milliseconds: 800),
        );
        expect(find.text('Carrera de Mika'), findsOneWidget);
      });
    }

    testWidgets('C) Events match prepare Mika dense viewports', (tester) async {
      for (final viewport in [
        ClashResponsiveViewports.smallPhone,
        ClashResponsiveViewports.mediumPhone,
      ]) {
        await runResponsiveCase(
          tester,
          label: 'Events match prepare ${viewportLabel(viewport)}',
          viewport: viewport,
          buildWidget: buildClashMikaMatchPrepareScreen,
          asyncWait: const Duration(milliseconds: 300),
          afterPump: (tester) async {
            await pumpUntilFinder(
              tester,
              find.text('Pases a toda velocidad'),
              maxSteps: 80,
            );
            await scrollUntilVisibleSafe(tester, find.text('Preparar equipo'));
          },
        );
        expect(find.text('Alineación activa incompleta'), findsOneWidget);
        expect(find.text('Preparar equipo'), findsOneWidget);
      }
    });

    testWidgets('D) Gifts smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Gifts',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashGiftsScreen,
      );
      expect(find.text('Reclamar'), findsWidgets);
    });

    testWidgets('E) Daily missions smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Daily missions',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashDailyMissionsScreen,
      );
      expect(find.text('Juega un partido'), findsOneWidget);
    });

    testWidgets('E) Weekly missions smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Weekly missions',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashWeeklyMissionsScreen,
      );
      expect(find.text('Misiones semanales'), findsOneWidget);
    });

    testWidgets('F) Achievements smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Achievements',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashAchievementsScreen,
      );
      expect(find.text('Primer partido'), findsOneWidget);
    });

    for (final viewport in ClashResponsiveViewports.denseScreens) {
      testWidgets('G) Shop ${viewportLabel(viewport)}', (tester) async {
        await runResponsiveCase(
          tester,
          label: 'Shop',
          viewport: viewport,
          buildWidget: buildClashShopScreen,
        );
        expect(find.text('Pack entrenamiento básico'), findsOneWidget);
      });

      testWidgets('G) Shop confirm dialog ${viewportLabel(viewport)}', (
        tester,
      ) async {
        await resetResponsiveTestSurface(tester);
        configureClashResponsiveViewport(tester, viewport);
        await applyClashResponsiveSurface(tester, viewport);

        final result = await pumpResponsiveWidget(tester, buildClashShopScreen);
        expectNoFlutterLayoutErrors(tester, pumpResult: result);

        await tester.tap(find.text('Comprar').first);
        final dialogResult = await collectFlutterErrorsDuringPump(
          tester,
          () async {
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        );
        expect(find.text('Confirmar compra'), findsOneWidget);
        expectNoFlutterLayoutErrors(tester, pumpResult: dialogResult);
      });
    }

    for (final viewport in ClashResponsiveViewports.denseScreens) {
      testWidgets('H) Inventory ${viewportLabel(viewport)}', (tester) async {
        await runResponsiveCase(
          tester,
          label: 'Inventory',
          viewport: viewport,
          buildWidget: buildClashInventoryScreen,
          asyncWait: const Duration(milliseconds: 300),
          afterPump: (tester) async {
            await pumpUntilFinder(
              tester,
              find.text('Manual básico de entrenamiento'),
              maxSteps: 80,
            );
          },
        );
        expect(find.text('Inventario'), findsOneWidget);
        final scrollResult = await collectFlutterErrorsDuringPump(
          tester,
          () => scrollUntilVisibleSafe(tester, find.text('Ver historial')),
        );
        expect(find.text('Ver historial'), findsOneWidget);
        expectNoFlutterLayoutErrors(tester, pumpResult: scrollResult);
      });
    }

    testWidgets('I) Reward history empty smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Reward history empty',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashRewardHistoryEmptyScreen,
      );
      expect(find.text('Aún no hay recompensas registradas.'), findsOneWidget);
    });

    testWidgets('I) Reward history filled smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Reward history filled',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashRewardHistoryFilledScreen,
      );
      expect(find.text('Historial de recompensas'), findsOneWidget);
    });

    testWidgets('J) Debug dense viewports', (tester) async {
      for (final viewport in ClashResponsiveViewports.denseScreens) {
        await runResponsiveCase(
          tester,
          label: 'Debug ${viewportLabel(viewport)}',
          viewport: viewport,
          buildWidget: buildClashDebugScreen,
          asyncWait: Duration.zero,
          afterPump: pumpUntilDebugLoaded,
        );
        expect(find.text('Diagnóstico Clash'), findsOneWidget);
        expect(find.text('Sincronización online'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Almacenamiento local'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Almacenamiento local'), findsOneWidget);
      }
    });

    testWidgets('K) Help smallPhone', (tester) async {
      await runResponsiveCase(
        tester,
        label: 'Help',
        viewport: ClashResponsiveViewports.smallPhone,
        buildWidget: buildClashHelpScreen,
        asyncWait: const Duration(milliseconds: 800),
        afterPump: (tester) async {
          await pumpUntilFinder(tester, find.text('¿Qué es Eternal Clash?'));
        },
      );
      expect(find.text('Guía Clash'), findsOneWidget);
      expect(find.text('Consejo rápido'), findsOneWidget);
      final scrollResult = await collectFlutterErrorsDuringPump(
        tester,
        () => scrollUntilVisibleSafe(tester, find.text('Diagnóstico local')),
      );
      expect(find.text('Diagnóstico local'), findsOneWidget);
      expectNoFlutterLayoutErrors(tester, pumpResult: scrollResult);
    });
  });
}

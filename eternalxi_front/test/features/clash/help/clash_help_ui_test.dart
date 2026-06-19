import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

late ClashHelpTopicsLocalDataSource _helpDataSource;

ClashHelpRepository _helpRepository() {
  return ClashHelpRepository(dataSource: _helpDataSource);
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 40,
}) async {
  for (var step = 0; step < maxSteps; step++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('No se encontró $finder tras esperar');
}

Future<void> _resetTesterSurface(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _helpDataSource = ClashHelpTopicsLocalDataSource();
    _helpDataSource.clearCacheForTests();
  });

  group('ClashHelp UI Fase 51', () {
    testWidgets('Home muestra acceso Ayuda', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final deps = await createTestMissionsSetup();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ChangeNotifierProvider(
            create: (_) => ClashStoryController(storyRepository: deps.story),
            child: const ClashHomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Guía Clash'), findsOneWidget);

      await _resetTesterSurface(tester);
    });

    testWidgets('Help screen lista, filtra y busca', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Provider<ClashHelpRepository>.value(
            value: _helpRepository(),
            child: const ClashHelpScreen(),
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text('¿Qué es Eternal Clash?'));

      expect(find.text('Guía Clash'), findsOneWidget);
      expect(find.text('Consejo rápido'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Partido'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Partidos y duelos'));
      expect(find.text('PT y resistencia'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Todos'));
      await tester.pump();
      await _pumpUntilFound(tester, find.text('¿Qué es Eternal Clash?'));

      await tester.enterText(find.byType(TextField), 'zzznoresultado');
      await _pumpUntilFound(tester, find.text('Sin resultados'));

      await tester.enterText(find.byType(TextField), '');
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await _resetTesterSurface(tester);
    });

    testWidgets('no overflow en viewport móvil', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Provider<ClashHelpRepository>.value(
            value: _helpRepository(),
            child: const ClashHelpScreen(),
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text('Guía Clash'));

      expect(tester.takeException(), isNull);

      await _resetTesterSurface(tester);
    });
  });
}

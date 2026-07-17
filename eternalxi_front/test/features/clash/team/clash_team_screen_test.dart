import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/team/presentation/clash_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Widget> _teamApp() async {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const Scaffold(body: ClashTeamScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('ClashTeamScreen', () {
    testWidgets('por ahora solo muestra Personajes', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(await _teamApp());
      await tester.pumpAndSettle();

      expect(find.text('Personajes'), findsOneWidget);
      expect(find.text('Alineación 7vs7'), findsNothing);
      expect(find.text('Inventario'), findsNothing);
      expect(find.text('Mejorar cartas'), findsNothing);
      expect(find.text('Resumen del equipo'), findsNothing);
    });
  });
}

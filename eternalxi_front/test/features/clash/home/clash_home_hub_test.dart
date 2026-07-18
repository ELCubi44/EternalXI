import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_events_button.dart';
import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_story_map_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('ClashHome hub UI', () {
    testWidgets('muestra Historia y Eventos bloqueados', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ClashHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClashHomeScreen), findsOneWidget);
      expect(find.byType(ClashHomeStoryMapButton), findsOneWidget);
      expect(find.byType(ClashHomeEventsButton), findsOneWidget);
      expect(find.text('HISTORIA'), findsOneWidget);
      expect(find.text('EVENTOS'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });
}

import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
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
    testWidgets('muestra el fondo del instituto a pantalla completa', (
      tester,
    ) async {
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
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  ClashHomeScreen.backgroundAsset,
        ),
        findsOneWidget,
      );
      expect(find.text('Historia'), findsNothing);
      expect(find.text('Eventos'), findsNothing);
    });
  });
}

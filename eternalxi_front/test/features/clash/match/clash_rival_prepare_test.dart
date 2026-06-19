import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_rival_prepare_section.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashMatchRivalPrepareSection', () {
    late ClashRivalTeam trainingTeam;
    late ClashRivalTeam arinTeam;

    setUpAll(() async {
      final repo = ClashRivalsRepository();
      trainingTeam = (await repo.findTeam('rival-training-squad'))!;
      arinTeam = (await repo.findTeam('rival-arin-training'))!;
    });

    Widget section({
      required int ownPower,
      ClashRivalTeam? rivalTeam,
      int? fallbackRecommendedPower,
    }) {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ListView(
            children: [
              ClashMatchRivalPrepareSection(
                ownPower: ownPower,
                rivalTeam: rivalTeam,
                fallbackRecommendedPower: fallbackRecommendedPower,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('ficha, comparativa, expansión y fallback', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(section(ownPower: 85, rivalTeam: trainingTeam));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Equipo de entrenamiento'), findsOneWidget);
      expect(find.text('7/7 jugadores'), findsOneWidget);
      expect(find.text('Tu potencia'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('Potencia rival'), findsWidgets);
      expect(find.text('Partido igualado'), findsOneWidget);
      expect(find.text('Dificultad 1 · Fácil'), findsOneWidget);

      await tester.tap(find.text('Ver alineación rival'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Portero Prueba'), findsOneWidget);

      await tester.pumpWidget(
        section(ownPower: 50, fallbackRecommendedPower: 120),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Rival estándar'), findsOneWidget);

      await tester.pumpWidget(section(ownPower: 90, rivalTeam: arinTeam));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Grupo de Arin'), findsOneWidget);
      expect(find.text('Dificultad 2 · Normal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

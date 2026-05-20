import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_participant_lineup_history.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_timeline_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LeagueSquadPlayer _player(int idLigaJugador) {
  return LeagueSquadPlayer(
    idLigaJugador: idLigaJugador,
    idJugador: idLigaJugador,
    nombre: 'J$idLigaJugador',
    pila: '',
    posicion: 'DEL',
    valoracion: 80,
    idEquipo: 1,
    nombreEquipo: 'Equipo',
    estado: 'DISPONIBLE',
    cansancio: 0,
    valor: 1e6,
    fotoJugador: '',
    enPoolMercado: false,
    propietarioNick: '',
    idUsuarioDueno: 0,
  );
}

LeagueMatchRoster _rosterLocal({required Set<int> ids}) {
  final map = {for (final id in ids) id: _player(id)};
  return LeagueMatchRoster(
    localPlayerIds: ids,
    awayPlayerIds: const {},
    playersById: map,
  );
}

LeagueMatchRoster _rosterAway({required Set<int> ids}) {
  final map = {for (final id in ids) id: _player(id)};
  return LeagueMatchRoster(
    localPlayerIds: const {},
    awayPlayerIds: ids,
    playersById: map,
  );
}

void main() {
  group('Modelo: CESION vs CAMBIO', () {
    test('CESION_PARTIDO no cuenta como sustitución', () {
      final e = LeagueMatchEvent(
        idEvento: 1,
        minuto: 0,
        segundo: 0,
        tipo: 'CESION_PARTIDO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 10,
        jugadorPrincipal: 'N',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Ha sido cedido',
      );
      expect(leagueMatchEventTipoCambioSustitucion(e), isFalse);
      expect(isLoanGroupedEvent(e), isFalse);
      expect(isLoanIndividualEvent(e), isTrue);
    });

    test('CAMBIO cuenta como sustitución y no como cesión individual', () {
      final e = LeagueMatchEvent(
        idEvento: 2,
        minuto: 60,
        segundo: 0,
        tipo: 'CAMBIO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 10,
        jugadorPrincipal: 'Entra',
        idLigaJugadorSecundario: 5,
        jugadorSecundario: 'Sale',
        texto: 'Entra cedido X por Y',
      );
      expect(leagueMatchEventTipoCambioSustitucion(e), isTrue);
      expect(isLoanIndividualEvent(e), isFalse);
    });

    test('CESIONES_PARTIDO es agrupado', () {
      final e = LeagueMatchEvent(
        idEvento: 3,
        minuto: 0,
        segundo: 0,
        tipo: 'CESIONES_PARTIDO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 0,
        jugadorPrincipal: '',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Resumen cesiones',
      );
      expect(isLoanGroupedEvent(e), isTrue);
      expect(leagueMatchEventTipoCambioSustitucion(e), isFalse);
    });
  });

  group('Última jornada disponible (perfil otro participante)', () {
    test('elige mayor numeroJornada con alineacionDisponible', () {
      final jornadas = [
        const LeagueParticipantLineupRoundSummary(
          idJornada: 1,
          numeroJornada: 3,
          estadoJornada: 'FINALIZADA',
          inicioJornada: null,
          alineacionDisponible: true,
          puntosTotales: 0,
        ),
        const LeagueParticipantLineupRoundSummary(
          idJornada: 2,
          numeroJornada: 7,
          estadoJornada: 'EN_CURSO',
          inicioJornada: null,
          alineacionDisponible: true,
          puntosTotales: 0,
        ),
        const LeagueParticipantLineupRoundSummary(
          idJornada: 3,
          numeroJornada: 9,
          estadoJornada: 'PENDIENTE',
          inicioJornada: null,
          alineacionDisponible: false,
          puntosTotales: 0,
        ),
      ];
      final withLineup = jornadas
          .where((j) => j.alineacionDisponible)
          .toList(growable: false);
      final sorted = [...withLineup]
        ..sort((a, b) => a.numeroJornada.compareTo(b.numeroJornada));
      expect(sorted.last.numeroJornada, 7);
      expect(sorted.last.idJornada, 2);
    });
  });

  group('Cronología widget', () {
    testWidgets('CAMBIO local: dos fotos red + swap, sin bloque agrupado', (
      tester,
    ) async {
      final roster = _rosterLocal(ids: {10, 5});
      final event = LeagueMatchEvent(
        idEvento: 10,
        minuto: 60,
        segundo: 0,
        tipo: 'CAMBIO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 10,
        jugadorPrincipal: 'Entra',
        idLigaJugadorSecundario: 5,
        jugadorSecundario: 'Sale',
        texto: 'Sustitución local',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeagueMatchTimelineTab(
                roster: roster,
                events: [event],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
      expect(find.textContaining('Sustitución local'), findsOneWidget);
      expect(find.byType(ClipOval), findsNWidgets(2));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth == double.infinity &&
              (w.decoration is BoxDecoration) &&
              ((w.decoration! as BoxDecoration).borderRadius ==
                  BorderRadius.circular(14)),
        ),
        findsNothing,
      );
    });

    testWidgets('CAMBIO con URLs principal/secundario para cedidos', (
      tester,
    ) async {
      final roster = _rosterLocal(ids: {10, 5});
      final event = LeagueMatchEvent(
        idEvento: 11,
        minuto: 61,
        segundo: 0,
        tipo: 'CAMBIO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 10,
        jugadorPrincipal: 'Entra',
        idLigaJugadorSecundario: 5,
        jugadorSecundario: 'Sale',
        texto: 'Cambio cedido',
        fotoUrlJugadorPrincipal: 'https://example.com/entra.jpg',
        fotoUrlJugadorSecundario: 'https://example.com/sale.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeagueMatchTimelineTab(roster: roster, events: [event]),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('CESION_PARTIDO: una cara + texto (no dos fotos de cambio)', (
      tester,
    ) async {
      final roster = _rosterLocal(ids: {99});
      final event = LeagueMatchEvent(
        idEvento: 12,
        minuto: 0,
        segundo: 0,
        tipo: 'CESION_PARTIDO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 99,
        jugadorPrincipal: 'Cedido',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Ha sido cedido',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeagueMatchTimelineTab(roster: roster, events: [event]),
          ),
        ),
      );
      await tester.pump();

      expect(leagueMatchEventTipoCambioSustitucion(event), isFalse);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('CESIONES_PARTIDO: bloque resumen ancho completo', (
      tester,
    ) async {
      final roster = _rosterLocal(ids: {1});
      final event = LeagueMatchEvent(
        idEvento: 13,
        minuto: 0,
        segundo: 0,
        tipo: 'CESIONES_PARTIDO',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 0,
        jugadorPrincipal: '',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Varias cesiones…',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeagueMatchTimelineTab(roster: roster, events: [event]),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration is BoxDecoration) &&
              ((w.decoration! as BoxDecoration).borderRadius ==
                  BorderRadius.circular(14)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('GOL local: icono balón + texto alineado', (tester) async {
      final roster = _rosterLocal(ids: {7});
      final event = LeagueMatchEvent(
        idEvento: 14,
        minuto: 12,
        segundo: 0,
        tipo: 'GOL',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 7,
        jugadorPrincipal: 'Delantero',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Gol de Delantero',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeagueMatchTimelineTab(roster: roster, events: [event]),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
      expect(find.textContaining('12′'), findsWidgets);
    });

    testWidgets('ASISTENCIA visitante: icono + texto a la derecha', (
      tester,
    ) async {
      final roster = _rosterAway(ids: {8});
      final event = LeagueMatchEvent(
        idEvento: 15,
        minuto: 20,
        segundo: 0,
        tipo: 'ASISTENCIA',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 8,
        jugadorPrincipal: 'Medio',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Asistencia',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeagueMatchTimelineTab(roster: roster, events: [event]),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.sports_handball_outlined), findsOneWidget);
      final textFinder = find.textContaining('Asistencia');
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.textAlign, TextAlign.right);
    });

    testWidgets('TARJETA_AMARILLA y TARJETA_ROJA muestran iconos', (
      tester,
    ) async {
      final roster = _rosterLocal(ids: {3, 4});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LeagueMatchTimelineTab(
                  roster: roster,
                  events: [
                    LeagueMatchEvent(
                      idEvento: 20,
                      minuto: 30,
                      segundo: 0,
                      tipo: 'TARJETA_AMARILLA',
                      replayOffsetSec: 0,
                      idLigaJugadorPrincipal: 3,
                      jugadorPrincipal: 'A',
                      idLigaJugadorSecundario: 0,
                      jugadorSecundario: '',
                      texto: 'Amarilla',
                    ),
                    LeagueMatchEvent(
                      idEvento: 21,
                      minuto: 31,
                      segundo: 0,
                      tipo: 'TARJETA_ROJA',
                      replayOffsetSec: 0,
                      idLigaJugadorPrincipal: 4,
                      jugadorPrincipal: 'B',
                      idLigaJugadorSecundario: 0,
                      jugadorSecundario: '',
                      texto: 'Roja',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.style_rounded), findsOneWidget);
      expect(find.byIcon(Icons.report_rounded), findsOneWidget);
    });

    testWidgets('LESION con icono médico', (tester) async {
      final roster = _rosterLocal(ids: {2});
      final event = LeagueMatchEvent(
        idEvento: 22,
        minuto: 40,
        segundo: 0,
        tipo: 'LESION_JUGADOR',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 2,
        jugadorPrincipal: 'Les',
        idLigaJugadorSecundario: 0,
        jugadorSecundario: '',
        texto: 'Lesión',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeagueMatchTimelineTab(roster: roster, events: [event]),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.medical_services), findsOneWidget);
    });
  });
}

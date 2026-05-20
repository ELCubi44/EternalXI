import 'package:eternal_xi/data/models/league_player_detail.dart';
import 'package:eternal_xi/features/leagues/utils/league_saves_stat_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('displayFantasyTotalPoints', () {
    test('prioriza puntosFantasyTotales del backend', () {
      final detail = LeaguePlayerDetail.fromJson({
        'idLigaJugador': 1,
        'idJugador': 2,
        'nombre': 'Test',
        'pila': 'T',
        'posicion': 'POR',
        'valoracion': 80,
        'idEquipo': 3,
        'nombreEquipo': 'Eq',
        'estado': 'DISPONIBLE',
        'cansancio': 0,
        'valor': 1000,
        'valorAnterior': 1000,
        'fotoJugador': '',
        'puntosTotales': 5,
        'puntosFantasyTotales': 42,
        'estadisticasJornadas': [],
      });
      expect(detail.displayFantasyTotalPoints, 42);
    });

    test('sin puntosFantasyTotales usa puntosTotales', () {
      final detail = LeaguePlayerDetail.fromJson({
        'idLigaJugador': 1,
        'idJugador': 2,
        'nombre': 'Test',
        'pila': 'T',
        'posicion': 'POR',
        'valoracion': 80,
        'idEquipo': 3,
        'nombreEquipo': 'Eq',
        'estado': 'DISPONIBLE',
        'cansancio': 0,
        'valor': 1000,
        'valorAnterior': 1000,
        'fotoJugador': '',
        'puntosTotales': 18,
        'estadisticasJornadas': [],
      });
      expect(detail.displayFantasyTotalPoints, 18);
    });
  });

  group('7 paradas en UI', () {
    test('muestra +3 pts solo con desglose oficial', () {
      expect(
        leagueParadasStatDisplayValue(7, officialPoints: 3),
        '7 · +3 pts',
      );
      expect(
        leagueParadasStatDisplayValue(7, officialPoints: null),
        '7',
      );
    });
  });
}

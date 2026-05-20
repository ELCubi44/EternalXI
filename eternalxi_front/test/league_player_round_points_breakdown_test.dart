import 'package:eternal_xi/data/models/league_player_round_stats.dart';
import 'package:eternal_xi/features/leagues/utils/league_round_stat_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('puntosDesglose', () {
    test('parsea desglose oficial del backend', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 1,
        'numeroJornada': 2,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 1,
        'asistencias': 0,
        'golesEncajados': 0,
        'porteriaCero': true,
        'paradas': 8,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'puntos': 17,
        'puntosDesglose': {
          'goles': 6,
          'paradas': 4,
          'minutos': 3,
        },
      });
      expect(s.puntosDesglose.goles, 6);
      expect(s.puntosDesglose.paradas, 4);
      expect(
        leagueRoundStatDisplayValue('8', officialPoints: s.puntosDesglose.paradas),
        '8 | +4',
      );
    });

    test('sin desglose no inventa impactos', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 1,
        'numeroJornada': 1,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 2,
        'asistencias': 0,
        'golesEncajados': 0,
        'porteriaCero': false,
        'paradas': 6,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'puntos': 10,
      });
      expect(s.puntosDesglose.hasAny, isFalse);
      expect(leagueRoundStatDisplayValue('2', officialPoints: null), '2');
      expect(leagueRoundStatDisplayValue('6', officialPoints: null), '6');
    });

    test('7 paradas con puntosDesglose.paradas=3 se pinta +3', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 1,
        'numeroJornada': 1,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'golesEncajados': 0,
        'porteriaCero': false,
        'paradas': 7,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'puntos': 6,
        'puntosDesglose': {'paradas': 3, 'total': 6},
      });
      expect(s.paradas, 7);
      expect(s.puntosDesglose.paradas, 3);
      expect(
        leagueRoundStatDisplayValue('7', officialPoints: s.puntosDesglose.paradas),
        '7 | +3',
      );
    });

    test('legacy puntosFantasyParadas se mapea a desglose.paradas', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 1,
        'numeroJornada': 1,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'golesEncajados': 0,
        'porteriaCero': false,
        'paradas': 8,
        'puntosFantasyParadas': 4,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'puntos': 4,
      });
      expect(s.puntosDesglose.paradas, 4);
    });
  });
}

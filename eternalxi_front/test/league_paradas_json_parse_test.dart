import 'package:eternal_xi/data/models/league_participant_lineup_history.dart';
import 'package:eternal_xi/data/models/league_player_round_stat.dart';
import 'package:eternal_xi/data/models/league_player_round_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaguePlayerRoundStats paradas', () {
    test('fromJson lee paradas numéricas', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 181,
        'numeroJornada': 1,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'golesEncajados': 1,
        'porteriaCero': false,
        'paradas': 4,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'notaPeriodico': 6.5,
        'puntos': 5,
      });
      expect(s.paradas, 4);
      expect(s.puntosDesglose.paradas, isNull);
    });

    test('fromJson lee desglose puntosParadas del backend', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 181,
        'numeroJornada': 1,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'golesEncajados': 1,
        'porteriaCero': false,
        'paradas': 8,
        'puntosParadas': 4,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'notaPeriodico': 6.5,
        'puntos': 17,
      });
      expect(s.paradas, 8);
      expect(s.puntosDesglose.paradas, 4);
    });

    test('fromJson lee desglose puntosFantasyParadas del backend', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 181,
        'numeroJornada': 1,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'golesEncajados': 1,
        'porteriaCero': false,
        'paradas': 5,
        'puntosFantasyParadas': 2,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'notaPeriodico': 6.5,
        'puntos': 5,
      });
      expect(s.paradas, 5);
      expect(s.puntosDesglose.paradas, 2);
    });

    test('fromJson sin paradas usa 0', () {
      final s = LeaguePlayerRoundStats.fromJson({
        'idJornada': 1,
        'numeroJornada': 2,
        'estadoJornada': 'FINALIZADA',
        'minutosJugados': 90,
        'goles': 1,
        'asistencias': 0,
        'golesEncajados': 0,
        'porteriaCero': true,
        'regates': 0,
        'balonesRecuperados': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'lesionadoEnPartido': false,
        'puntos': 8,
      });
      expect(s.paradas, 0);
    });
  });

  group('LeagueParticipantLineupRoundPlayer paradas', () {
    test('fromJson lee paradas', () {
      final p = LeagueParticipantLineupRoundPlayer.fromJson({
        'idLigaJugador': 1459,
        'idJugador': 1,
        'nombre': 'Mark Evans',
        'pila': 'Evans',
        'nombreMostrado': 'Mark Evans',
        'posicion': 'POR',
        'valoracion': 80,
        'idEquipo': 1,
        'nombreEquipo': 'Eq',
        'fotoEquipo': '',
        'fotoJugador': '',
        'estado': 'DISPONIBLE',
        'cansancio': 0,
        'valor': 1,
        'titular': true,
        'capitan': true,
        'orden': 1,
        'puntosJornada': 5,
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'notaPeriodico': 6,
        'golesEncajados': 1,
        'porteriaCero': false,
        'lesionadoEnPartido': false,
        'paradas': 4,
        'regates': 0,
        'balonesRecuperados': 0,
      });
      expect(p.paradas, 4);
      expect(p.posicion, 'POR');
      expect(p.puntosFantasyParadas, isNull);
    });

    test('fromJson lee puntosDesglose.paradas en alineación jornada', () {
      final p = LeagueParticipantLineupRoundPlayer.fromJson({
        'idLigaJugador': 1459,
        'idJugador': 1,
        'nombre': 'Portero',
        'pila': 'POR',
        'nombreMostrado': 'POR',
        'posicion': 'POR',
        'valoracion': 80,
        'idEquipo': 1,
        'nombreEquipo': 'Equipo',
        'fotoEquipo': '',
        'fotoJugador': '',
        'estado': 'DISPONIBLE',
        'cansancio': 0,
        'valor': 1,
        'titular': true,
        'capitan': false,
        'orden': 1,
        'puntosJornada': 9,
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'notaPeriodico': 6.5,
        'golesEncajados': 1,
        'porteriaCero': false,
        'lesionadoEnPartido': false,
        'paradas': 7,
        'puntosDesglose': {'paradas': 3, 'total': 9},
        'regates': 0,
        'balonesRecuperados': 0,
      });
      expect(p.paradas, 7);
      expect(p.puntosDesglose.paradas, 3);
      expect(p.puntosFantasyParadasOficial, 3);
    });

    test('fromJson lee puntosFantasyParadas en alineación jornada', () {
      final p = LeagueParticipantLineupRoundPlayer.fromJson({
        'idLigaJugador': 1459,
        'idJugador': 1,
        'nombre': 'Mark Evans',
        'pila': 'Evans',
        'nombreMostrado': 'Mark Evans',
        'posicion': 'POR',
        'valoracion': 80,
        'idEquipo': 1,
        'nombreEquipo': 'Eq',
        'fotoEquipo': '',
        'fotoJugador': '',
        'estado': 'DISPONIBLE',
        'cansancio': 0,
        'valor': 1,
        'titular': true,
        'capitan': true,
        'orden': 1,
        'puntosJornada': 5,
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'notaPeriodico': 6,
        'golesEncajados': 1,
        'porteriaCero': false,
        'lesionadoEnPartido': false,
        'paradas': 4,
        'puntosFantasyParadas': 2,
        'regates': 0,
        'balonesRecuperados': 0,
      });
      expect(p.puntosFantasyParadas, 2);
    });

    test('fromJson sin paradas usa 0', () {
      final p = LeagueParticipantLineupRoundPlayer.fromJson({
        'idLigaJugador': 2,
        'idJugador': 2,
        'nombre': 'X',
        'pila': 'X',
        'nombreMostrado': 'X',
        'posicion': 'DEF',
        'valoracion': 70,
        'idEquipo': 1,
        'nombreEquipo': 'Eq',
        'fotoEquipo': '',
        'fotoJugador': '',
        'estado': 'DISPONIBLE',
        'cansancio': 0,
        'valor': 1,
        'titular': true,
        'capitan': false,
        'orden': 2,
        'puntosJornada': 3,
        'minutosJugados': 90,
        'goles': 0,
        'asistencias': 0,
        'tarjetasAmarillas': 0,
        'tarjetasRojas': 0,
        'notaPeriodico': 6,
        'golesEncajados': 0,
        'porteriaCero': false,
        'lesionadoEnPartido': false,
        'regates': 0,
        'balonesRecuperados': 5,
      });
      expect(p.paradas, 0);
    });
  });

  group('LeaguePlayerRoundStat paradas (fromBackend)', () {
    test('parsea paradas', () {
      final s = LeaguePlayerRoundStat.fromBackend({
        'idJornada': 5,
        'numeroJornada': 1,
        'paradas': 3,
        'puntos': 4,
      });
      expect(s.paradas, 3);
    });
  });
}

import 'package:eternal_xi/data/models/join_league_response.dart';
import 'package:eternal_xi/features/leagues/utils/league_config_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeagueConfigLabels.calendarLabel', () {
    test('solo fines de semana', () {
      expect(LeagueConfigLabels.calendarLabel(false), 'fines de semana');
    });

    test('fines de semana y entre semana', () {
      expect(
        LeagueConfigLabels.calendarLabel(true),
        'fines de semana + martes/miércoles',
      );
    });
  });

  group('JoinLeagueResponse.fromJson', () {
    test('parsea respuesta completa del backend', () {
      final r = JoinLeagueResponse.fromJson({
        'joined': true,
        'idLiga': 12,
        'idLigaParticipante': 456,
        'jugadoresAsignados': 9,
        'plantillaIncompleta': true,
        'valorPlantillaInicial': 1250000,
        'mensaje':
            'Has entrado en la liga. Tu plantilla inicial está incompleta (9 jugadores); podrás completarla en el mercado.',
      });
      expect(r.joined, isTrue);
      expect(r.idLiga, 12);
      expect(r.jugadoresAsignados, 9);
      expect(r.plantillaIncompleta, isTrue);
      expect(r.valorPlantillaInicial, 1250000);
      expect(r.isSuccess, isTrue);
      expect(r.postJoinNotice, isNotNull);
    });

    test('plantilla completa: sin aviso post-unión', () {
      final r = JoinLeagueResponse.fromJson({
        'joined': true,
        'idLiga': 12,
        'jugadoresAsignados': 15,
        'plantillaIncompleta': false,
      });
      expect(r.postJoinNotice, isNull);
    });

    test('menos de 15 jugadores sin plantilla incompleta: flujo normal', () {
      final r = JoinLeagueResponse.fromJson({
        'joined': true,
        'idLiga': 12,
        'jugadoresAsignados': 9,
        'plantillaIncompleta': false,
      });
      expect(r.isSuccess, isTrue);
      expect(r.postJoinNotice, isNull);
    });

    test('jugadoresAsignados 0 con plantilla incompleta: aviso', () {
      final r = JoinLeagueResponse.fromJson({
        'joined': true,
        'idLiga': 12,
        'jugadoresAsignados': 0,
        'plantillaIncompleta': true,
      });
      expect(r.isSuccess, isTrue);
      expect(
        r.postJoinNotice,
        'Has entrado en la liga, pero tu plantilla inicial está incompleta. Podrás completarla en el mercado.',
      );
    });

    test('compatibilidad: respuesta antigua solo con idLiga', () {
      final r = JoinLeagueResponse.fromJson({'idLiga': 12});
      expect(r.joined, isTrue);
      expect(r.jugadoresAsignados, isNull);
      expect(r.plantillaIncompleta, isNull);
      expect(r.valorPlantillaInicial, isNull);
      expect(r.postJoinNotice, isNull);
    });

    test('joined false no es éxito', () {
      final r = JoinLeagueResponse.fromJson({
        'joined': false,
        'idLiga': 12,
        'mensaje': 'Código inválido',
      });
      expect(r.isSuccess, isFalse);
    });
  });
}

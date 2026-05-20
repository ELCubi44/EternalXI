import 'package:eternal_xi/data/models/create_league_request.dart';
import 'package:eternal_xi/data/models/create_league_response.dart';
import 'package:eternal_xi/data/models/league_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateLeagueRequest.toJson', () {
    test('incluye campos avanzados cuando están definidos', () {
      final json = CreateLeagueRequest(
        nombre: 'Liga prueba',
        idTemporada: 1,
        idUsuario: 3,
        maxParticipantes: 12,
        semanaPreviaFichajes: true,
        permiteEntresemana: true,
        idaYVuelta: false,
        recompensaBaseJornada: 500,
        dineroPorPuntoFantasy: 200000,
      ).toJson();

      expect(json['nombre'], 'Liga prueba');
      expect(json['maxParticipantes'], 12);
      expect(json['semanaPreviaFichajes'], isTrue);
      expect(json['permiteEntresemana'], isTrue);
      expect(json['idaYVuelta'], isFalse);
      expect(json['recompensaBaseJornada'], 500);
      expect(json['dineroPorPuntoFantasy'], 200000);
      expect(json.containsKey('recompensaBonusGanador'), isFalse);
    });

    test('solo obligatorios para compatibilidad legacy', () {
      final json = const CreateLeagueRequest(
        nombre: 'X',
        idTemporada: 1,
        idUsuario: 1,
      ).toJson();

      expect(json.keys, containsAll(['nombre', 'idTemporada', 'idUsuario']));
      expect(json.containsKey('maxParticipantes'), isFalse);
    });
  });

  group('CreateLeagueResponse.fromJson', () {
    test('parsea respuesta completa', () {
      final r = CreateLeagueResponse.fromJson({
        'idLiga': 123,
        'maxParticipantes': 12,
        'semanaPreviaFichajes': true,
        'permiteEntresemana': true,
        'idaYVuelta': false,
        'recompensaBaseJornada': 500,
        'recompensaBonusGanador': 250,
        'dineroPorPuntoFantasy': 200000,
        'numeroJornadas': 15,
        'primerPartidoEn': '2026-05-26T17:00:00Z',
        'finLigaEn': '2026-08-30',
      });

      expect(r.idLiga, 123);
      expect(r.maxParticipantes, 12);
      expect(r.recompensaBonusGanador, 250);
      expect(r.numeroJornadas, 15);
      expect(r.primerPartidoEn, isNotNull);
      expect(r.isSuccess, isTrue);
    });

    test('compatibilidad solo idLiga', () {
      final r = CreateLeagueResponse.fromJson({'idLiga': 5});
      expect(r.idLiga, 5);
      expect(r.maxParticipantes, isNull);
    });
  });

  group('LeagueDetail configuración', () {
    test('mapea campos y detecta fase de fichajes', () {
      final future = DateTime.now().add(const Duration(days: 7));
      final d = LeagueDetail.fromJson({
        'id': 1,
        'nombre': 'Liga',
        'idTemporada': 1,
        'codigoInvitacion': 'ABC',
        'idAdministrador': 1,
        'soyAdmin': true,
        'participantes': 3,
        'miDinero': 0,
        'misPuntos': 0,
        'miValorEquipo': 0,
        'maxParticipantes': 12,
        'semanaPreviaFichajes': true,
        'permiteEntresemana': true,
        'idaYVuelta': false,
        'recompensaBaseJornada': 500,
        'dineroPorPuntoFantasy': 200000,
        'primerPartidoEn': future.toUtc().toIso8601String(),
      });

      expect(d.hasConfigSummary, isTrue);
      expect(d.maxParticipantes, 12);
      expect(d.isFichajesPhaseActive, isTrue);
    });
  });
}

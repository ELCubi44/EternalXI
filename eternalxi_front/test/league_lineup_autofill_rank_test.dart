import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_lineup_autofill_rank.dart';
import 'package:flutter_test/flutter_test.dart';

LeagueSquadPlayer _p({
  required int id,
  required String estado,
  int? pct,
  int idEquipo = 1,
  double valoracion = 70,
  double valor = 1e6,
}) {
  return LeagueSquadPlayer(
    idLigaJugador: id,
    idJugador: id,
    nombre: 'J$id',
    pila: 'J$id',
    posicion: 'DEL',
    valoracion: valoracion,
    idEquipo: idEquipo,
    nombreEquipo: 'E$idEquipo',
    estado: estado,
    cansancio: 0,
    valor: valor,
    fotoJugador: '',
    enPoolMercado: false,
    propietarioNick: 'u',
    idUsuarioDueno: 3,
    probabilidadTitular: pct,
  );
}

void main() {
  group('LeagueLineupAutofillRank', () {
    test('prefers 7% available over injured high-value', () {
      final low = _p(id: 1, estado: 'DISPONIBLE', pct: 7, valor: 1);
      final injured = _p(id: 2, estado: 'LESIONADO', pct: 0, valor: 99);
      expect(
        LeagueLineupAutofillRank.compare(
          low,
          injured,
          coachActive: false,
        ),
        lessThan(0),
      );
    });

    test('prefers coach club when active', () {
      final coachClub = _p(
        id: 1,
        estado: 'DISPONIBLE',
        pct: 40,
        idEquipo: 10,
      );
      final other = _p(
        id: 2,
        estado: 'DISPONIBLE',
        pct: 80,
        idEquipo: 99,
      );
      expect(
        LeagueLineupAutofillRank.compare(
          coachClub,
          other,
          coachActive: true,
          coachTeamId: 10,
        ),
        lessThan(0),
      );
      expect(
        LeagueLineupAutofillRank.compare(
          coachClub,
          other,
          coachActive: false,
          coachTeamId: 10,
        ),
        greaterThan(0),
      );
    });

    test('pickBest fills injured only after actives are used', () {
      final pool = [
        _p(id: 1, estado: 'DISPONIBLE', pct: 20),
        _p(id: 2, estado: 'DISPONIBLE', pct: 10),
        _p(id: 3, estado: 'LESIONADO', pct: 0, valor: 50),
        _p(id: 4, estado: 'SANCIONADO', pct: 0, valor: 40),
      ];
      final three = LeagueLineupAutofillRank.pickBest(
        pool: pool,
        needed: 3,
        coachActive: false,
        allowUnavailable: true,
      );
      expect(three.map((p) => p.idLigaJugador).toList(), [1, 2, 3]);

      final two = LeagueLineupAutofillRank.pickBest(
        pool: pool,
        needed: 2,
        coachActive: false,
        allowUnavailable: true,
      );
      expect(two.map((p) => p.idLigaJugador).toList(), [1, 2]);

      final reserveOnlyActive = LeagueLineupAutofillRank.pickBest(
        pool: pool,
        needed: 1,
        coachActive: false,
        excludeIds: {1, 2},
        allowUnavailable: false,
      );
      expect(reserveOnlyActive, isEmpty);
    });

    test('duda ranks below disponible but above lesionado', () {
      final ok = _p(id: 1, estado: 'DISPONIBLE', pct: 30);
      final doubt = _p(id: 2, estado: 'DUDA', pct: 90);
      final hurt = _p(id: 3, estado: 'LESIONADO', pct: 0);
      expect(
        LeagueLineupAutofillRank.compare(ok, doubt, coachActive: false),
        lessThan(0),
      );
      expect(
        LeagueLineupAutofillRank.compare(doubt, hurt, coachActive: false),
        lessThan(0),
      );
    });
  });
}

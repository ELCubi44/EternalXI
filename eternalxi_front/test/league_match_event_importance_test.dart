import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_event_importance.dart';
import 'package:flutter_test/flutter_test.dart';

LeagueMatchEvent _e(String tipo, {int minuto = 10, int sec = 0, int secPlayer = 0}) {
  return LeagueMatchEvent(
    idEvento: minuto * 100 + sec,
    minuto: minuto,
    segundo: sec,
    tipo: tipo,
    replayOffsetSec: 0,
    idLigaJugadorPrincipal: 1,
    jugadorPrincipal: 'A',
    idLigaJugadorSecundario: secPlayer,
    jugadorSecundario: secPlayer > 0 ? 'B' : '',
    texto: tipo,
  );
}

void main() {
  test('goals and cards are highlights', () {
    expect(isHighlightMatchEvent(_e('GOL')), isTrue);
    expect(isHighlightMatchEvent(_e('TARJETA_ROJA')), isTrue);
    expect(isHighlightMatchEvent(_e('PARADA')), isTrue);
  });

  test('recoveries are minor', () {
    expect(
      classifyLeagueMatchEventImportance(_e('RECUPERACION')),
      LeagueMatchEventImportance.minor,
    );
  });

  test('assist hidden when paired with goal', () {
    final ordered = [
      LeagueMatchEvent(
        idEvento: 1,
        minuto: 22,
        segundo: 0,
        tipo: 'GOL',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 10,
        jugadorPrincipal: 'Scorer',
        idLigaJugadorSecundario: 20,
        jugadorSecundario: 'Assist',
        texto: 'Gol',
      ),
      LeagueMatchEvent(
        idEvento: 2,
        minuto: 22,
        segundo: 1,
        tipo: 'ASISTENCIA',
        replayOffsetSec: 0,
        idLigaJugadorPrincipal: 20,
        jugadorPrincipal: 'Assist',
        idLigaJugadorSecundario: 10,
        jugadorSecundario: 'Scorer',
        texto: 'Asistencia',
      ),
    ];
    expect(shouldSuppressAssistInSummary(ordered, ordered[1]), isTrue);
    expect(assistPlayerNameForGoal(ordered, ordered[0]), 'Assist');
  });
}

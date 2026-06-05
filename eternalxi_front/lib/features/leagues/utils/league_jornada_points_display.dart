import 'package:eternal_xi/app/localization/league_l10n.dart';

String leagueJornadaEstadoNormalized(String raw) => raw.trim().toUpperCase();

bool leagueJornadaIsInProgress(String estadoJornada) =>
    leagueJornadaEstadoNormalized(estadoJornada) == 'EN_CURSO';

bool leagueJornadaIsFinalizada(String estadoJornada) =>
    leagueJornadaEstadoNormalized(estadoJornada) == 'FINALIZADA';

/// Puntos concedidos de jornada: solo cuando la jornada ha finalizado.
bool leagueJornadaShowsGrantedPoints(String estadoJornada) =>
    leagueJornadaIsFinalizada(estadoJornada);

/// Etiqueta del chip/filtro de jornada (J8 → «Jornada en curso» si aplica).
String leagueJornadaChipLabel({
  required String estadoJornada,
  required int numeroJornada,
  required LeagueL10n ll,
}) {
  if (leagueJornadaIsInProgress(estadoJornada)) {
    return ll.roundInProgressMatchday;
  }
  if (numeroJornada > 0) {
    return 'J$numeroJornada';
  }
  return 'J';
}

bool leagueRoundSummaryIsSelectableInStandings({
  required bool finalizada,
  required String estado,
  required bool actual,
}) {
  final e = leagueJornadaEstadoNormalized(estado);
  return finalizada || e == 'FINALIZADA' || e == 'EN_CURSO' || actual;
}

int leagueRoundSummarySortWeight({
  required bool finalizada,
  required String estado,
  required bool actual,
  required int numero,
}) {
  if (leagueJornadaIsInProgress(estado) || actual) {
    return 1_000_000 + numero;
  }
  if (finalizada || leagueJornadaEstadoNormalized(estado) == 'FINALIZADA') {
    return 100_000 + numero;
  }
  return numero;
}

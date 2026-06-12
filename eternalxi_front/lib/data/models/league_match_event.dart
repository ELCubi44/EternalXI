import 'package:eternal_xi/data/models/league_json_read.dart';

/// Evento de partido según `LeagueMatchEventResponse` del backend (lista `eventos`).
class LeagueMatchEvent {
  const LeagueMatchEvent({
    required this.idEvento,
    required this.minuto,
    required this.segundo,
    required this.tipo,
    required this.replayOffsetSec,
    required this.idLigaJugadorPrincipal,
    required this.jugadorPrincipal,
    required this.idLigaJugadorSecundario,
    required this.jugadorSecundario,
    required this.texto,
    this.idJugadorCedidoTemporadaPrincipal = 0,
    this.idJugadorCedidoTemporadaSecundario = 0,
    this.idJugadorCedidoTemporada = 0,
    this.fotoUrlJugadorPrincipal = '',
    this.fotoUrlJugadorSecundario = '',
    this.fotoCedidoRaw = '',
    this.fotoCedidoSecundarioRaw = '',
  });

  final int idEvento;
  final int minuto;
  final int segundo;
  final String tipo;
  final int replayOffsetSec;
  final int idLigaJugadorPrincipal;
  final String jugadorPrincipal;
  final int idLigaJugadorSecundario;
  final String jugadorSecundario;
  final String texto;

  /// Valor en JSON de `idJugadorCedidoTemporadaPrincipal` / snake_case (0 si no viene).
  final int idJugadorCedidoTemporadaPrincipal;

  /// `idJugadorCedidoTemporadaSecundario` (p. ej. sustituto que entra en un CAMBIO).
  final int idJugadorCedidoTemporadaSecundario;

  /// Id efectivo del cedido en el “principal”: positivo si viene principal o legacy.
  /// Foto canónica: `{ApiConstants.baseUrl}/assets/loan-players/{id}`.
  final int idJugadorCedidoTemporada;

  /// Valor explícito de `fotoUrlJugadorPrincipal` en JSON (vacío si no viene).
  final String fotoUrlJugadorPrincipal;

  /// Valor explícito de foto del jugador secundario (entra / segundo sujeto).
  final String fotoUrlJugadorSecundario;

  /// Primer campo no vacío entre alias de foto del cedido (lado principal) en JSON.
  final String fotoCedidoRaw;

  /// Alias de foto cedido lado secundario (CAMBIO con cedido entrando).
  final String fotoCedidoSecundarioRaw;

  factory LeagueMatchEvent.fromBackend(Map<String, dynamic> json) {
    final idPrincipal = readLeagueInt(json, const [
      'idJugadorCedidoTemporadaPrincipal',
      'id_jugador_cedido_temporada_principal',
    ]);
    final idSecundario = readLeagueInt(json, const [
      'idJugadorCedidoTemporadaSecundario',
      'id_jugador_cedido_temporada_secundario',
    ]);
    final idLegacy = readLeagueInt(json, const [
      'idJugadorCedidoTemporada',
      'id_jugador_cedido_temporada',
      'idJugadorCedido',
      'id_jugador_cedido',
    ]);
    final idCedidoEfectivo = idPrincipal > 0 ? idPrincipal : idLegacy;
    final fotoPrincipal = readLeagueString(json, const [
      'fotoUrlJugadorPrincipal',
      'foto_url_jugador_principal',
    ]);
    final fotoSecundariaApi = readLeagueString(json, const [
      'fotoUrlJugadorSecundario',
      'foto_url_jugador_secundario',
    ]);
    return LeagueMatchEvent(
      idEvento: readLeagueInt(json, const ['idEvento', 'id']),
      minuto: readLeagueInt(json, const ['minuto']),
      segundo: readLeagueInt(json, const ['segundo']),
      tipo: readLeagueString(json, const ['tipo']),
      replayOffsetSec: readLeagueInt(json, const ['replayOffsetSec']),
      idLigaJugadorPrincipal: readLeagueInt(json, const [
        'idLigaJugadorPrincipal',
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      jugadorPrincipal: readLeagueString(json, const [
        'jugadorPrincipal',
        'nombreJugadorPrincipal',
        'nombre_jugador_principal',
      ]),
      idLigaJugadorSecundario: readLeagueInt(json, const [
        'idLigaJugadorSecundario',
      ]),
      jugadorSecundario: readLeagueString(json, const [
        'jugadorSecundario',
        'nombreJugadorSecundario',
        'nombre_jugador_secundario',
      ]),
      texto: readLeagueString(json, const ['texto']),
      idJugadorCedidoTemporadaPrincipal: idPrincipal,
      idJugadorCedidoTemporadaSecundario: idSecundario,
      idJugadorCedidoTemporada: idCedidoEfectivo,
      fotoUrlJugadorPrincipal: fotoPrincipal,
      fotoUrlJugadorSecundario: fotoSecundariaApi,
      fotoCedidoRaw: _firstNonEmptyString(json, const [
        'fotoUrlJugadorPrincipal',
        'foto_url_jugador_principal',
        'fotoUrl',
        'foto_url',
        'fotoJugador',
        'foto_jugador',
        'fotoCedido',
        'foto_cedido',
      ]),
      fotoCedidoSecundarioRaw: _firstNonEmptyString(json, const [
        'fotoUrlJugadorSecundario',
        'foto_url_jugador_secundario',
        'fotoUrlJugadorSecundaria',
        'foto_url_jugador_secundaria',
        'fotoSecundaria',
        'foto_secundaria',
      ]),
    );
  }
}

/// Sustitución en cronología: solo tipos de cambio, nunca cesión individual/agrupada.
bool leagueMatchEventTipoCambioSustitucion(LeagueMatchEvent e) {
  if (isLoanGroupedEvent(e)) {
    return false;
  }
  final t = normalizedLeagueMatchEventType(e);
  if (t == 'CESION_PARTIDO' ||
      t.contains('CESION_PARTIDO') ||
      t.contains('CESIONES_PARTIDO')) {
    return false;
  }
  return t == 'CAMBIO' ||
      t.contains('CAMBIO') ||
      t.contains('SUSTITUCION') ||
      t.contains('SUBSTITUTION');
}

String _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty) {
      return s;
    }
  }
  return '';
}

String normalizedLeagueMatchEventType(LeagueMatchEvent e) {
  return e.tipo.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
}

bool isRedCardMatchEvent(LeagueMatchEvent e) {
  final t = normalizedLeagueMatchEventType(e);
  return t == 'TARJETA_ROJA' ||
      (t.contains('TARJETA') && t.contains('ROJ')) ||
      t.contains('ROJA');
}

bool isInjuryMatchEvent(LeagueMatchEvent e) {
  return normalizedLeagueMatchEventType(e).contains('LESION');
}

bool isLoanGroupedEvent(LeagueMatchEvent e) {
  final t = normalizedLeagueMatchEventType(e);
  return t == 'CESIONES_PARTIDO' || t.contains('CESIONES_PARTIDO');
}

bool isLoanIndividualEvent(LeagueMatchEvent e) {
  if (isLoanGroupedEvent(e)) {
    return false;
  }
  if (leagueMatchEventTipoCambioSustitucion(e)) {
    return false;
  }
  final t = normalizedLeagueMatchEventType(e);
  if (t == 'CESION_PARTIDO' || t.contains('CESION_PARTIDO')) {
    return true;
  }
  // Variantes tipo `CESION_DE_PARTIDO`, etc. (sin la S de agrupado).
  if (t.contains('CESION') && t.contains('PARTIDO')) {
    return true;
  }
  // Backend a veces manda otro `tipo` pero el texto es de cesión individual.
  final tx = e.texto.toUpperCase();
  if (tx.contains('HA SIDO CEDIDO') || tx.contains('HA SIDO CEDIDA')) {
    return true;
  }
  return false;
}

bool isAnyLoanEvent(LeagueMatchEvent e) {
  return isLoanGroupedEvent(e) || isLoanIndividualEvent(e);
}

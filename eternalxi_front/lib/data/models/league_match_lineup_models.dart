import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';

/// Titulares / suplentes de un bando según DTO de partido (detalle o live).
class LeagueMatchLineupSide {
  const LeagueMatchLineupSide({
    required this.titulares,
    required this.suplentes,
    this.formacion,
    this.entrenador,
  });

  final List<LeagueSquadPlayer> titulares;
  final List<LeagueSquadPlayer> suplentes;

  /// Formación base del equipo real en simulación (p. ej. `equipos.alineacion`).
  final String? formacion;

  /// Entrenador del equipo real (no fantasy).
  final LeagueCoachAssignment? entrenador;

  bool get isEmpty => titulares.isEmpty && suplentes.isEmpty;

  /// Prioriza meta propia; si falta formación o entrenador, toma del otro bando parseado.
  LeagueMatchLineupSide mergedWithFallbackMeta(LeagueMatchLineupSide fallback) {
    final f = formacion?.trim() ?? '';
    final fb = fallback.formacion?.trim() ?? '';
    return LeagueMatchLineupSide(
      titulares: titulares,
      suplentes: suplentes,
      formacion: f.isNotEmpty ? f : (fb.isNotEmpty ? fb : null),
      entrenador: entrenador ?? fallback.entrenador,
    );
  }

  /// Parsea `titularesX` + `suplentesX` desde el mapa raíz del JSON.
  static LeagueMatchLineupSide? tryParseFromMap(
    Map<String, dynamic> map, {
    required String titularesKey,
    required String suplentesKey,
    List<String> formacionKeys = const [],
    List<String> entrenadorKeys = const [],
  }) {
    var tit = _parsePlayerList(map, titularesKey);
    var sub = _parsePlayerList(map, suplentesKey);
    Map<String, dynamic>? nestedRoot;
    final lineupNestedLocal = map['lineupLocal'];
    final lineupNestedVisit = map['lineupVisitante'];
    if (titularesKey.contains('Local') &&
        lineupNestedLocal is Map<String, dynamic>) {
      nestedRoot = lineupNestedLocal;
    } else if (titularesKey.contains('Visitante') &&
        lineupNestedVisit is Map<String, dynamic>) {
      nestedRoot = lineupNestedVisit;
    }

    if (nestedRoot != null) {
      if (tit.isEmpty) {
        tit = _parsePlayerList(nestedRoot, titularesKey);
        if (tit.isEmpty) {
          tit = _parsePlayerList(nestedRoot, 'titulares');
        }
      }
      if (sub.isEmpty) {
        sub = _parsePlayerList(nestedRoot, suplentesKey);
        if (sub.isEmpty) {
          sub = _parsePlayerList(nestedRoot, 'suplentes');
        }
      }
    }

    if (tit.isEmpty && sub.isEmpty) {
      return null;
    }

    String formationSide = formacionKeys.isEmpty
        ? ''
        : readLeagueString(map, formacionKeys).trim();
    if (formationSide.isEmpty && nestedRoot != null) {
      formationSide = formacionKeys.isEmpty
          ? ''
          : readLeagueString(nestedRoot, formacionKeys).trim();
      if (formationSide.isEmpty) {
        formationSide = readLeagueString(nestedRoot, const [
          'formacion',
          'formación',
          'formation',
        ]).trim();
      }
    }

    LeagueCoachAssignment? coach;
    if (entrenadorKeys.isNotEmpty) {
      for (final k in entrenadorKeys) {
        coach = LeagueCoachAssignment.maybeFromJson(map[k]);
        if (coach == null && nestedRoot != null) {
          coach = LeagueCoachAssignment.maybeFromJson(nestedRoot[k]);
        }
        if (coach != null) {
          break;
        }
      }
    }

    final formTrimFinal = formationSide.trim().isEmpty ? null : formationSide.trim();

    return LeagueMatchLineupSide(
      titulares: tit,
      suplentes: sub,
      formacion: formTrimFinal,
      entrenador: coach,
    );
  }

  static List<LeagueSquadPlayer> _parsePlayerList(
    Map<String, dynamic> map,
    String key,
  ) {
    final raw = map[key];
    if (raw is! List) {
      return const [];
    }
    final out = <LeagueSquadPlayer>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final row = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(playerFromBackendRow(row));
    }
    return out;
  }

  /// `LeagueMatchLineupPlayerResponse` (record Java en camelCase).
  static LeagueSquadPlayer playerFromBackendRow(Map<String, dynamic> json) {
    final pila = readLeagueString(json, const ['pila']);
    final nombreVisible = readLeagueString(json, const ['nombreVisible']);
    final nombre = readLeagueString(json, const ['nombre']);
    final pilaEfectiva = pila.isNotEmpty
        ? pila
        : (nombreVisible.isNotEmpty ? nombreVisible : nombre);

    var idJugador = readLeagueInt(json, const [
      'idJugador',
      'id_jugador',
      'jugadorId',
    ]);
    if (idJugador <= 0) {
      final alt = readLeagueInt(json, const [
        'idJugadorCedidoTemporada',
        'id_jugador_cedido_temporada',
      ]);
      if (alt > 0) {
        idJugador = alt;
      }
    }

    return LeagueSquadPlayer(
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: idJugador,
      nombre: nombre,
      pila: pilaEfectiva,
      posicion: readLeagueString(json, const ['posicion']),
      valoracion: readLeagueDouble(json, const ['valoracion']),
      idEquipo: readLeagueInt(json, const ['idEquipo']),
      nombreEquipo: readLeagueString(json, const ['nombreEquipo']),
      estado: readLeagueString(json, const ['estado']),
      cansancio: readLeagueInt(json, const ['cansancio']),
      valor: readLeagueDouble(json, const ['valor']),
      fotoJugador: readLeagueString(json, const [
        'fotoUrl',
        'foto_url',
        'fotoJugadorUrl',
        'foto_jugador_url',
        'fotoJugador',
        'foto_jugador',
        'foto',
        'imagen',
        'urlFoto',
      ]),
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: 0,
      probabilidadTitular: readLeagueOptionalProbabilityTitular(json),
      motivoTitularidad: readLeagueOptionalNonEmptyString(json, const [
        'motivoTitularidad',
        'motivo_titularidad',
      ]),
      idPartidoProbabilidad: readLeagueOptionalPositiveInt(json, const [
        'idPartidoProbabilidad',
        'id_partido_probabilidad',
      ]),
      calculadoEnProbabilidad: readLeagueOptionalDateTime(json, const [
        'calculadoEnProbabilidad',
        'calculado_en_probabilidad',
      ]),
    );
  }
}

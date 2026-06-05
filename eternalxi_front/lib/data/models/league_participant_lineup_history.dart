import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_player_round_points_breakdown.dart';
import 'package:eternal_xi/data/models/league_lineup_empty_slot.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:flutter/foundation.dart';

DateTime? _readLeagueDateTime(Map<String, dynamic> json, List<String> keys) {
  final raw = readLeagueString(json, keys).trim();
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

List<Map<String, dynamic>> _readList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e))
      .toList();
}

int? _tryNullableInt(Map<String, dynamic> json, List<String> keys) {
  Object? v;
  for (final k in keys) {
    if (json.containsKey(k)) {
      v = json[k];
      break;
    }
  }
  if (v == null) {
    return null;
  }
  if (v is int) {
    return v;
  }
  if (v is double) {
    return v.round();
  }
  if (v is String) {
    return int.tryParse(v.trim());
  }
  return null;
}

String _formatRoundStat(double value) =>
    value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

/// Número compacto en burbujas del campo / banquillo del historial.
/// Vacío si la jornada sigue `PENDIENTE` (no se muestra valoración antes del partido).
String leagueRoundPlayerPitchBadgeText(
  LeagueParticipantLineupRoundPlayer player,
  bool showJornadaPitchBadges,
) {
  if (!showJornadaPitchBadges) {
    return '';
  }
  return _formatRoundStat(player.puntosJornada);
}

/// Etiqueta en tarjetas de lista (solo puntos de jornada; vacío si aún no ha empezado).
String leagueRoundPlayerListBadgeLabel(
  LeagueParticipantLineupRoundPlayer player,
  bool showJornadaPitchBadges,
) {
  if (!showJornadaPitchBadges) {
    return '';
  }
  return '${_formatRoundStat(player.puntosJornada)} pts';
}

LeagueCoachAssignment? _parseEntrenadorHistorialDetail(
  Map<String, dynamic> json,
) {
  for (final key in const [
    'entrenadorAsignado',
    'entrenador_asignado',
    'entrenador',
    'coach',
    'mister',
  ]) {
    final parsed = LeagueCoachAssignment.maybeFromJson(json[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  final idEntrenador = _tryNullableInt(json, const [
    'idEntrenador',
    'id_entrenador',
    'entrenadorId',
    'idEntrenadorLineup',
    'id_entrenador_lineup',
  ]);
  final entrenadorNombre = readLeagueString(json, const [
    'entrenadorNombre',
    'entrenador_nombre',
    'nombreEntrenador',
    'nombre_entrenador',
  ]).trim();
  final entrenadorPila = readLeagueString(json, const [
    'entrenadorPila',
    'entrenador_pila',
  ]).trim();
  final foto = readLeagueString(json, const [
    'fotoEntrenador',
    'foto_entrenador',
    'fotoUrlEntrenador',
    'foto_url_entrenador',
  ]).trim();
  final formacion = readLeagueString(json, const [
    'formacionEntrenador',
    'formacion_entrenador',
  ]).trim();
  if (idEntrenador == null &&
      entrenadorNombre.isEmpty &&
      entrenadorPila.isEmpty &&
      foto.isEmpty) {
    return null;
  }
  return LeagueCoachAssignment(
    idEntrenador: idEntrenador,
    entrenadorNombre: entrenadorNombre.isEmpty ? null : entrenadorNombre,
    entrenadorPila: entrenadorPila.isEmpty ? null : entrenadorPila,
    formacion: formacion.isEmpty ? null : formacion,
    foto: foto.isEmpty ? null : foto,
    bonusPuntos: readLeagueInt(json, const [
      'bonusEntrenador',
      'bonus_entrenador',
      'bonusPuntosEntrenador',
      'bonus_puntos_entrenador',
    ]),
    puntosEntrenadorJornada: readLeagueInt(json, const [
      'puntosEntrenadorJornada',
      'puntos_entrenador_jornada',
      'coachRoundPoints',
      'coach_round_points',
      'puntosJornadaEntrenador',
      'puntos_jornada_entrenador',
    ]),
    activo: readLeagueBool(json, const ['entrenadorActivo', 'entrenador_activo']),
  );
}

String? _firstPresentKey(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return key;
    }
  }
  return null;
}

class LeagueParticipantLineupHistorySummary {
  const LeagueParticipantLineupHistorySummary({
    required this.idLiga,
    required this.idLigaParticipante,
    required this.idUsuarioParticipante,
    required this.nickname,
    required this.jornadas,
  });

  final int idLiga;
  final int idLigaParticipante;
  final int idUsuarioParticipante;
  final String nickname;
  final List<LeagueParticipantLineupRoundSummary> jornadas;

  factory LeagueParticipantLineupHistorySummary.fromJson(
    Map<String, dynamic> json,
  ) {
    final rows = _readList(json['jornadas']);
    return LeagueParticipantLineupHistorySummary(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      idUsuarioParticipante: readLeagueInt(json, const [
        'idUsuarioParticipante',
        'id_usuario_participante',
      ]),
      nickname: readLeagueString(json, const ['nickname', 'nick', 'alias']),
      jornadas: rows
          .map(LeagueParticipantLineupRoundSummary.fromJson)
          .toList(growable: false),
    );
  }
}

class LeagueParticipantLineupRoundSummary {
  const LeagueParticipantLineupRoundSummary({
    required this.idJornada,
    required this.numeroJornada,
    required this.estadoJornada,
    required this.inicioJornada,
    required this.alineacionDisponible,
    required this.puntosTotales,
  });

  final int idJornada;
  final int numeroJornada;
  final String estadoJornada;
  final DateTime? inicioJornada;
  final bool alineacionDisponible;

  /// Total de puntos de la jornada tal cual envía el backend (jugadores, penalizaciones/huecos
  /// y entrenador cuando el API ya los incluye). No sumar en cliente `puntosEntrenadorJornada`.
  final double puntosTotales;

  bool get isPending => estadoJornada.toUpperCase() == 'PENDIENTE';
  bool get isInProgress => estadoJornada.toUpperCase() == 'EN_CURSO';
  bool get isFinalizada => estadoJornada.toUpperCase() == 'FINALIZADA';

  factory LeagueParticipantLineupRoundSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return LeagueParticipantLineupRoundSummary(
      idJornada: readLeagueInt(json, const ['idJornada', 'id_jornada']),
      numeroJornada: readLeagueInt(json, const [
        'numeroJornada',
        'numero_jornada',
        'numero',
      ]),
      estadoJornada: readLeagueString(json, const [
        'estadoJornada',
        'estado_jornada',
        'estado',
      ]),
      inicioJornada: _readLeagueDateTime(json, const [
        'inicioJornada',
        'inicio_jornada',
      ]),
      alineacionDisponible: readLeagueBool(json, const [
        'alineacionDisponible',
        'alineacion_disponible',
      ]),
      puntosTotales: readLeagueDouble(json, const [
        'puntosTotales',
        'puntos_totales',
        'puntos',
        'puntosJornada',
        'puntos_jornada',
        'totalPuntosJornada',
        'total_puntos_jornada',
      ]),
    );
  }
}

/// Detalle de una jornada del historial de alineaciones.
///
/// El míster debe obtenerse **solo** del JSON de
/// `GET .../lineup-history/{idJornada}` (p. ej. `entrenadorAsignado`). No combinar con el
/// inventario de coach del participante: sería el entrenador vigente, no el de esa jornada.
class LeagueParticipantLineupRoundDetail {
  const LeagueParticipantLineupRoundDetail({
    required this.idLiga,
    required this.idLigaParticipante,
    required this.idUsuarioParticipante,
    required this.nickname,
    required this.idJornada,
    required this.numeroJornada,
    required this.estadoJornada,
    required this.inicioJornada,
    required this.puntosTotales,
    required this.idCapitan,
    required this.titulares,
    required this.reservas,
    this.formacionEfectiva = '4-3-3',
    this.emptySlots = const [],
    this.entrenadorAsignado,
    this.puntosJugadoresFormacion,
    this.penalizacionHuecosFantasy,
    this.puntosEntrenadorFantasy,
  });

  final int idLiga;
  final int idLigaParticipante;
  final int idUsuarioParticipante;
  final String nickname;
  final int idJornada;
  final int numeroJornada;
  final String estadoJornada;
  final DateTime? inicioJornada;

  /// Total de puntos de la jornada tal cual envía el backend (jugadores, penalizaciones/huecos
  /// y entrenador cuando el API ya los incluye). No sumar en cliente `puntosEntrenadorJornada`.
  final double puntosTotales;

  /// Desglose opcional del backend (no recalcular el total en cliente).
  final double? puntosJugadoresFormacion;
  final double? penalizacionHuecosFantasy;
  final double? puntosEntrenadorFantasy;

  final int idCapitan;
  final List<LeagueParticipantLineupRoundPlayer> titulares;
  final List<LeagueParticipantLineupRoundPlayer> reservas;
  final String formacionEfectiva;
  final List<LeagueLineupEmptySlot> emptySlots;
  final LeagueCoachAssignment? entrenadorAsignado;

  bool get isJornadaFinalizada =>
      estadoJornada.toUpperCase() == 'FINALIZADA';

  /// Burbujas de puntos en campo, banquillo y tarjetas: solo `FINALIZADA`
  /// (en `EN_CURSO` aún no hay puntos concedidos).
  bool get shouldShowJornadaPitchBadges {
    final s = estadoJornada.trim().toUpperCase();
    return s == 'FINALIZADA';
  }

  /// Burbuja circular de puntos del entrenador en el campo (misma regla que jugadores).
  bool get shouldShowCoachJornadaPointsBadge => shouldShowJornadaPitchBadges;

  factory LeagueParticipantLineupRoundDetail.fromJson(Map<String, dynamic> json) {
    final formacionRaw = readLeagueString(json, const [
      'formacionEfectiva',
      'formacion_efectiva',
      'formation',
    ], fallback: '4-3-3');
    final formacionTrim = formacionRaw.trim();
    return LeagueParticipantLineupRoundDetail(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      idUsuarioParticipante: readLeagueInt(json, const [
        'idUsuarioParticipante',
        'id_usuario_participante',
      ]),
      nickname: readLeagueString(json, const ['nickname', 'nick', 'alias']),
      idJornada: readLeagueInt(json, const ['idJornada', 'id_jornada']),
      numeroJornada: readLeagueInt(json, const ['numeroJornada', 'numero_jornada']),
      estadoJornada: readLeagueString(json, const [
        'estadoJornada',
        'estado_jornada',
        'estado',
      ]),
      inicioJornada: _readLeagueDateTime(json, const [
        'inicioJornada',
        'inicio_jornada',
      ]),
      puntosTotales: readLeagueDouble(json, const [
        'puntosTotales',
        'puntos_totales',
        'puntos',
      ]),
      puntosJugadoresFormacion: readLeagueOptionalDouble(json, const [
        'puntosJugadoresFormacion',
        'puntos_jugadores_formacion',
      ]),
      penalizacionHuecosFantasy: readLeagueOptionalDouble(json, const [
        'penalizacionHuecosFantasy',
        'penalizacion_huecos_fantasy',
        'penalizacionHuecos',
        'penalizacion_huecos',
      ]),
      puntosEntrenadorFantasy: readLeagueOptionalDouble(json, const [
        'puntosEntrenadorFantasy',
        'puntos_entrenador_fantasy',
      ]),
      idCapitan: readLeagueInt(json, const ['idCapitan', 'id_capitan']),
      titulares: _readList(json['titulares'])
          .map(LeagueParticipantLineupRoundPlayer.fromJson)
          .toList(growable: false),
      reservas: _readList(json['reservas'])
          .map(LeagueParticipantLineupRoundPlayer.fromJson)
          .toList(growable: false),
      formacionEfectiva: formacionTrim.isEmpty ? '4-3-3' : formacionTrim,
      emptySlots: LeagueLineupEmptySlot.listFromJson(json['emptySlots']),
      entrenadorAsignado: _parseEntrenadorHistorialDetail(json),
    );
  }
}

class LeagueParticipantLineupRoundPlayer {
  const LeagueParticipantLineupRoundPlayer({
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.nombreMostrado,
    required this.posicion,
    required this.valoracion,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
    required this.fotoJugador,
    required this.estado,
    required this.cansancio,
    required this.valor,
    required this.titular,
    required this.capitan,
    required this.orden,
    required this.puntosJornada,
    required this.minutosJugados,
    required this.goles,
    required this.asistencias,
    required this.tarjetasAmarillas,
    required this.tarjetasRojas,
    required this.notaPeriodico,
    required this.golesEncajados,
    required this.porteriaCero,
    required this.lesionadoEnPartido,
    required this.paradas,
    this.puntosDesglose = LeaguePlayerRoundPointsBreakdown.empty,
    this.puntosFantasyParadas,
    required this.regates,
    required this.balonesRecuperados,
    this.fantasyTitularSinConteoPorBanquillo = false,
    this.fantasyBanquilloContandoPorSuplencia = false,
  });

  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String nombreMostrado;
  final String posicion;
  final double valoracion;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;
  final String fotoJugador;
  final String estado;
  final int cansancio;
  final double valor;
  final bool titular;
  final bool capitan;
  final int orden;

  /// Puntos base del jugador en la jornada (sin multiplicar por capitán). El total del equipo
  /// fantasy (capitán, entrenador, penalizaciones por huecos) viene en [LeagueParticipantLineupRoundDetail.puntosTotales].
  final double puntosJornada;
  final int minutosJugados;
  final int goles;
  final int asistencias;
  final int tarjetasAmarillas;
  final int tarjetasRojas;
  final double notaPeriodico;
  final int golesEncajados;
  final bool porteriaCero;
  final bool lesionadoEnPartido;

  /// Paradas (portero). Dato del servidor; [puntosJornada] ya viene calculado.
  final int paradas;

  /// Desglose oficial (`puntosDesglose` en API).
  final LeaguePlayerRoundPointsBreakdown puntosDesglose;

  /// Legacy: puntos fantasy por paradas en raíz del JSON (si no viene [puntosDesglose]).
  final double? puntosFantasyParadas;

  /// Puntos de paradas para UI: desglose oficial o legacy.
  double? get puntosFantasyParadasOficial =>
      puntosDesglose.paradas ?? puntosFantasyParadas;

  final int regates;
  final int balonesRecuperados;

  /// Titular que no sumó al fantasy de la jornada: contaron los puntos del suplente guardado.
  final bool fantasyTitularSinConteoPorBanquillo;

  /// Suplente cuyos puntos cuentan en el fantasy por sustituir al titular de la formación.
  final bool fantasyBanquilloContandoPorSuplencia;

  factory LeagueParticipantLineupRoundPlayer.fromJson(Map<String, dynamic> json) {
    const concededKeys = <String>[
      'golesEncajados',
      'goles_encajados',
      'concededGoals',
      'conceded_goals',
      'goalsConceded',
      'goals_conceded',
    ];
    const cleanSheetKeys = <String>[
      'porteriaCero',
      'porteria_cero',
      'cleanSheet',
      'clean_sheet',
      'cleanSheets',
      'clean_sheets',
    ];
    if (kDebugMode) {
      final concededSource = _firstPresentKey(json, concededKeys);
      if (concededSource != null) {
        debugPrint(
          '[parse][LeagueParticipantLineupRoundPlayer] golesEncajados source=$concededSource value=${json[concededSource]}',
        );
      }
      final cleanSheetSource = _firstPresentKey(json, cleanSheetKeys);
      if (cleanSheetSource != null) {
        debugPrint(
          '[parse][LeagueParticipantLineupRoundPlayer] porteriaCero source=$cleanSheetSource value=${json[cleanSheetSource]}',
        );
      }
    }
    final parsedGoalsConceded = readLeagueInt(json, concededKeys);
    if (kDebugMode) {
      final rawKey = _firstPresentKey(json, concededKeys);
      final rawValue = rawKey == null ? null : json[rawKey];
      final rawPos = readLeagueString(json, const ['posicion', 'posición']);
      final rawIdLigaJugador = readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]);
      debugPrint(
        '[lineup-history-detail][parse] idLigaJugador=$rawIdLigaJugador posicion=$rawPos rawGoalsConceded=$rawValue parsedGoalsConceded=$parsedGoalsConceded',
      );
    }
    return LeagueParticipantLineupRoundPlayer(
      idLigaJugador: readLeagueInt(json, const ['idLigaJugador', 'id_liga_jugador']),
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: readLeagueString(json, const ['pila']),
      nombreMostrado: readLeagueString(json, const [
        'nombreMostrado',
        'nombre_mostrado',
      ]),
      posicion: readLeagueString(json, const ['posicion', 'posición']),
      valoracion: readLeagueDouble(json, const ['valoracion', 'valoración']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const ['nombreEquipo', 'nombre_equipo']),
      fotoEquipo: readLeagueString(json, const ['fotoEquipo', 'foto_equipo']),
      fotoJugador: readLeagueString(json, const ['fotoJugador', 'foto_jugador']),
      estado: readLeagueString(json, const ['estado']),
      cansancio: readLeagueInt(json, const ['cansancio']),
      valor: readLeagueDouble(json, const ['valor']),
      titular: readLeagueBool(json, const ['titular']),
      capitan: readLeagueBool(json, const ['capitan', 'capitán']),
      orden: readLeagueInt(json, const ['orden']),
      puntosJornada: readLeagueDouble(json, const ['puntosJornada', 'puntos_jornada']),
      minutosJugados: readLeagueInt(json, const [
        'minutosJugados',
        'minutos_jugados',
      ]),
      goles: readLeagueInt(json, const ['goles']),
      asistencias: readLeagueInt(json, const ['asistencias']),
      tarjetasAmarillas: readLeagueInt(json, const [
        'tarjetasAmarillas',
        'tarjetas_amarillas',
      ]),
      tarjetasRojas: readLeagueInt(json, const [
        'tarjetasRojas',
        'tarjetas_rojas',
      ]),
      notaPeriodico: readLeagueDouble(json, const [
        'notaPeriodico',
        'nota_periodico',
        'nota',
      ]),
      golesEncajados: parsedGoalsConceded,
      porteriaCero: readLeagueBool(json, cleanSheetKeys),
      lesionadoEnPartido: readLeagueBool(json, const [
        'lesionadoEnPartido',
        'lesionado_en_partido',
      ]),
      paradas: readLeagueParadas(json),
      puntosDesglose: readLeagueRoundPointsBreakdown(json),
      puntosFantasyParadas: readLeagueParadasFantasyPoints(json),
      regates: readLeagueInt(json, const ['regates']),
      balonesRecuperados: readLeagueInt(json, const [
        'balonesRecuperados',
        'balones_recuperados',
      ]),
      fantasyTitularSinConteoPorBanquillo: readLeagueBool(json, const [
        'fantasyTitularSinConteoPorBanquillo',
        'fantasy_titular_sin_conteo_por_banquillo',
      ]),
      fantasyBanquilloContandoPorSuplencia: readLeagueBool(json, const [
        'fantasyBanquilloContandoPorSuplencia',
        'fantasy_banquillo_contando_por_suplencia',
      ]),
    );
  }

  LeagueSquadPlayer toSquadPlayer() {
    return LeagueSquadPlayer(
      idLigaJugador: idLigaJugador,
      idJugador: idJugador,
      nombre: nombre,
      pila: pila,
      posicion: posicion,
      valoracion: valoracion,
      idEquipo: idEquipo,
      nombreEquipo: nombreEquipo,
      estado: estado,
      cansancio: cansancio,
      valor: valor,
      fotoJugador: fotoJugador,
      fotoEquipo: fotoEquipo,
      enPoolMercado: false,
      propietarioNick: '',
      idUsuarioDueno: 0,
    );
  }
}

import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_player_round_points_breakdown.dart';
import 'package:flutter/foundation.dart';

String? _firstPresentKey(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return key;
    }
  }
  return null;
}

/// Estadísticas por jornada para el detalle de jugador de liga.
class LeaguePlayerRoundStats {
  const LeaguePlayerRoundStats({
    required this.idJornada,
    required this.numeroJornada,
    required this.estadoJornada,
    required this.minutosJugados,
    required this.goles,
    required this.asistencias,
    required this.golesEncajados,
    required this.porteriaCero,
    required this.paradas,
    this.puntosDesglose = LeaguePlayerRoundPointsBreakdown.empty,
    required this.regates,
    required this.balonesRecuperados,
    required this.tarjetasAmarillas,
    required this.tarjetasRojas,
    required this.lesionadoEnPartido,
    required this.notaPeriodico,
    required this.puntos,
  });

  final int idJornada;
  final int numeroJornada;
  final String estadoJornada;
  final int minutosJugados;
  final int goles;
  final int asistencias;
  final int golesEncajados;
  final bool porteriaCero;

  /// Paradas (portero). Dato del servidor; [puntos] ya viene calculado.
  final int paradas;

  /// Desglose oficial de puntos por estadística (`puntosDesglose` en API).
  final LeaguePlayerRoundPointsBreakdown puntosDesglose;

  final int regates;
  final int balonesRecuperados;
  final int tarjetasAmarillas;
  final int tarjetasRojas;
  final bool lesionadoEnPartido;
  final double? notaPeriodico;
  final double puntos;

  factory LeaguePlayerRoundStats.fromJson(Map<String, dynamic> json) {
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
    final parsedGoalsConceded = readLeagueInt(json, concededKeys);
    final parsedCleanSheet = readLeagueBool(json, cleanSheetKeys);
    final parsedMinutes = readLeagueInt(json, const [
      'minutosJugados',
      'minutos_jugados',
      'minutos',
    ]);
    const dribblesKeys = <String>[
      'regates',
      'regates_totales',
      'dribbles',
      'dribbles_total',
    ];
    const recoveriesKeys = <String>[
      'balonesRecuperados',
      'balones_recuperados',
      'recoveries',
      'ballRecoveries',
      'ball_recoveries',
    ];
    final parsedDribbles = readLeagueInt(json, dribblesKeys);
    final parsedRecoveries = readLeagueInt(json, recoveriesKeys);
    final parsedNote = _readNullableDouble(json, const [
      'notaPeriodico',
      'nota_periodico',
      'nota',
      'notaPeriodicoJugador',
      'nota_periodico_jugador',
      'notaDiario',
      'nota_diario',
    ]);
    final parsedPoints = readLeagueDouble(json, const ['puntos']);
    if (kDebugMode) {
      final concededSource = _firstPresentKey(json, concededKeys);
      final cleanSheetSource = _firstPresentKey(json, cleanSheetKeys);
      final idJornada = readLeagueInt(json, const ['idJornada', 'id_jornada']);
      final rawConceded = concededSource == null ? null : json[concededSource];
      final rawCleanSheet = cleanSheetSource == null
          ? null
          : json[cleanSheetSource];
      final minutesKey = _firstPresentKey(json, const [
        'minutosJugados',
        'minutos_jugados',
        'minutos',
      ]);
      final rawMinutes = minutesKey == null ? null : json[minutesKey];
      final noteKey = _firstPresentKey(json, const [
        'notaPeriodico',
        'nota_periodico',
        'nota',
        'notaPeriodicoJugador',
        'nota_periodico_jugador',
        'notaDiario',
        'nota_diario',
      ]);
      final rawNote = noteKey == null ? null : json[noteKey];
      final pointsKey = _firstPresentKey(json, const ['puntos']);
      final rawPoints = pointsKey == null ? null : json[pointsKey];
      final dribblesKey = _firstPresentKey(json, dribblesKeys);
      final recoveriesKey = _firstPresentKey(json, recoveriesKeys);
      final rawDribbles = dribblesKey == null ? null : json[dribblesKey];
      final rawRecoveries = recoveriesKey == null ? null : json[recoveriesKey];
      debugPrint(
        '[player-detail][parse] idJornada=$idJornada golesEncajadosRaw=$rawConceded golesEncajadosParsed=$parsedGoalsConceded minutosJugadosRaw=$rawMinutes minutosJugadosParsed=$parsedMinutes regatesRaw=$rawDribbles regatesParsed=$parsedDribbles balonesRecuperadosRaw=$rawRecoveries balonesRecuperadosParsed=$parsedRecoveries notaRaw=$rawNote notaParsed=$parsedNote puntosRaw=$rawPoints puntosParsed=$parsedPoints porteriaCeroRaw=$rawCleanSheet porteriaCeroParsed=$parsedCleanSheet',
      );
    }
    return LeaguePlayerRoundStats(
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
      minutosJugados: parsedMinutes,
      goles: readLeagueInt(json, const ['goles']),
      asistencias: readLeagueInt(json, const ['asistencias']),
      golesEncajados: parsedGoalsConceded,
      paradas: readLeagueParadas(json),
      puntosDesglose: readLeagueRoundPointsBreakdown(json),
      regates: parsedDribbles,
      balonesRecuperados: parsedRecoveries,
      tarjetasAmarillas: readLeagueInt(json, const [
        'tarjetasAmarillas',
        'tarjetas_amarillas',
      ]),
      tarjetasRojas: readLeagueInt(json, const [
        'tarjetasRojas',
        'tarjetas_rojas',
      ]),
      lesionadoEnPartido: readLeagueBool(json, const [
        'lesionadoEnPartido',
        'lesionado_en_partido',
      ]),
      porteriaCero: parsedCleanSheet,
      notaPeriodico: parsedNote,
      puntos: parsedPoints,
    );
  }

  static double? _readNullableDouble(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!json.containsKey(key)) {
        continue;
      }
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is double) {
        return value;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        final v = value.trim();
        if (v.isEmpty || v.toLowerCase() == 'null') {
          return null;
        }
        return double.tryParse(v.replaceAll(',', '.'));
      }
      return null;
    }
    return null;
  }
}

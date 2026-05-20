import 'package:eternal_xi/data/models/league_json_read.dart';

/// Estadísticas de un jugador en una jornada concreta (fantasy / liga).
///
/// El backend puede enviar la colección bajo distintas claves o nombres de campo;
/// si no llega ninguna lista reconocida, [parseLeaguePlayerRoundStatsList] devuelve [].
class LeaguePlayerRoundStat {
  const LeaguePlayerRoundStat({
    required this.idJornada,
    required this.numeroJornada,
    this.minutosJugados = 0,
    this.goles = 0,
    this.asistencias = 0,
    this.tarjetasAmarillas = 0,
    this.tarjetasRojas = 0,
    this.paradas = 0,
    this.puntos = 0.0,
  });

  final int idJornada;
  final int numeroJornada;
  final int minutosJugados;
  final int goles;
  final int asistencias;
  final int tarjetasAmarillas;
  final int tarjetasRojas;
  final int paradas;
  final double puntos;

  factory LeaguePlayerRoundStat.fromBackend(Map<String, dynamic> json) {
    return LeaguePlayerRoundStat(
      idJornada: readLeagueInt(json, const [
        'idJornada',
        'id_jornada',
        'jornadaId',
      ]),
      numeroJornada: readLeagueInt(json, const [
        'numeroJornada',
        'numero_jornada',
        'numero',
        'jornada',
        'nJornada',
      ]),
      minutosJugados: readLeagueInt(json, const [
        'minutosJugados',
        'minutos_jugados',
        'minutos',
        'mins',
        'minutesPlayed',
      ]),
      goles: readLeagueInt(json, const ['goles', 'goals', 'g']),
      asistencias: readLeagueInt(json, const ['asistencias', 'assists', 'a']),
      tarjetasAmarillas: readLeagueInt(json, const [
        'tarjetasAmarillas',
        'tarjetas_amarillas',
        'amarillas',
        'yellowCards',
      ]),
      tarjetasRojas: readLeagueInt(json, const [
        'tarjetasRojas',
        'tarjetas_rojas',
        'rojas',
        'redCards',
      ]),
      paradas: readLeagueParadas(json),
      puntos: readLeagueDouble(json, const [
        'puntos',
        'puntosFantasy',
        'puntos_fantasy',
        'fantasyPoints',
        'score',
      ]),
    );
  }

  static LeaguePlayerRoundStat zeroFor({
    required int idJornada,
    required int numeroJornada,
  }) {
    return LeaguePlayerRoundStat(
      idJornada: idJornada,
      numeroJornada: numeroJornada,
    );
  }
}

/// Busca en [json] una lista de mapas con estadísticas por jornada.
List<LeaguePlayerRoundStat> parseLeaguePlayerRoundStatsList(
  Map<String, dynamic> json,
) {
  const listKeys = <String>[
    'estadisticasPorJornada',
    'estadisticas_por_jornada',
    'estadisticasJornadas',
    'estadisticas_jornadas',
    'rendimientoJornadas',
    'rendimiento_jornadas',
    'historialJornadas',
    'historial_jornadas',
    'statsPorJornada',
    'stats_por_jornada',
    'jornadasStats',
    'jornadas_stats',
    'jornadas',
  ];
  for (final key in listKeys) {
    final raw = json[key];
    if (raw is! List) {
      continue;
    }
    final out = <LeaguePlayerRoundStat>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final row = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      try {
        out.add(LeaguePlayerRoundStat.fromBackend(row));
      } catch (_) {
        continue;
      }
    }
    if (out.isNotEmpty) {
      return out;
    }
  }
  return const [];
}

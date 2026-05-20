import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueTeamStandingRow {
  const LeagueTeamStandingRow({
    required this.posicion,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
    required this.partidosJugados,
    required this.partidosGanados,
    required this.partidosEmpatados,
    required this.partidosPerdidos,
    required this.golesFavor,
    required this.golesContra,
    required this.diferenciaGoles,
    required this.puntos,
  });

  final int posicion;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;
  final int partidosJugados;
  final int partidosGanados;
  final int partidosEmpatados;
  final int partidosPerdidos;
  final int golesFavor;
  final int golesContra;
  final int diferenciaGoles;
  final int puntos;

  factory LeagueTeamStandingRow.fromJson(Map<String, dynamic> json) {
    return LeagueTeamStandingRow(
      posicion: readLeagueInt(json, const ['posicion', 'posición']),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const ['nombreEquipo', 'nombre_equipo']),
      fotoEquipo: readLeagueString(json, const ['fotoEquipo', 'foto_equipo']),
      partidosJugados: readLeagueInt(json, const ['partidosJugados', 'partidos_jugados']),
      partidosGanados: readLeagueInt(json, const ['partidosGanados', 'partidos_ganados']),
      partidosEmpatados: readLeagueInt(json, const ['partidosEmpatados', 'partidos_empatados']),
      partidosPerdidos: readLeagueInt(json, const ['partidosPerdidos', 'partidos_perdidos']),
      golesFavor: readLeagueInt(json, const ['golesFavor', 'goles_favor']),
      golesContra: readLeagueInt(json, const ['golesContra', 'goles_contra']),
      diferenciaGoles: readLeagueInt(json, const ['diferenciaGoles', 'diferencia_goles']),
      puntos: readLeagueInt(json, const ['puntos']),
    );
  }

  String? resolvedFotoEquipoUrl() {
    return LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: fotoEquipo,
    );
  }
}

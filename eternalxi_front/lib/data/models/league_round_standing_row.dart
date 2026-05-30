import 'package:eternal_xi/data/models/league_json_read.dart';

/// Fila de clasificación de una jornada concreta.
class LeagueRoundStandingRow {
  const LeagueRoundStandingRow({
    required this.posicion,
    this.idLigaParticipante = 0,
    required this.idUsuario,
    required this.nickname,
    required this.puntosFantasyJornada,
    required this.puntosRecompensaJornada,
    required this.valorTotalEquipo,
    required this.admin,
  });

  final int posicion;
  final int idLigaParticipante;
  final int idUsuario;
  final String nickname;
  final int puntosFantasyJornada;
  final int puntosRecompensaJornada;
  final double valorTotalEquipo;
  final bool admin;

  factory LeagueRoundStandingRow.fromJson(Map<String, dynamic> json) {
    return LeagueRoundStandingRow(
      posicion: readLeagueInt(json, const [
        'posicion',
        'posición',
        'position',
      ]),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      idUsuario: readLeagueInt(json, const ['idUsuario', 'id_usuario']),
      nickname: readLeagueString(json, const ['nickname', 'nick']),
      puntosFantasyJornada: readLeagueInt(json, const [
        'puntosFantasyJornada',
        'puntos_fantasy_jornada',
      ]),
      puntosRecompensaJornada: readLeagueInt(json, const [
        'puntosRecompensaJornada',
        'puntos_recompensa_jornada',
      ]),
      valorTotalEquipo: readLeagueDouble(json, const [
        'valorTotalEquipo',
        'valor_total_equipo',
      ]),
      admin: readLeagueBool(json, const ['admin', 'esAdmin', 'es_admin']),
    );
  }
}

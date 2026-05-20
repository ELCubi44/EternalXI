import 'package:eternal_xi/data/models/league_json_read.dart';

/// Respuesta de `POST /api/v1/leagues` ([CreateLeagueResponse] en backend).
class CreateLeagueResponse {
  const CreateLeagueResponse({
    required this.idLiga,
    this.maxParticipantes,
    this.semanaPreviaFichajes,
    this.permiteEntresemana,
    this.idaYVuelta,
    this.recompensaBaseJornada,
    this.recompensaBonusGanador,
    this.dineroPorPuntoFantasy,
    this.numeroJornadas,
    this.primerPartidoEn,
    this.finLigaEn,
  });

  final int idLiga;
  final int? maxParticipantes;
  final bool? semanaPreviaFichajes;
  final bool? permiteEntresemana;
  final bool? idaYVuelta;
  final int? recompensaBaseJornada;
  final int? recompensaBonusGanador;
  final int? dineroPorPuntoFantasy;
  final int? numeroJornadas;
  final DateTime? primerPartidoEn;
  final DateTime? finLigaEn;

  bool get isSuccess => idLiga > 0;

  factory CreateLeagueResponse.fromJson(dynamic data) {
    final map = readLeagueSingleMap(data);
    final idLiga = map.isEmpty
        ? readLeagueIdFromPostResponse(data)
        : readLeagueInt(map, const [
            'idLiga',
            'id_liga',
            'id',
            'leagueId',
            'ligaId',
          ]);

    if (map.isEmpty) {
      return CreateLeagueResponse(idLiga: idLiga);
    }

    return CreateLeagueResponse(
      idLiga: idLiga,
      maxParticipantes: _optionalInt(map, 'maxParticipantes', 'max_participantes'),
      semanaPreviaFichajes: _optionalBool(
        map,
        'semanaPreviaFichajes',
        'semana_previa_fichajes',
      ),
      permiteEntresemana: _optionalBool(
        map,
        'permiteEntresemana',
        'permite_entresemana',
      ),
      idaYVuelta: _optionalBool(map, 'idaYVuelta', 'ida_y_vuelta'),
      recompensaBaseJornada: _optionalInt(
        map,
        'recompensaBaseJornada',
        'recompensa_base_jornada',
      ),
      recompensaBonusGanador: _optionalInt(
        map,
        'recompensaBonusGanador',
        'recompensa_bonus_ganador',
      ),
      dineroPorPuntoFantasy: _optionalInt(
        map,
        'dineroPorPuntoFantasy',
        'dinero_por_punto_fantasy',
      ),
      numeroJornadas: _optionalInt(map, 'numeroJornadas', 'numero_jornadas'),
      primerPartidoEn: readLeagueOptionalDateTime(map, const [
        'primerPartidoEn',
        'primer_partido_en',
      ]),
      finLigaEn: readLeagueOptionalDateTime(map, const [
        'finLigaEn',
        'fin_liga_en',
      ]),
    );
  }
}

int? _optionalInt(Map<String, dynamic> map, String camel, String snake) {
  if (!map.containsKey(camel) && !map.containsKey(snake)) {
    return null;
  }
  return readLeagueInt(map, [camel, snake]);
}

bool? _optionalBool(Map<String, dynamic> map, String camel, String snake) {
  if (!map.containsKey(camel) && !map.containsKey(snake)) {
    return null;
  }
  return readLeagueBool(map, [camel, snake]);
}

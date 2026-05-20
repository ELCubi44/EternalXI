import 'package:eternal_xi/data/models/league_json_read.dart';

/// Respuesta de `POST /api/v1/leagues/join` ([JoinLeagueResponse] en backend).
class JoinLeagueResponse {
  const JoinLeagueResponse({
    required this.joined,
    required this.idLiga,
    this.idLigaParticipante = 0,
    this.jugadoresAsignados,
    this.plantillaIncompleta,
    this.valorPlantillaInicial,
    this.mensaje,
  });

  final bool joined;
  final int idLiga;
  final int idLigaParticipante;

  /// `null` si el campo no venía (respuesta antigua solo con `idLiga`).
  final int? jugadoresAsignados;

  /// `null` si el campo no venía (respuesta antigua).
  final bool? plantillaIncompleta;

  /// Valor económico de la plantilla inicial (opcional; no obligatorio en UI).
  final double? valorPlantillaInicial;

  final String? mensaje;

  bool get isSuccess => joined && idLiga > 0;

  /// Aviso post-unión para UI; `null` = flujo normal sin mensaje extra.
  String? get postJoinNotice {
    if (plantillaIncompleta != true) {
      return null;
    }
    return 'Has entrado en la liga, pero tu plantilla inicial está incompleta. Podrás completarla en el mercado.';
  }

  factory JoinLeagueResponse.fromJson(dynamic data) {
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
      return JoinLeagueResponse(
        joined: idLiga > 0,
        idLiga: idLiga,
      );
    }

    final hasJoinedKey = map.containsKey('joined');
    final joined = hasJoinedKey
        ? readLeagueBool(map, const ['joined'])
        : idLiga > 0;

    return JoinLeagueResponse(
      joined: joined,
      idLiga: idLiga,
      idLigaParticipante: readLeagueInt(map, const [
        'idLigaParticipante',
        'id_liga_participante',
        'ligaParticipanteId',
      ]),
      jugadoresAsignados: map.containsKey('jugadoresAsignados') ||
              map.containsKey('jugadores_asignados')
          ? readLeagueInt(map, const [
              'jugadoresAsignados',
              'jugadores_asignados',
            ])
          : null,
      plantillaIncompleta: map.containsKey('plantillaIncompleta') ||
              map.containsKey('plantilla_incompleta')
          ? readLeagueBool(map, const [
              'plantillaIncompleta',
              'plantilla_incompleta',
            ])
          : null,
      valorPlantillaInicial: readLeagueOptionalDouble(map, const [
        'valorPlantillaInicial',
        'valor_plantilla_inicial',
      ]),
      mensaje: readLeagueOptionalNonEmptyString(map, const [
        'mensaje',
        'message',
      ]),
    );
  }
}

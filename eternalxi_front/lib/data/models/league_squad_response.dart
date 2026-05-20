import 'package:eternal_xi/data/models/league_coach_assignment.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';

/// Respuesta raíz de `GET /leagues/{idLiga}/squad?idUsuario=` con `plantilla` y metadatos de coach/formación.
class LeagueSquadResponse {
  const LeagueSquadResponse({
    this.idLiga,
    this.idLigaParticipante,
    this.idUsuario,
    this.entrenadorAsignado,
    this.entrenadoresDisponibles = const [],
    this.entrenadorActivo = false,
    this.formacionEfectiva = '4-3-3',
    this.plantilla = const [],
  });

  final int? idLiga;
  final int? idLigaParticipante;
  final int? idUsuario;
  final LeagueCoachAssignment? entrenadorAsignado;
  final List<LeagueCoachAssignment> entrenadoresDisponibles;
  final bool entrenadorActivo;
  final String formacionEfectiva;
  final List<LeagueSquadPlayer> plantilla;

  factory LeagueSquadResponse.fromJson(Map<String, dynamic> json) {
    final formacionRaw = readLeagueString(json, const [
      'formacionEfectiva',
      'formacion_efectiva',
      'formation',
    ], fallback: '4-3-3').trim();
    return LeagueSquadResponse(
      idLiga: _readNullablePositiveInt(json, const ['idLiga', 'id_liga']),
      idLigaParticipante: _readNullablePositiveInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
      ]),
      idUsuario: _readNullablePositiveInt(json, const [
        'idUsuario',
        'id_usuario',
      ]),
      entrenadorAsignado: LeagueCoachAssignment.maybeFromJson(
        json['entrenadorAsignado'],
      ),
      entrenadoresDisponibles: LeagueCoachAssignment.listFromJson(
        json['entrenadoresDisponibles'] ?? json['entrenadores'],
      ),
      entrenadorActivo: readLeagueBool(json, const [
        'entrenadorActivo',
        'entrenador_activo',
      ]),
      formacionEfectiva: formacionRaw.isEmpty ? '4-3-3' : formacionRaw,
      plantilla: _parsePlantilla(json),
    );
  }

  /// Legacy: respuesta que es solo una lista de jugadores.
  factory LeagueSquadResponse.plantillaOnly(List<LeagueSquadPlayer> players) {
    return LeagueSquadResponse(plantilla: players);
  }
}

List<LeagueSquadPlayer> _parsePlantilla(Map<String, dynamic> json) {
  const keys = <String>[
    'plantilla',
    'jugadores',
    'ligaJugadores',
    'liga_jugadores',
    'squad',
  ];
  for (final k in keys) {
    final raw = json[k];
    if (raw is List) {
      final out = <LeagueSquadPlayer>[];
      for (final e in raw) {
        if (e is! Map) {
          continue;
        }
        final map = e is Map<String, dynamic>
            ? e
            : Map<String, dynamic>.from(e);
        out.add(LeagueSquadPlayer.fromJson(map));
      }
      return out;
    }
  }
  return const [];
}

int? _readNullablePositiveInt(Map<String, dynamic> json, List<String> keys) {
  final v = readLeagueInt(json, keys);
  return v > 0 ? v : null;
}

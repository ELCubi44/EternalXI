import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueActivityEvent {
  const LeagueActivityEvent({
    required this.id,
    required this.idLiga,
    required this.idActorUsuario,
    required this.actorNickname,
    required this.tipo,
    required this.mensaje,
    required this.idLigaParticipanteActor,
    required this.idLigaParticipanteObjetivo,
    required this.idLigaJugador,
    required this.idCarta,
    required this.idEntrenador,
    required this.cantidad,
    required this.metadataJson,
    required this.creadoEn,
  });

  final int id;
  final int idLiga;
  final int? idActorUsuario;
  final String actorNickname;
  final String tipo;
  final String mensaje;
  final int? idLigaParticipanteActor;
  final int? idLigaParticipanteObjetivo;
  final int? idLigaJugador;
  final int? idCarta;
  final int? idEntrenador;
  final int? cantidad;
  final String? metadataJson;
  final DateTime? creadoEn;

  factory LeagueActivityEvent.fromJson(Map<String, dynamic> json) {
    return LeagueActivityEvent(
      id: readLeagueInt(json, const ['id']),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idActorUsuario: _optInt(json, const ['idActorUsuario', 'id_actor_usuario']),
      actorNickname: readLeagueString(json, const ['actorNickname', 'actor_nickname']),
      tipo: readLeagueString(json, const ['tipo', 'type']),
      mensaje: readLeagueString(json, const ['mensaje', 'message']),
      idLigaParticipanteActor: _optInt(json, const ['idLigaParticipanteActor', 'id_liga_participante_actor']),
      idLigaParticipanteObjetivo: _optInt(json, const ['idLigaParticipanteObjetivo', 'id_liga_participante_objetivo']),
      idLigaJugador: _optInt(json, const ['idLigaJugador', 'id_liga_jugador']),
      idCarta: _optInt(json, const ['idCarta', 'id_carta']),
      idEntrenador: _optInt(json, const ['idEntrenador', 'id_entrenador']),
      cantidad: _optInt(json, const ['cantidad']),
      metadataJson: _optStr(json, const ['metadataJson', 'metadata_json']),
      creadoEn: _parseDate(json['creadoEn'] ?? json['creado_en']),
    );
  }

  static List<LeagueActivityEvent> listFrom(dynamic data) {
    if (data is! List) return const [];
    final out = <LeagueActivityEvent>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueActivityEvent.fromJson(m));
    }
    return out;
  }
}

int? _optInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (!json.containsKey(k) || json[k] == null) continue;
    return readLeagueInt(json, [k]);
  }
  return null;
}

String? _optStr(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (!json.containsKey(k) || json[k] == null) continue;
    final s = readLeagueString(json, [k]);
    return s.trim().isEmpty ? null : s;
  }
  return null;
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim());
  }
  return null;
}

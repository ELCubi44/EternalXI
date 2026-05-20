import 'package:eternal_xi/data/models/league_json_read.dart';

/// Resumen de liga (p. ej. listado "mis ligas").
class LeagueSummary {
  const LeagueSummary({
    required this.id,
    required this.nombre,
    required this.idTemporada,
    required this.codigoInvitacion,
    required this.soyAdmin,
    required this.participantes,
  });

  final int id;
  final String nombre;
  final int idTemporada;
  final String codigoInvitacion;
  final bool soyAdmin;
  final int participantes;

  factory LeagueSummary.fromJson(Map<String, dynamic> json) {
    return LeagueSummary(
      id: readLeagueInt(json, const ['id', 'idLiga']),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      idTemporada: readLeagueInt(json, const ['idTemporada', 'id_temporada']),
      codigoInvitacion: readLeagueString(json, const [
        'codigoInvitacion',
        'codigo_invitacion',
        'codigoInvitación',
      ]),
      soyAdmin: readLeagueBool(json, const ['soyAdmin', 'soy_admin', 'admin']),
      participantes: readParticipantesCount(json, const [
        'participantes',
        'numParticipantes',
        'num_participantes',
        'totalParticipantes',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'idTemporada': idTemporada,
      'codigoInvitacion': codigoInvitacion,
      'soyAdmin': soyAdmin,
      'participantes': participantes,
    };
  }
}

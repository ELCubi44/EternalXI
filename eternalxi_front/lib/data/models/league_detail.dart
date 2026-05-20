import 'package:eternal_xi/data/models/league_json_read.dart';

/// Detalle de una liga (GET /leagues/{idLiga}).
class LeagueDetail {
  const LeagueDetail({
    required this.id,
    required this.nombre,
    required this.idTemporada,
    required this.codigoInvitacion,
    required this.idAdministrador,
    required this.soyAdmin,
    required this.participantes,
    required this.miDinero,
    required this.misPuntos,
    required this.miValorEquipo,
    required this.nombreTemporada,
    required this.nicknameAdministrador,
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

  final int id;
  final String nombre;
  final int idTemporada;
  final String codigoInvitacion;
  final int idAdministrador;
  final bool soyAdmin;

  /// Participantes actuales en la liga (no confundir con [maxParticipantes]).
  final int participantes;
  final double miDinero;
  final double misPuntos;
  final double miValorEquipo;

  /// Nombre legible de la temporada (si el backend lo envía).
  final String nombreTemporada;

  /// Nickname del administrador (si el backend lo envía).
  final String nicknameAdministrador;

  /// Cupo máximo de managers/participantes fantasy.
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

  bool get hasConfigSummary =>
      maxParticipantes != null ||
      semanaPreviaFichajes != null ||
      permiteEntresemana != null ||
      idaYVuelta != null ||
      recompensaBaseJornada != null ||
      dineroPorPuntoFantasy != null;

  /// Semana previa activa y aún no ha empezado el primer partido.
  bool get isFichajesPhaseActive {
    if (semanaPreviaFichajes != true) {
      return false;
    }
    final start = primerPartidoEn;
    if (start == null) {
      return false;
    }
    return DateTime.now().isBefore(start.toLocal());
  }

  factory LeagueDetail.fromJson(Map<String, dynamic> json) {
    return LeagueDetail(
      id: readLeagueInt(json, const ['id', 'idLiga']),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      idTemporada: readLeagueInt(json, const ['idTemporada', 'id_temporada']),
      codigoInvitacion: readLeagueString(json, const [
        'codigoInvitacion',
        'codigo_invitacion',
        'codigoInvitación',
      ]),
      idAdministrador: readLeagueInt(json, const [
        'idAdministrador',
        'id_administrador',
        'idAdmin',
        'administradorId',
      ]),
      soyAdmin: readLeagueBool(json, const ['soyAdmin', 'soy_admin', 'admin']),
      participantes: readParticipantesCount(json, const [
        'participantes',
        'numParticipantes',
        'num_participantes',
        'totalParticipantes',
      ]),
      miDinero: readLeagueDouble(json, const [
        'miDinero',
        'mi_dinero',
        'dinero',
      ]),
      misPuntos: readLeagueDouble(json, const [
        'misPuntos',
        'mis_puntos',
        'puntos',
      ]),
      miValorEquipo: readLeagueDouble(json, const [
        'miValorEquipo',
        'mi_valor_equipo',
        'valorEquipo',
        'valor_equipo',
      ]),
      nombreTemporada: readLeagueString(json, const [
        'nombreTemporada',
        'nombre_temporada',
        'temporadaNombre',
        'temporada',
        'seasonName',
        'season',
      ]),
      nicknameAdministrador: readLeagueString(json, const [
        'nicknameAdministrador',
        'nickname_administrador',
        'adminNickname',
        'nickAdministrador',
        'adminNick',
      ]),
      maxParticipantes: _optionalInt(json, 'maxParticipantes', 'max_participantes'),
      semanaPreviaFichajes: _optionalBool(
        json,
        'semanaPreviaFichajes',
        'semana_previa_fichajes',
      ),
      permiteEntresemana: _optionalBool(
        json,
        'permiteEntresemana',
        'permite_entresemana',
      ),
      idaYVuelta: _optionalBool(json, 'idaYVuelta', 'ida_y_vuelta'),
      recompensaBaseJornada: _optionalInt(
        json,
        'recompensaBaseJornada',
        'recompensa_base_jornada',
      ),
      recompensaBonusGanador: _optionalInt(
        json,
        'recompensaBonusGanador',
        'recompensa_bonus_ganador',
      ),
      dineroPorPuntoFantasy: _optionalInt(
        json,
        'dineroPorPuntoFantasy',
        'dinero_por_punto_fantasy',
      ),
      numeroJornadas: _optionalInt(json, 'numeroJornadas', 'numero_jornadas'),
      primerPartidoEn: readLeagueOptionalDateTime(json, const [
        'primerPartidoEn',
        'primer_partido_en',
      ]),
      finLigaEn: readLeagueOptionalDateTime(json, const [
        'finLigaEn',
        'fin_liga_en',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'idTemporada': idTemporada,
      'codigoInvitacion': codigoInvitacion,
      'idAdministrador': idAdministrador,
      'soyAdmin': soyAdmin,
      'participantes': participantes,
      'miDinero': miDinero,
      'misPuntos': misPuntos,
      'miValorEquipo': miValorEquipo,
      'nombreTemporada': nombreTemporada,
      'nicknameAdministrador': nicknameAdministrador,
      if (maxParticipantes != null) 'maxParticipantes': maxParticipantes,
      if (semanaPreviaFichajes != null)
        'semanaPreviaFichajes': semanaPreviaFichajes,
      if (permiteEntresemana != null) 'permiteEntresemana': permiteEntresemana,
      if (idaYVuelta != null) 'idaYVuelta': idaYVuelta,
      if (recompensaBaseJornada != null)
        'recompensaBaseJornada': recompensaBaseJornada,
      if (recompensaBonusGanador != null)
        'recompensaBonusGanador': recompensaBonusGanador,
      if (dineroPorPuntoFantasy != null)
        'dineroPorPuntoFantasy': dineroPorPuntoFantasy,
      if (numeroJornadas != null) 'numeroJornadas': numeroJornadas,
      if (primerPartidoEn != null)
        'primerPartidoEn': primerPartidoEn!.toIso8601String(),
      if (finLigaEn != null) 'finLigaEn': finLigaEn!.toIso8601String(),
    };
  }
}

int? _optionalInt(Map<String, dynamic> json, String camel, String snake) {
  if (!json.containsKey(camel) && !json.containsKey(snake)) {
    return null;
  }
  return readLeagueInt(json, [camel, snake]);
}

bool? _optionalBool(Map<String, dynamic> json, String camel, String snake) {
  if (!json.containsKey(camel) && !json.containsKey(snake)) {
    return null;
  }
  return readLeagueBool(json, [camel, snake]);
}

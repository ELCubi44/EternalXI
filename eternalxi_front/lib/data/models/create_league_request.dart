/// Cuerpo de `POST /api/v1/leagues`. Campos avanzados opcionales: si no se envían,
/// el backend aplica defaults legacy.
class CreateLeagueRequest {
  const CreateLeagueRequest({
    required this.nombre,
    required this.idTemporada,
    required this.idUsuario,
    this.maxParticipantes,
    this.semanaPreviaFichajes,
    this.permiteEntresemana,
    this.idaYVuelta,
    this.recompensaBaseJornada,
    this.dineroPorPuntoFantasy,
  });

  final String nombre;
  final int idTemporada;
  final int idUsuario;
  final int? maxParticipantes;
  final bool? semanaPreviaFichajes;
  final bool? permiteEntresemana;
  final bool? idaYVuelta;
  final int? recompensaBaseJornada;
  final int? dineroPorPuntoFantasy;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'idTemporada': idTemporada,
      'idUsuario': idUsuario,
    };
    if (maxParticipantes != null) {
      map['maxParticipantes'] = maxParticipantes;
    }
    if (semanaPreviaFichajes != null) {
      map['semanaPreviaFichajes'] = semanaPreviaFichajes;
    }
    if (permiteEntresemana != null) {
      map['permiteEntresemana'] = permiteEntresemana;
    }
    if (idaYVuelta != null) {
      map['idaYVuelta'] = idaYVuelta;
    }
    if (recompensaBaseJornada != null) {
      map['recompensaBaseJornada'] = recompensaBaseJornada;
    }
    if (dineroPorPuntoFantasy != null) {
      map['dineroPorPuntoFantasy'] = dineroPorPuntoFantasy;
    }
    return map;
  }
}

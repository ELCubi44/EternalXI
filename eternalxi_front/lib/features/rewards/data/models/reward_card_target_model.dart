import 'package:eternal_xi/data/models/league_json_read.dart';

class RewardCardTargetPlayer {
  const RewardCardTargetPlayer({
    required this.idLigaJugador,
    required this.nombreJugador,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
    required this.fotoJugador,
    required this.posicion,
    required this.valoracionActual,
    required this.idUsuarioDueno,
    required this.nicknameDueno,
    required this.valorActual,
    required this.valorAnterior,
    required this.valorMercadoEfectivo,
    required this.porcentajeModificadorValorActivo,
    required this.multiplicadorVenta,
    required this.cantidadRecibidaPreview,
    required this.costeClausulaAtacante,
    required this.compensacionPropietario,
    required this.protegido,
    required this.motivoBloqueo,
    required this.idJornadaInicioProteccion,
    required this.idJornadaFinProteccion,
    required this.proteccionHastaFinTemporada,
    required this.jornadasProteccion,
    required this.proteccionTemporada,
    required this.valorTemporalEstimado,
    required this.porcentajeRecuperacion,
    required this.idJornadaExpiracionPreview,
    this.numeroJornadaFinProteccion,
    this.numeroJornadaExpiracionPreview,
    this.incrementoValorDiarioPreview,
    this.diferenciaValorPreview,
  });

  final int idLigaJugador;
  final String nombreJugador;
  final int? idEquipo;
  final String? nombreEquipo;
  final String? fotoEquipo;
  final String? fotoJugador;
  final String? posicion;
  final double? valoracionActual;
  final int? idUsuarioDueno;
  final String? nicknameDueno;
  final int? valorActual;
  final int? valorAnterior;
  final int? valorMercadoEfectivo;
  final double? porcentajeModificadorValorActivo;
  final double? multiplicadorVenta;
  final int? cantidadRecibidaPreview;
  final int? costeClausulaAtacante;
  final int? compensacionPropietario;
  final bool? protegido;
  final String? motivoBloqueo;
  final int? idJornadaInicioProteccion;
  final int? idJornadaFinProteccion;
  final bool? proteccionHastaFinTemporada;
  final int? jornadasProteccion;
  final bool? proteccionTemporada;
  final int? valorTemporalEstimado;
  final double? porcentajeRecuperacion;
  final int? idJornadaExpiracionPreview;
  final int? numeroJornadaFinProteccion;
  final int? numeroJornadaExpiracionPreview;
  final int? incrementoValorDiarioPreview;
  final int? diferenciaValorPreview;

  factory RewardCardTargetPlayer.fromJson(Map<String, dynamic> json) {
    return RewardCardTargetPlayer(
      idLigaJugador: readLeagueInt(json, const ['idLigaJugador', 'id_liga_jugador']),
      nombreJugador: readLeagueString(json, const ['nombreJugador', 'nombre_jugador']),
      idEquipo: _optInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: _optStr(json, const ['nombreEquipo', 'nombre_equipo']),
      fotoEquipo: _optStr(json, const ['fotoEquipo', 'foto_equipo']),
      fotoJugador: _optStr(json, const ['fotoJugador', 'foto_jugador']),
      posicion: _optStr(json, const ['posicion', 'position']),
      valoracionActual: _optDbl(json, const ['valoracionActual', 'valoracion_actual']),
      idUsuarioDueno: _optInt(json, const ['idUsuarioDueno', 'id_usuario_dueno']),
      nicknameDueno: _optStr(json, const ['nicknameDueno', 'nickname_dueno']),
      valorActual: _optInt(json, const ['valorActual', 'valor_actual']),
      valorAnterior: _optInt(json, const ['valorAnterior', 'valor_anterior']),
      valorMercadoEfectivo: _optInt(json, const ['valorMercadoEfectivo', 'valor_mercado_efectivo']),
      porcentajeModificadorValorActivo: _optDbl(json, const ['porcentajeModificadorValorActivo', 'porcentaje_modificador_valor_activo']),
      multiplicadorVenta: _optDbl(json, const ['multiplicadorVenta', 'multiplicador_venta']),
      cantidadRecibidaPreview: _optInt(json, const ['cantidadRecibidaPreview', 'cantidad_recibida_preview']),
      costeClausulaAtacante: _optInt(json, const ['costeClausulaAtacante', 'coste_clausula_atacante']),
      compensacionPropietario: _optInt(json, const ['compensacionPropietario', 'compensacion_propietario']),
      protegido: _optBool(json['protegido']),
      motivoBloqueo: _optStr(json, const ['motivoBloqueo', 'motivo_bloqueo']),
      idJornadaInicioProteccion: _optInt(json, const ['idJornadaInicioProteccion', 'id_jornada_inicio_proteccion']),
      idJornadaFinProteccion: _optInt(json, const ['idJornadaFinProteccion', 'id_jornada_fin_proteccion']),
      proteccionHastaFinTemporada: _optBool(json['proteccionHastaFinTemporada'] ?? json['proteccion_hasta_fin_temporada']),
      jornadasProteccion: _optInt(json, const ['jornadasProteccion', 'jornadas_proteccion']),
      proteccionTemporada: _optBool(json['proteccionTemporada'] ?? json['proteccion_temporada']),
      valorTemporalEstimado: _optInt(json, const ['valorTemporalEstimado', 'valor_temporal_estimado']),
      porcentajeRecuperacion: _optDbl(json, const ['porcentajeRecuperacion', 'porcentaje_recuperacion']),
      idJornadaExpiracionPreview: _optInt(json, const ['idJornadaExpiracionPreview', 'id_jornada_expiracion_preview']),
      numeroJornadaFinProteccion: _optInt(json, const [
        'numeroJornadaFinProteccion',
        'numero_jornada_fin_proteccion',
      ]),
      numeroJornadaExpiracionPreview: _optInt(json, const [
        'numeroJornadaExpiracionPreview',
        'numero_jornada_expiracion_preview',
        'numeroJornadaExpiracion',
        'numero_jornada_expiracion',
      ]),
      incrementoValorDiarioPreview: _optInt(json, const [
        'incrementoValorDiarioPreview',
        'incremento_valor_diario_preview',
        'incrementoValorDiario',
        'incremento_valor_diario',
        'subidaValorDiario',
        'subida_valor_diario',
      ]),
      diferenciaValorPreview: _optInt(json, const [
        'diferenciaValorPreview',
        'diferencia_valor_preview',
      ]),
    );
  }
}

class RewardParticipantTarget {
  const RewardParticipantTarget({
    required this.idLigaParticipante,
    required this.idUsuario,
    required this.nickname,
    required this.jugadoresDisponibles,
    required this.jugadoresBloqueados,
    required this.objetivos,
    required this.objetivosBloqueados,
  });

  final int idLigaParticipante;
  final int idUsuario;
  final String nickname;
  final int jugadoresDisponibles;
  final int jugadoresBloqueados;
  final List<RewardCardTargetPlayer> objetivos;
  final List<RewardCardTargetPlayer> objetivosBloqueados;

  factory RewardParticipantTarget.fromJson(Map<String, dynamic> json) {
    return RewardParticipantTarget(
      idLigaParticipante: readLeagueInt(json, const ['idLigaParticipante', 'id_liga_participante']),
      idUsuario: readLeagueInt(json, const ['idUsuario', 'id_usuario']),
      nickname: readLeagueString(json, const ['nickname']),
      jugadoresDisponibles: readLeagueInt(json, const ['jugadoresDisponibles', 'jugadores_disponibles']),
      jugadoresBloqueados: readLeagueInt(json, const ['jugadoresBloqueados', 'jugadores_bloqueados']),
      objetivos: _parsePlayerList(json['objetivos']),
      objetivosBloqueados: _parsePlayerList(json['objetivosBloqueados'] ?? json['objetivos_bloqueados']),
    );
  }
}

class RewardValidTargetsResponse {
  const RewardValidTargetsResponse({
    required this.tipoEfecto,
    required this.objetivos,
    required this.objetivosBloqueados,
    required this.participantesObjetivo,
    required this.puntosAnadidosPreview,
  });

  final String tipoEfecto;
  final List<RewardCardTargetPlayer> objetivos;
  final List<RewardCardTargetPlayer> objetivosBloqueados;
  final List<RewardParticipantTarget> participantesObjetivo;
  final int? puntosAnadidosPreview;

  factory RewardValidTargetsResponse.fromJson(Map<String, dynamic> json) {
    final partRaw = json['participantesObjetivo'] ?? json['participantes_objetivo'];
    final parts = <RewardParticipantTarget>[];
    if (partRaw is List) {
      for (final e in partRaw) {
        if (e is! Map) continue;
        final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        parts.add(RewardParticipantTarget.fromJson(m));
      }
    }

    int? puntosPreview;
    if (_hasKey(json, const ['puntosAnadidosPreview', 'puntos_anadidos_preview'])) {
      puntosPreview = readLeagueInt(json, const ['puntosAnadidosPreview', 'puntos_anadidos_preview']);
    }

    return RewardValidTargetsResponse(
      tipoEfecto: readLeagueString(json, const ['tipoEfecto', 'tipo_efecto']),
      objetivos: _parsePlayerList(json['objetivos']),
      objetivosBloqueados: _parsePlayerList(json['objetivosBloqueados'] ?? json['objetivos_bloqueados']),
      participantesObjetivo: parts,
      puntosAnadidosPreview: puntosPreview,
    );
  }
}

List<RewardCardTargetPlayer> _parsePlayerList(dynamic raw) {
  if (raw is! List) return const [];
  final out = <RewardCardTargetPlayer>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
    out.add(RewardCardTargetPlayer.fromJson(m));
  }
  return out;
}

String? _optStr(Map<String, dynamic> json, List<String> keys) {
  final s = readLeagueString(json, keys);
  final t = s.trim();
  return t.isEmpty ? null : t;
}

int? _optInt(Map<String, dynamic> json, List<String> keys) {
  if (!_hasKey(json, keys)) return null;
  return readLeagueInt(json, keys);
}

double? _optDbl(Map<String, dynamic> json, List<String> keys) {
  if (!_hasKey(json, keys)) return null;
  return readLeagueDouble(json, keys);
}

bool? _optBool(Object? raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is String) {
    final t = raw.trim().toLowerCase();
    if (t == 'true') return true;
    if (t == 'false') return false;
  }
  return null;
}

bool _hasKey(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return true;
  }
  return false;
}

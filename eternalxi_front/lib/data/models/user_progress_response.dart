import 'dart:convert';

class UserProgressResponse {
  const UserProgressResponse({
    required this.idUsuario,
    required this.nivel,
    required this.experienciaTotal,
    required this.xpEnNivel,
    required this.xpParaSiguienteNivel,
    required this.rango,
    required this.logros,
    required this.eventosPendientes,
  });

  final int idUsuario;
  final int nivel;
  final int experienciaTotal;
  final int xpEnNivel;
  final int xpParaSiguienteNivel;
  final String rango;
  final List<UserAchievement> logros;
  final List<UserProgressEvent> eventosPendientes;

  factory UserProgressResponse.fromJson(Map<String, dynamic> json) {
    final achievementsRaw = json['logros'] as List<dynamic>? ?? const [];
    final eventsRaw = json['eventosPendientes'] as List<dynamic>? ?? const [];
    return UserProgressResponse(
      idUsuario: (json['idUsuario'] as num?)?.toInt() ?? 0,
      nivel: (json['nivel'] as num?)?.toInt() ?? 1,
      experienciaTotal: (json['experienciaTotal'] as num?)?.toInt() ?? 0,
      xpEnNivel: (json['xpEnNivel'] as num?)?.toInt() ?? 0,
      xpParaSiguienteNivel: (json['xpParaSiguienteNivel'] as num?)?.toInt() ?? 100,
      rango: json['rango'] as String? ?? 'Novato',
      logros: achievementsRaw
          .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventosPendientes: eventsRaw
          .map((e) => UserProgressEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'idUsuario': idUsuario,
    'nivel': nivel,
    'experienciaTotal': experienciaTotal,
    'xpEnNivel': xpEnNivel,
    'xpParaSiguienteNivel': xpParaSiguienteNivel,
    'rango': rango,
    'logros': logros.map((e) => e.toJson()).toList(),
    'eventosPendientes': eventosPendientes.map((e) => e.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  static UserProgressResponse? fromJsonString(String raw) {
    try {
      return UserProgressResponse.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

class UserAchievement {
  const UserAchievement({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.informacion,
    required this.categoria,
    required this.xpRecompensa,
    required this.desbloqueado,
    this.desbloqueadoEn,
    this.progresoActual,
    this.progresoObjetivo,
  });

  final String codigo;
  final String titulo;
  final String descripcion;
  final String informacion;
  final String categoria;
  final int xpRecompensa;
  final bool desbloqueado;
  final DateTime? desbloqueadoEn;
  final int? progresoActual;
  final int? progresoObjetivo;

  bool get tieneProgreso =>
      progresoObjetivo != null && progresoObjetivo! > 0 && !desbloqueado;

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    final rawDate = json['desbloqueadoEn'];
    DateTime? unlockedAt;
    if (rawDate is String && rawDate.isNotEmpty) {
      unlockedAt = DateTime.tryParse(rawDate);
    }
    return UserAchievement(
      codigo: json['codigo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      informacion: json['informacion'] as String? ?? json['descripcion'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      xpRecompensa: (json['xpRecompensa'] as num?)?.toInt() ?? 0,
      desbloqueado: json['desbloqueado'] as bool? ?? false,
      desbloqueadoEn: unlockedAt,
      progresoActual: (json['progresoActual'] as num?)?.toInt(),
      progresoObjetivo: (json['progresoObjetivo'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'titulo': titulo,
    'descripcion': descripcion,
    'informacion': informacion,
    'categoria': categoria,
    'xpRecompensa': xpRecompensa,
    'desbloqueado': desbloqueado,
    if (desbloqueadoEn != null) 'desbloqueadoEn': desbloqueadoEn!.toIso8601String(),
    if (progresoActual != null) 'progresoActual': progresoActual,
    if (progresoObjetivo != null) 'progresoObjetivo': progresoObjetivo,
  };
}

class UserProgressEvent {
  const UserProgressEvent({
    required this.id,
    required this.tipo,
    this.cantidadXp,
    this.nivelAnterior,
    this.nivelNuevo,
    this.codigoLogro,
    this.tituloLogro,
    this.descripcionLogro,
    this.xpLogro,
    required this.xpTotalDespues,
    required this.xpEnNivelDespues,
    required this.xpParaSiguienteDespues,
  });

  final int id;
  final String tipo;
  final int? cantidadXp;
  final int? nivelAnterior;
  final int? nivelNuevo;
  final String? codigoLogro;
  final String? tituloLogro;
  final String? descripcionLogro;
  final int? xpLogro;
  final int xpTotalDespues;
  final int xpEnNivelDespues;
  final int xpParaSiguienteDespues;

  factory UserProgressEvent.fromJson(Map<String, dynamic> json) {
    return UserProgressEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: json['tipo'] as String? ?? '',
      cantidadXp: (json['cantidadXp'] as num?)?.toInt(),
      nivelAnterior: (json['nivelAnterior'] as num?)?.toInt(),
      nivelNuevo: (json['nivelNuevo'] as num?)?.toInt(),
      codigoLogro: json['codigoLogro'] as String?,
      tituloLogro: json['tituloLogro'] as String?,
      descripcionLogro: json['descripcionLogro'] as String?,
      xpLogro: (json['xpLogro'] as num?)?.toInt(),
      xpTotalDespues: (json['xpTotalDespues'] as num?)?.toInt() ?? 0,
      xpEnNivelDespues: (json['xpEnNivelDespues'] as num?)?.toInt() ?? 0,
      xpParaSiguienteDespues: (json['xpParaSiguienteDespues'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    if (cantidadXp != null) 'cantidadXp': cantidadXp,
    if (nivelAnterior != null) 'nivelAnterior': nivelAnterior,
    if (nivelNuevo != null) 'nivelNuevo': nivelNuevo,
    if (codigoLogro != null) 'codigoLogro': codigoLogro,
    if (tituloLogro != null) 'tituloLogro': tituloLogro,
    if (descripcionLogro != null) 'descripcionLogro': descripcionLogro,
    if (xpLogro != null) 'xpLogro': xpLogro,
    'xpTotalDespues': xpTotalDespues,
    'xpEnNivelDespues': xpEnNivelDespues,
    'xpParaSiguienteDespues': xpParaSiguienteDespues,
  };
}

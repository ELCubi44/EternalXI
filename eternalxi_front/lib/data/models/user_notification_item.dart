class UserNotificationItem {
  const UserNotificationItem({
    required this.id,
    this.idLiga,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.datos,
    this.creadaEn,
  });

  final int id;
  final int? idLiga;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final Map<String, dynamic> datos;
  final DateTime? creadaEn;

  int? get idLigaJugador => _readInt(datos['idLigaJugador']);
  int? get idJugador => _readInt(datos['idJugador']);
  String? get playerName => _readString(datos['playerName']);
  String? get playerPhotoUrl => _readString(datos['playerPhotoUrl']);
  int? get idUsuarioActor => _readInt(datos['idUsuarioActor']);
  String? get actorName => _readString(datos['actorName']);
  String? get actorPhotoUrl => _readString(datos['actorPhotoUrl']);
  int? get idOferta => _readInt(datos['idOferta']);
  int? get precio => _readInt(datos['precio']);
  String? get actionTab => _readString(datos['actionTab']);
  int? get actionSegment => _readInt(datos['actionSegment']);

  factory UserNotificationItem.fromJson(Map<String, dynamic> json) {
    final datosRaw = json['datos'];
    Map<String, dynamic> datos = const {};
    if (datosRaw is Map) {
      datos = datosRaw.map((k, v) => MapEntry(k.toString(), v));
    }
    return UserNotificationItem(
      id: _readInt(json['id']) ?? 0,
      idLiga: _readInt(json['idLiga']),
      tipo: json['tipo']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      leida: json['leida'] == true,
      datos: datos,
      creadaEn: _readDateTime(json['creadaEn']),
    );
  }

  static int? _readInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }

  static String? _readString(Object? value) {
    if (value == null) {
      return null;
    }
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }
}

class UserNotificationsListResponse {
  const UserNotificationsListResponse({
    required this.items,
    required this.noLeidas,
  });

  final List<UserNotificationItem> items;
  final int noLeidas;

  factory UserNotificationsListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => UserNotificationItem.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .toList()
        : <UserNotificationItem>[];
    return UserNotificationsListResponse(
      items: items,
      noLeidas: UserNotificationItem._readInt(json['noLeidas']) ?? 0,
    );
  }
}

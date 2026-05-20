class UserResourcesResponse {
  const UserResourcesResponse({required this.idUsuario, required this.fichas});

  final int idUsuario;
  final int fichas;

  factory UserResourcesResponse.fromJson(Map<String, dynamic> json) {
    return UserResourcesResponse(
      idUsuario: _asInt(json['idUsuario']),
      fichas: _asInt(json['fichas']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

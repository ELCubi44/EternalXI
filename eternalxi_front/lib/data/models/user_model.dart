class UserModel {
  const UserModel({
    required this.id,
    required this.correo,
    required this.nickname,
    required this.nivel,
    this.foto,
  });

  final int id;
  final String correo;
  final String nickname;
  final int nivel;
  final String? foto;

  bool get hasProfilePhoto => foto != null && foto!.trim().isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawFoto = json['foto'];
    final fotoStr = rawFoto?.toString().trim();
    return UserModel(
      id: _asInt(json['id']),
      correo: (json['correo'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      nivel: _asInt(json['nivel'], fallback: 1),
      foto: (fotoStr == null || fotoStr.isEmpty) ? null : fotoStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': correo,
      'nickname': nickname,
      'nivel': nivel,
      'foto': foto ?? '',
    };
  }

  UserModel copyWith({
    int? id,
    String? correo,
    String? nickname,
    int? nivel,
    String? foto,
  }) {
    return UserModel(
      id: id ?? this.id,
      correo: correo ?? this.correo,
      nickname: nickname ?? this.nickname,
      nivel: nivel ?? this.nivel,
      foto: foto ?? this.foto,
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

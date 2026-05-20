import 'package:eternal_xi/core/utils/league_asset_urls.dart';

/// Temporada del catálogo (`GET /catalog/seasons`).
class SeasonSummary {
  const SeasonSummary({required this.id, required this.nombre, this.foto = ''});

  final int id;
  final String nombre;

  /// Ruta o URL de imagen devuelta por el backend (opcional).
  final String foto;

  /// URL para mostrar en UI: `foto` del catálogo o asset `/assets/seasons/{id}`.
  String? displayImageUrl() {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(foto);
    if (fromApi != null) {
      return fromApi;
    }
    if (id > 0) {
      return LeagueAssetUrls.seasonCover(id).toString();
    }
    return null;
  }

  factory SeasonSummary.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] is int)
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;
    final nombre = '${json['nombre'] ?? json['name'] ?? ''}';
    final foto = '${json['foto'] ?? json['imagen'] ?? json['image'] ?? ''}';
    return SeasonSummary(id: id, nombre: nombre, foto: foto);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'foto': foto,
  };
}

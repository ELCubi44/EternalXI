import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Cabecera de equipo en respuestas de catálogo (`equipo` en `/catalog/teams/.../squad`).
class CatalogTeamSummary {
  const CatalogTeamSummary({
    required this.id,
    required this.nombre,
    required this.idTemporada,
    required this.foto,
    this.fotoUrl,
    this.formacionEquipo = '',
  });

  final int id;
  final String nombre;
  final int idTemporada;
  final String foto;
  final String? fotoUrl;

  /// Formación del equipo en competición (no confundir con la del entrenador fantasy).
  /// Si el backend no envía este campo, queda vacío.
  final String formacionEquipo;

  String? resolvedFotoUrl() {
    final preferred = fotoUrl?.trim() ?? '';
    if (preferred.isNotEmpty) {
      final resolvedPreferred = LeagueAssetUrls.buildBackendImageUrl(preferred);
      if (resolvedPreferred != null) {
        return resolvedPreferred;
      }
    }
    return LeagueAssetUrls.resolveTeamBadgeUrl(idEquipo: id, rawFoto: foto);
  }

  factory CatalogTeamSummary.fromJson(Map<String, dynamic> json) {
    return CatalogTeamSummary(
      id: readLeagueInt(json, const ['id', 'idEquipo', 'id_equipo']),
      nombre: readLeagueString(json, const ['nombre', 'name', 'nombreEquipo']),
      idTemporada: readLeagueInt(json, const [
        'idTemporada',
        'id_temporada',
        'temporadaId',
      ]),
      foto: readLeagueString(json, const ['foto', 'escudo', 'imagen', 'logo']),
      fotoUrl: _readOptionalString(json, const ['fotoUrl', 'foto_url']),
      formacionEquipo: readLeagueString(json, const [
        'formacionEquipo',
        'formacion_equipo',
        'alineacion',
        'alineación',
        'alineacionTitular',
        'alineacion_titular',
        'formacionTitular',
        'formacion_titular',
      ]),
    );
  }
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  final value = readLeagueString(json, keys).trim();
  return value.isEmpty ? null : value;
}

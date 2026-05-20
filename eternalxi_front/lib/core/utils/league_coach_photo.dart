import 'package:eternal_xi/core/utils/league_asset_urls.dart';

/// Fotos de entrenadores/managers vía `GET /assets/managers/{id}`.
abstract final class LeagueCoachPhoto {
  LeagueCoachPhoto._();

  static String? resolveUrl({
    required int? idEntrenador,
    String? foto,
    String? fotoUrl,
  }) {
    return LeagueAssetUrls.resolveManagerPhotoUrl(
      idEntrenador: idEntrenador,
      rawFoto: (fotoUrl ?? '').trim().isNotEmpty
          ? fotoUrl
          : ((foto ?? '').trim().isNotEmpty ? foto : null),
    );
  }
}

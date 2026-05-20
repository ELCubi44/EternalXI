import 'package:eternal_xi/core/utils/league_asset_urls.dart';

/// URLs de escudo para [LeagueTeamLogo.networkImageUrl] (solo http/https seguras).
abstract final class LeagueNightMarketImages {
  LeagueNightMarketImages._();

  static String? teamBadgeNetworkUrl({
    required int idEquipo,
    required String fotoEquipo,
  }) {
    return LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: fotoEquipo,
    );
  }
}

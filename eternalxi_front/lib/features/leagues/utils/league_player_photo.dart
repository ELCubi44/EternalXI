import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';

/// Resolución centralizada de URL de foto de jugador (plantilla / alineación / mercado).
abstract final class LeaguePlayerPhoto {
  LeaguePlayerPhoto._();

  static Uri? uriFromRawPhoto(String? raw) {
    final url = LeagueAssetUrls.buildBackendImageUrl(raw);
    return url == null ? null : Uri.tryParse(url);
  }

  static Uri? templateUrlFromPlayerId(LeagueSquadPlayer p) {
    if (p.idJugador > 0) {
      return LeagueAssetUrls.playerPhoto(p.idJugador);
    }
    return null;
  }

  static Uri? resolve(LeagueSquadPlayer p) {
    final url = LeagueAssetUrls.resolvePlayerPhotoUrl(
      idJugador: p.idJugador,
      rawFoto: p.fotoJugador,
    );
    return url == null ? null : Uri.tryParse(url);
  }

  static Uri? resolveLoanTimelinePhoto({
    required int idJugadorCedidoTemporada,
    required String fotoRaw,
  }) {
    var id = idJugadorCedidoTemporada;
    if (id <= 0) {
      id = parseLoanPlayerSeasonIdFromPath(fotoRaw);
    }
    if (id > 0) {
      return LeagueAssetUrls.loanPlayerPhoto(id);
    }
    return uriFromRawPhoto(fotoRaw);
  }

  static int parseLoanPlayerSeasonIdFromPath(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return 0;
    }
    final re = RegExp(r'loan-players/(\d+)', caseSensitive: false);
    final m = re.firstMatch(t);
    if (m == null) {
      return 0;
    }
    return int.tryParse(m.group(1) ?? '') ?? 0;
  }

  static Uri? resolveNightMarket({
    required int idJugador,
    required String fotoJugador,
  }) {
    final url = LeagueAssetUrls.resolvePlayerPhotoUrl(
      idJugador: idJugador,
      rawFoto: fotoJugador,
    );
    return url == null ? null : Uri.tryParse(url);
  }
}

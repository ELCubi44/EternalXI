import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueDmThread {
  const LeagueDmThread({
    required this.idPeer,
    required this.nicknamePeer,
    required this.fotoPeer,
    required this.ultimoTexto,
    required this.ultimoEn,
    required this.ultimoId,
    required this.esAmigo,
  });

  final int idPeer;
  final String nicknamePeer;
  final String fotoPeer;
  final String ultimoTexto;
  final DateTime? ultimoEn;
  final int ultimoId;
  final bool esAmigo;

  factory LeagueDmThread.fromJson(Map<String, dynamic> json) {
    return LeagueDmThread(
      idPeer: readLeagueInt(json, const ['idPeer', 'id_peer']),
      nicknamePeer: readLeagueString(json, const [
        'nicknamePeer',
        'nickname_peer',
        'nickname',
      ]),
      fotoPeer: readLeagueString(json, const ['fotoPeer', 'foto_peer', 'foto']),
      ultimoTexto: readLeagueString(json, const [
        'ultimoTexto',
        'ultimo_texto',
        'texto',
      ]),
      ultimoEn: _parseDate(json['ultimoEn'] ?? json['ultimo_en']),
      ultimoId: readLeagueInt(json, const ['ultimoId', 'ultimo_id']),
      esAmigo: readLeagueBool(json, const ['esAmigo', 'es_amigo']),
    );
  }

  static List<LeagueDmThread> listFrom(dynamic data) {
    if (data is! List) return const [];
    final out = <LeagueDmThread>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueDmThread.fromJson(m));
    }
    return out;
  }

  String? resolvedPhotoUrl() {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(fotoPeer);
    if (fromApi != null) return fromApi;
    if (fotoPeer.trim().isEmpty && idPeer > 0) {
      return ApiConstants.userProfilePhotoUrl(idPeer, cacheBuster: idPeer);
    }
    return null;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }
}

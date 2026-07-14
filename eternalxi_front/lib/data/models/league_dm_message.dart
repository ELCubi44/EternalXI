import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueDmMessage {
  const LeagueDmMessage({
    required this.id,
    required this.idLiga,
    required this.idEmisor,
    required this.idDestino,
    required this.nicknameEmisor,
    required this.fotoEmisor,
    required this.texto,
    required this.creadoEn,
  });

  final int id;
  final int idLiga;
  final int idEmisor;
  final int idDestino;
  final String nicknameEmisor;
  final String fotoEmisor;
  final String texto;
  final DateTime? creadoEn;

  factory LeagueDmMessage.fromJson(Map<String, dynamic> json) {
    return LeagueDmMessage(
      id: readLeagueInt(json, const ['id']),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idEmisor: readLeagueInt(json, const ['idEmisor', 'id_emisor']),
      idDestino: readLeagueInt(json, const ['idDestino', 'id_destino']),
      nicknameEmisor: readLeagueString(json, const [
        'nicknameEmisor',
        'nickname_emisor',
        'nickname',
      ]),
      fotoEmisor: readLeagueString(json, const ['fotoEmisor', 'foto_emisor', 'foto']),
      texto: readLeagueString(json, const ['texto', 'text', 'mensaje']),
      creadoEn: _parseDate(json['creadoEn'] ?? json['creado_en']),
    );
  }

  static List<LeagueDmMessage> listFrom(dynamic data) {
    if (data is! List) return const [];
    final out = <LeagueDmMessage>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueDmMessage.fromJson(m));
    }
    return out;
  }

  String? resolvedPhotoUrl({int? cacheBuster}) {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(fotoEmisor);
    if (fromApi != null) return fromApi;
    if (fotoEmisor.trim().isEmpty && idEmisor > 0) {
      return ApiConstants.userProfilePhotoUrl(
        idEmisor,
        cacheBuster: cacheBuster ?? id,
      );
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

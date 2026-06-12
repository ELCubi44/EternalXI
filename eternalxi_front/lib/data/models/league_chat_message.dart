import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueChatMessage {
  const LeagueChatMessage({
    required this.id,
    required this.idUsuario,
    required this.nickname,
    required this.foto,
    required this.texto,
    required this.creadoEn,
  });

  final int id;
  final int idUsuario;
  final String nickname;
  final String foto;
  final String texto;
  final DateTime? creadoEn;

  factory LeagueChatMessage.fromJson(Map<String, dynamic> json) {
    return LeagueChatMessage(
      id: readLeagueInt(json, const ['id']),
      idUsuario: readLeagueInt(json, const ['idUsuario', 'id_usuario']),
      nickname: readLeagueString(json, const ['nickname', 'nick']),
      foto: readLeagueString(json, const ['foto']),
      texto: readLeagueString(json, const ['texto', 'text', 'mensaje']),
      creadoEn: _parseDate(json['creadoEn'] ?? json['creado_en']),
    );
  }

  static List<LeagueChatMessage> listFrom(dynamic data) {
    if (data is! List) return const [];
    final out = <LeagueChatMessage>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(LeagueChatMessage.fromJson(m));
    }
    return out;
  }

  String? resolvedPhotoUrl({int? cacheBuster}) {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(foto);
    if (fromApi != null) return fromApi;
    if (foto.trim().isEmpty && idUsuario > 0) {
      return ApiConstants.userProfilePhotoUrl(
        idUsuario,
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

import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class Friendship {
  const Friendship({
    required this.id,
    required this.idUsuario,
    required this.nickname,
    required this.foto,
    required this.estado,
    required this.soySolicitante,
    required this.creadoEn,
  });

  final int id;
  final int idUsuario;
  final String nickname;
  final String foto;
  final String estado;
  final bool soySolicitante;
  final DateTime? creadoEn;

  bool get isAccepted => estado.toUpperCase() == 'ACEPTADA';
  bool get isPending => estado.toUpperCase() == 'PENDIENTE';

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: readLeagueInt(json, const ['id']),
      idUsuario: readLeagueInt(json, const [
        'idUsuario',
        'id_usuario',
        'peerId',
        'peer_id',
      ]),
      nickname: readLeagueString(json, const ['nickname', 'peerNick', 'peer_nick']),
      foto: readLeagueString(json, const ['foto', 'peerFoto', 'peer_foto']),
      estado: readLeagueString(json, const ['estado', 'status']),
      soySolicitante: readLeagueBool(json, const [
        'soySolicitante',
        'soy_solicitante',
      ]),
      creadoEn: _parseDate(json['creadoEn'] ?? json['creado_en']),
    );
  }

  static List<Friendship> listFrom(dynamic data) {
    if (data is! List) return const [];
    final out = <Friendship>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(Friendship.fromJson(m));
    }
    return out;
  }

  String? resolvedPhotoUrl() {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(foto);
    if (fromApi != null) return fromApi;
    if (foto.trim().isEmpty && idUsuario > 0) {
      return ApiConstants.userProfilePhotoUrl(idUsuario, cacheBuster: idUsuario);
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

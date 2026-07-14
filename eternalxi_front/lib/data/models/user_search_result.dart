import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.nickname,
    required this.foto,
    required this.relacionAmistad,
  });

  final int id;
  final String nickname;
  final String foto;
  final String? relacionAmistad;

  bool get isFriend => relacionAmistad?.toUpperCase() == 'ACEPTADA';
  bool get isPending => relacionAmistad?.toUpperCase() == 'PENDIENTE';

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    final rel = readLeagueString(json, const [
      'relacionAmistad',
      'relacion_amistad',
    ]);
    return UserSearchResult(
      id: readLeagueInt(json, const ['id']),
      nickname: readLeagueString(json, const ['nickname']),
      foto: readLeagueString(json, const ['foto']),
      relacionAmistad: rel.isEmpty ? null : rel,
    );
  }

  static List<UserSearchResult> listFrom(dynamic data) {
    if (data is! List) return const [];
    final out = <UserSearchResult>[];
    for (final e in data) {
      if (e is! Map) continue;
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(UserSearchResult.fromJson(m));
    }
    return out;
  }

  String? resolvedPhotoUrl() {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(foto);
    if (fromApi != null) return fromApi;
    if (foto.trim().isEmpty && id > 0) {
      return ApiConstants.userProfilePhotoUrl(id, cacheBuster: id);
    }
    return null;
  }
}

import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Participante de una liga.
class LeagueParticipant {
  const LeagueParticipant({
    required this.idLigaParticipante,
    required this.idUsuario,
    required this.nickname,
    this.fotoUsuario = '',
    required this.admin,
    required this.puntosTotales,
    required this.dinero,
    required this.valorTotalEquipo,
  });

  /// Identificador en `liga_participantes` (si el backend lo envía).
  final int idLigaParticipante;
  final int idUsuario;
  final String nickname;
  final String fotoUsuario;
  final bool admin;
  final double puntosTotales;
  final double dinero;
  final double valorTotalEquipo;

  factory LeagueParticipant.fromJson(Map<String, dynamic> json) {
    return LeagueParticipant(
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
        'idParticipante',
      ]),
      idUsuario: readLeagueInt(json, const [
        'idUsuario',
        'id_usuario',
        'usuarioId',
      ]),
      nickname: readLeagueString(json, const ['nickname', 'nick', 'alias']),
      fotoUsuario: readLeagueString(json, const [
        'foto',
        'fotoUsuario',
        'foto_usuario',
        'avatar',
        'avatarUrl',
        'fotoPerfil',
        'foto_perfil',
      ]),
      admin: readLeagueBool(json, const ['admin', 'esAdmin', 'es_admin']),
      puntosTotales: readLeagueDouble(json, const [
        'puntosTotales',
        'puntos_totales',
        'puntos',
      ]),
      dinero: readLeagueDouble(json, const ['dinero', 'saldo']),
      valorTotalEquipo: readLeagueDouble(json, const [
        'valorTotalEquipo',
        'valor_total_equipo',
        'valorEquipo',
        'valor_equipo',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idLigaParticipante': idLigaParticipante,
      'idUsuario': idUsuario,
      'nickname': nickname,
      'fotoUsuario': fotoUsuario,
      'admin': admin,
      'puntosTotales': puntosTotales,
      'dinero': dinero,
      'valorTotalEquipo': valorTotalEquipo,
    };
  }

  String? resolvedFotoUsuarioUrl() {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(fotoUsuario);
    if (fromApi != null) {
      return fromApi;
    }
    if (fotoUsuario.trim().isEmpty && idUsuario > 0) {
      return ApiConstants.userProfilePhotoUrl(
        idUsuario,
        cacheBuster: idUsuario,
      );
    }
    return null;
  }
}

import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Fila de clasificación (standings).
class LeagueStandingRow {
  const LeagueStandingRow({
    required this.posicion,
    this.idLigaParticipante = 0,
    required this.idUsuario,
    required this.nickname,
    this.fotoUsuario = '',
    this.nombreEquipo = '',
    this.fotoEquipo = '',
    required this.puntosTotales,
    required this.dinero,
    required this.valorTotalEquipo,
    required this.admin,
  });

  final int posicion;
  final int idLigaParticipante;
  final int idUsuario;
  final String nickname;
  final String fotoUsuario;
  final String nombreEquipo;
  final String fotoEquipo;
  final double puntosTotales;
  final double dinero;
  final double valorTotalEquipo;
  final bool admin;

  factory LeagueStandingRow.fromJson(Map<String, dynamic> json) {
    return LeagueStandingRow(
      posicion: readLeagueInt(json, const [
        'posicion',
        'posición',
        'position',
        'rank',
        'orden',
      ]),
      idLigaParticipante: readLeagueInt(json, const [
        'idLigaParticipante',
        'id_liga_participante',
        'idParticipante',
        'ligaParticipanteId',
        'liga_participante_id',
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
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
        'equipo',
        'teamName',
      ]),
      fotoEquipo: readLeagueString(json, const [
        'fotoEquipo',
        'foto_equipo',
        'escudoEquipo',
        'escudo_equipo',
      ]),
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
      admin: readLeagueBool(json, const [
        'admin',
        'esAdmin',
        'es_admin',
        'soyAdmin',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posicion': posicion,
      'idLigaParticipante': idLigaParticipante,
      'idUsuario': idUsuario,
      'nickname': nickname,
      'fotoUsuario': fotoUsuario,
      'nombreEquipo': nombreEquipo,
      'fotoEquipo': fotoEquipo,
      'puntosTotales': puntosTotales,
      'dinero': dinero,
      'valorTotalEquipo': valorTotalEquipo,
      'admin': admin,
    };
  }

  String? resolvedFotoEquipoUrl() {
    return LeagueAssetUrls.buildBackendImageUrl(fotoEquipo);
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

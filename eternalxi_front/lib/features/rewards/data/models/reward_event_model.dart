import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';

class RewardEventModel {
  const RewardEventModel({
    required this.id,
    required this.tipo,
    required this.idCarta,
    required this.idLigaJugador,
    required this.idLigaParticipanteObjetivo,
    required this.packType,
    required this.cantidad,
    required this.descripcion,
    required this.creadoEn,
  });

  final int id;
  final String tipo;
  final int? idCarta;
  final int? idLigaJugador;
  final int? idLigaParticipanteObjetivo;
  final String? packType;
  final int? cantidad;
  final String descripcion;
  final DateTime? creadoEn;

  factory RewardEventModel.fromJson(Map<String, dynamic> json) {
    return RewardEventModel(
      id: readLeagueInt(json, const ['id']),
      tipo: readLeagueString(json, const ['tipo', 'type']),
      idCarta: _optInt(json, const ['idCarta', 'id_carta']),
      idLigaJugador: _optInt(json, const ['idLigaJugador', 'id_liga_jugador']),
      idLigaParticipanteObjetivo: _optInt(json, const [
        'idLigaParticipanteObjetivo',
        'id_liga_participante_objetivo',
      ]),
      packType: _optString(json, const ['packType', 'pack_type']),
      cantidad: _optInt(json, const ['cantidad']),
      descripcion: readLeagueString(json, const ['descripcion', 'description']),
      creadoEn: parseRewardDate(json['creadoEn'] ?? json['creado_en']),
    );
  }

  static List<RewardEventModel> listFrom(dynamic data) {
    if (data is! List) {
      return const [];
    }
    final out = <RewardEventModel>[];
    for (final e in data) {
      if (e is! Map) {
        continue;
      }
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(RewardEventModel.fromJson(m));
    }
    return out;
  }
}

int? _optInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (!json.containsKey(k) || json[k] == null) {
      continue;
    }
    return readLeagueInt(json, [k]);
  }
  return null;
}

String? _optString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (!json.containsKey(k) || json[k] == null) {
      continue;
    }
    final s = readLeagueString(json, [k]);
    return s.trim().isEmpty ? null : s;
  }
  return null;
}

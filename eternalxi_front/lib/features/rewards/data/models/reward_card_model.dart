import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart'
    show parseRewardDate;

class RewardCardModel {
  const RewardCardModel({
    required this.idCarta,
    required this.idDefinicion,
    required this.codigo,
    required this.nombre,
    required this.rareza,
    required this.tipoEfecto,
    required this.descripcion,
    required this.parametrosJson,
    required this.estado,
    required this.obtenidoEn,
    required this.usadoEn,
  });

  final int idCarta;
  final int idDefinicion;
  final String codigo;
  final String nombre;
  final String rareza;
  final String tipoEfecto;
  final String descripcion;
  final String? parametrosJson;
  final String estado;
  final DateTime? obtenidoEn;
  final DateTime? usadoEn;

  bool get isAvailable => estado.trim().toUpperCase() == 'AVAILABLE';

  /// Cartas de subida permanente de valor (incluye alias legacy en BD).
  bool get isValueBoost {
    final t = tipoEfecto.trim().toUpperCase();
    return t == 'PLAYER_VALUE_BOOST' || t == 'TEMPORARY_VALUE_RECOVERY';
  }

  factory RewardCardModel.fromJson(Map<String, dynamic> json) {
    return RewardCardModel(
      idCarta: readLeagueInt(json, const ['idCarta', 'id_carta']),
      idDefinicion: readLeagueInt(json, const ['idDefinicion', 'id_definicion']),
      codigo: readLeagueString(json, const ['codigo', 'code']),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      rareza: readLeagueString(json, const ['rareza', 'rarity']).trim(),
      tipoEfecto: readLeagueString(json, const ['tipoEfecto', 'tipo_efecto']),
      descripcion: readLeagueString(json, const ['descripcion', 'description']),
      parametrosJson: _nullableString(json['parametrosJson'] ?? json['parametros_json']),
      estado: readLeagueString(json, const ['estado', 'status']),
      obtenidoEn: parseRewardDate(json['obtenidoEn'] ?? json['obtenido_en']),
      usadoEn: parseRewardDate(json['usadoEn'] ?? json['usado_en']),
    );
  }

  static List<RewardCardModel> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <RewardCardModel>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
      out.add(RewardCardModel.fromJson(m));
    }
    return out;
  }
}

String? _nullableString(Object? v) {
  if (v == null) {
    return null;
  }
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  return '$v';
}

import 'package:eternal_xi/data/models/league_json_read.dart';

/// Probabilidades por rareza tal como envía el backend (orden de inserción conservado).
class RewardPackProbabilities {
  const RewardPackProbabilities._(this._values, this._order);

  final Map<String, int> _values;
  final List<String> _order;

  factory RewardPackProbabilities.fromJson(dynamic raw) {
    if (raw is! Map) {
      return const RewardPackProbabilities._({}, []);
    }
    final m = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
    final order = <String>[];
    final values = <String, int>{};
    for (final e in m.entries) {
      final key = _normalizeRarityKey(e.key);
      if (key.isEmpty) {
        continue;
      }
      final v = _parsePercentValue(e.value);
      if (!order.contains(key)) {
        order.add(key);
      }
      values[key] = v;
    }
    return RewardPackProbabilities._(values, order);
  }

  static String _normalizeRarityKey(Object? k) {
    if (k == null) {
      return '';
    }
    return k.toString().trim().toUpperCase().replaceAll('-', '_');
  }

  static int _parsePercentValue(Object? v) {
    if (v == null) {
      return 0;
    }
    if (v is int) {
      return v;
    }
    if (v is double) {
      return v.round();
    }
    if (v is String) {
      return int.tryParse(v.trim()) ?? 0;
    }
    return 0;
  }

  int _get(String canonicalKey, List<String> aliases) {
    for (final a in aliases) {
      final k = _normalizeRarityKey(a);
      if (_values.containsKey(k)) {
        return _values[k] ?? 0;
      }
    }
    return 0;
  }

  int get basic => _get('BASIC', const ['BASIC', 'basic']);
  int get normal => _get('NORMAL', const ['NORMAL', 'normal']);
  int get special => _get('SPECIAL', const ['SPECIAL', 'special']);
  int get superRare =>
      _get('SUPER_RARE', const ['SUPER_RARE', 'SUPERRARE', 'superRare']);
  int get legendary => _get('LEGENDARY', const ['LEGENDARY', 'legendary']);

  int get bestNonBasic {
    final list = <int>[special, superRare, legendary, normal];
    if (list.every((e) => e == 0)) {
      return 0;
    }
    return list.reduce((a, b) => a > b ? a : b);
  }

  /// Entradas en el orden del JSON del backend (para UI, sin cifras inventadas).
  List<MapEntry<String, int>> get orderedEntries {
    final out = <MapEntry<String, int>>[];
    for (final k in _order) {
      out.add(MapEntry(k, _values[k] ?? 0));
    }
    return out;
  }
}

class RewardPackModel {
  const RewardPackModel({
    required this.packType,
    required this.nombre,
    required this.costePuntos,
    required this.presupuestoMin,
    required this.presupuestoMax,
    required this.probabilidades,
  });

  final String packType;
  final String nombre;
  final int costePuntos;
  final int presupuestoMin;
  final int presupuestoMax;
  final RewardPackProbabilities probabilidades;

  factory RewardPackModel.fromJson(Map<String, dynamic> json) {
    return RewardPackModel(
      packType: readLeagueString(json, const ['packType', 'pack_type']),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      costePuntos: readLeagueInt(json, const ['costePuntos', 'coste_puntos']),
      presupuestoMin: readLeagueInt(json, const [
        'presupuestoMin',
        'presupuesto_min',
      ]),
      presupuestoMax: readLeagueInt(json, const [
        'presupuestoMax',
        'presupuesto_max',
      ]),
      probabilidades: RewardPackProbabilities.fromJson(
        json['probabilidades'] ?? json['probabilities'],
      ),
    );
  }
}

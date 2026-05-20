import 'package:eternal_xi/data/models/league_json_read.dart';

/// Hueco vacío en alineación (`emptySlots`).
class LeagueLineupEmptySlot {
  const LeagueLineupEmptySlot({
    this.posicion = '',
    this.orden = 0,
    this.penalizacion = 0,
    this.emptySlot = true,
  });

  final String posicion;
  final int orden;
  final int penalizacion;
  final bool emptySlot;

  factory LeagueLineupEmptySlot.fromJson(Map<String, dynamic> json) {
    return LeagueLineupEmptySlot(
      posicion: readLeagueString(json, const ['posicion', 'posición', 'role']),
      orden: readLeagueInt(json, const ['orden', 'order', 'slot']),
      penalizacion: readLeagueInt(json, const [
        'penalizacion',
        'penalización',
        'penalty',
      ]),
      emptySlot: readLeagueBool(
        json,
        const ['emptySlot', 'empty_slot', 'hueco'],
        fallback: true,
      ),
    );
  }

  static List<LeagueLineupEmptySlot> listFromJson(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <LeagueLineupEmptySlot>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final map = e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e);
      out.add(LeagueLineupEmptySlot.fromJson(map));
    }
    return out;
  }
}

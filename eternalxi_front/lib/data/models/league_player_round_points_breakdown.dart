import 'package:eternal_xi/data/models/league_json_read.dart';

/// Desglose oficial de puntos fantasy por estadística (`puntosDesglose` en API).
class LeaguePlayerRoundPointsBreakdown {
  const LeaguePlayerRoundPointsBreakdown({
    this.minutos,
    this.goles,
    this.asistencias,
    this.paradas,
    this.regates,
    this.balonesRecuperados,
    this.porteriaCero,
    this.golesEncajados,
    this.tarjetasAmarillas,
    this.tarjetasRojas,
    this.lesion,
    this.notaPeriodico,
  });

  final double? minutos;
  final double? goles;
  final double? asistencias;
  final double? paradas;
  final double? regates;
  final double? balonesRecuperados;
  final double? porteriaCero;
  final double? golesEncajados;
  final double? tarjetasAmarillas;
  final double? tarjetasRojas;
  final double? lesion;
  final double? notaPeriodico;

  static const empty = LeaguePlayerRoundPointsBreakdown();

  bool get hasAny =>
      minutos != null ||
      goles != null ||
      asistencias != null ||
      paradas != null ||
      regates != null ||
      balonesRecuperados != null ||
      porteriaCero != null ||
      golesEncajados != null ||
      tarjetasAmarillas != null ||
      tarjetasRojas != null ||
      lesion != null ||
      notaPeriodico != null;

  LeaguePlayerRoundPointsBreakdown mergeLegacyParadas(double? puntosFantasyParadas) {
    if (paradas != null || puntosFantasyParadas == null) {
      return this;
    }
    return LeaguePlayerRoundPointsBreakdown(
      minutos: minutos,
      goles: goles,
      asistencias: asistencias,
      paradas: puntosFantasyParadas,
      regates: regates,
      balonesRecuperados: balonesRecuperados,
      porteriaCero: porteriaCero,
      golesEncajados: golesEncajados,
      tarjetasAmarillas: tarjetasAmarillas,
      tarjetasRojas: tarjetasRojas,
      lesion: lesion,
      notaPeriodico: notaPeriodico,
    );
  }

  factory LeaguePlayerRoundPointsBreakdown.fromJson(dynamic raw) {
    if (raw is! Map) {
      return empty;
    }
    final map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    return LeaguePlayerRoundPointsBreakdown(
      minutos: _readOptionalPoints(map, const ['minutos']),
      goles: _readOptionalPoints(map, const ['goles']),
      asistencias: _readOptionalPoints(map, const ['asistencias']),
      paradas: _readOptionalPoints(map, const [
        'paradas',
        'puntosParadas',
        'puntos_paradas',
      ]),
      regates: _readOptionalPoints(map, const ['regates']),
      balonesRecuperados: _readOptionalPoints(map, const [
        'balonesRecuperados',
        'balones_recuperados',
        'recuperaciones',
      ]),
      porteriaCero: _readOptionalPoints(map, const [
        'porteriaCero',
        'porteria_cero',
        'cleanSheet',
      ]),
      golesEncajados: _readOptionalPoints(map, const [
        'golesEncajados',
        'goles_encajados',
      ]),
      tarjetasAmarillas: _readOptionalPoints(map, const [
        'tarjetasAmarillas',
        'tarjetas_amarillas',
        'amarillas',
      ]),
      tarjetasRojas: _readOptionalPoints(map, const [
        'tarjetasRojas',
        'tarjetas_rojas',
        'rojas',
      ]),
      lesion: _readOptionalPoints(map, const [
        'lesion',
        'lesionado',
        'lesionadoEnPartido',
        'lesionado_en_partido',
      ]),
      notaPeriodico: _readOptionalPoints(map, const [
        'notaPeriodico',
        'nota_periodico',
        'nota',
      ]),
    );
  }
}

double? _readOptionalPoints(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final v = json[key];
    if (v == null) {
      return null;
    }
    if (v is double) {
      return v;
    }
    if (v is int) {
      return v.toDouble();
    }
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) {
        return null;
      }
      return double.tryParse(t.replaceAll(',', '.'));
    }
  }
  return null;
}

LeaguePlayerRoundPointsBreakdown readLeagueRoundPointsBreakdown(
  Map<String, dynamic> json,
) {
  final raw = json['puntosDesglose'] ?? json['puntos_desglose'];
  final parsed = LeaguePlayerRoundPointsBreakdown.fromJson(raw);
  final legacyParadas = readLeagueParadasFantasyPoints(json);
  return parsed.mergeLegacyParadas(legacyParadas);
}

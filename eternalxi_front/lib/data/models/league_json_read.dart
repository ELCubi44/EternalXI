// Utilidades internas para parsear JSON del backend de ligas (camelCase / snake_case).

Map<String, dynamic> _asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

Object? _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k)) {
      return json[k];
    }
  }
  return null;
}

int readLeagueInt(
  Map<String, dynamic> json,
  List<String> keys, {
  int fallback = 0,
}) {
  final v = _pick(json, keys);
  if (v is int) {
    return v;
  }
  if (v is double) {
    return v.round();
  }
  if (v is String) {
    return int.tryParse(v.trim()) ?? fallback;
  }
  return fallback;
}

/// Paradas de portero (`paradas` en API). Solo dato estadístico; no recalcular fantasy en cliente.
int readLeagueParadas(Map<String, dynamic> json) {
  const keys = <String>[
    'paradas',
    'paradas_totales',
    'paradasTotales',
    'saves',
  ];
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    if (v == null) {
      continue;
    }
    if (v is num) {
      return v.toInt();
    }
    if (v is String) {
      return int.tryParse(v.trim()) ?? 0;
    }
  }
  return 0;
}

/// Puntos fantasy atribuibles a paradas (desglose opcional del backend).
/// Ausente → `null`: la app no debe inferir paradas→puntos en cliente.
double? readLeagueParadasFantasyPoints(Map<String, dynamic> json) {
  return readLeagueOptionalDouble(json, const [
    'puntosParadas',
    'puntos_paradas',
    'puntosFantasyParadas',
    'puntos_fantasy_paradas',
    'fantasyPuntosParadas',
    'fantasy_puntos_paradas',
    'puntosParadasFantasy',
    'puntos_paradas_fantasy',
    'paradasFantasyPoints',
    'paradas_fantasy_points',
    'impactoParadas',
    'impacto_paradas',
    'puntosPorParadas',
    'puntos_por_paradas',
    'savesFantasyPoints',
    'saves_fantasy_points',
  ]);
}

double readLeagueDouble(
  Map<String, dynamic> json,
  List<String> keys, {
  double fallback = 0,
}) {
  final v = _pick(json, keys);
  if (v is double) {
    return v;
  }
  if (v is int) {
    return v.toDouble();
  }
  if (v is String) {
    return double.tryParse(v.trim().replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

bool readLeagueBool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  final v = _pick(json, keys);
  if (v is bool) {
    return v;
  }
  if (v is int) {
    return v != 0;
  }
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'si' || s == 'sí') {
      return true;
    }
    if (s == 'false' || s == '0') {
      return false;
    }
  }
  return fallback;
}

String readLeagueString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  final v = _pick(json, keys);
  if (v == null) {
    return fallback;
  }
  return v.toString();
}

/// API (DTO jugador): [`probabilidadTitular`] y alias snake [`probabilidad_titular`].
/// Ausente → `null`; JSON `null` explícito → `null`; número → [0, 95].
int? readLeagueOptionalProbabilityTitular(Map<String, dynamic> json) {
  const keys = ['probabilidadTitular', 'probabilidad_titular'];
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    if (v == null) {
      return null;
    }
    final n = switch (v) {
      int() => v,
      double() => v.round(),
      _ => int.tryParse(v.toString().trim()) ?? 0,
    };
    return n.clamp(0, 95);
  }
  return null;
}

/// Primera clave presente con texto no vacío; ausente o vacío → `null`.
String? readLeagueOptionalNonEmptyString(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    if (v == null) {
      return null;
    }
    final s = v.toString().trim();
    if (s.isNotEmpty) {
      return s;
    }
    return null;
  }
  return null;
}

/// Id opcional; ausente o `null` o ≤0 → `null`.
int? readLeagueOptionalPositiveInt(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    if (v == null) {
      return null;
    }
    final n = readLeagueInt(json, [k]);
    return n > 0 ? n : null;
  }
  return null;
}

/// Número decimal opcional; ninguna clave presente o valor `null` → `null`.
double? readLeagueOptionalDouble(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    if (v == null) {
      return null;
    }
    return readLeagueDouble(json, [k]);
  }
  return null;
}

/// Fecha/hora opcional desde ISO u objeto ya parseable.
DateTime? readLeagueOptionalDateTime(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final k in keys) {
    if (!json.containsKey(k)) {
      continue;
    }
    final v = json[k];
    if (v == null) {
      return null;
    }
    if (v is DateTime) {
      return v;
    }
    final s = v.toString().trim();
    if (s.isEmpty) {
      return null;
    }
    return DateTime.tryParse(s);
  }
  return null;
}

int readParticipantesCount(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is int) {
    return v;
  }
  if (v is double) {
    return v.round();
  }
  if (v is String) {
    return int.tryParse(v.trim()) ?? 0;
  }
  if (v is List) {
    return v.length;
  }
  return 0;
}

List<Map<String, dynamic>> readLeagueListMap(dynamic data) {
  if (data is List) {
    return data.map((e) => _asJsonMap(e)).toList();
  }
  if (data is Map<String, dynamic>) {
    for (final key in const [
      'data',
      'ligas',
      'leagues',
      'items',
      'results',
      'standings',
      'participants',
      'jugadores',
      'seasons',
      'temporadas',
      'liga_jugadores',
      'ligaJugadores',
      'squad',
      'market',
      'mercado',
      'rows',
    ]) {
      final inner = data[key];
      if (inner is List) {
        return inner.map((e) => _asJsonMap(e)).toList();
      }
    }
  }
  return const [];
}

Map<String, dynamic> readLeagueSingleMap(dynamic data) {
  if (data is List && data.isNotEmpty) {
    return _asJsonMap(data.first);
  }
  if (data is Map<String, dynamic>) {
    if (data.containsKey('data') && data['data'] is Map) {
      return _asJsonMap(data['data']);
    }
    return data;
  }
  if (data is Map) {
    return readLeagueSingleMap(Map<String, dynamic>.from(data));
  }
  return <String, dynamic>{};
}

/// POST create/join de liga: el backend devuelve típicamente solo `idLiga` (o `id`), no un detalle completo.
/// También admite envoltorios `{ "data": <int> }` o `{ "data": { "idLiga": … } }`.
int readLeagueIdFromPostResponse(dynamic data) {
  if (data is int) {
    return data;
  }
  if (data is double) {
    return data.round();
  }
  if (data is String) {
    return int.tryParse(data.trim()) ?? 0;
  }
  if (data is Map) {
    final m = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);
    final wrapped = m['data'];
    if (wrapped != null && wrapped is! Map && wrapped is! List) {
      final inner = readLeagueIdFromPostResponse(wrapped);
      if (inner > 0) {
        return inner;
      }
    }
  }
  final map = readLeagueSingleMap(data);
  return readLeagueInt(map, const [
    'idLiga',
    'id_liga',
    'id',
    'leagueId',
    'ligaId',
  ]);
}

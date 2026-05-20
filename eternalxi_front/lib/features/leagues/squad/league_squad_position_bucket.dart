/// Línea de campo para agrupar la plantilla (orden de sección en UI).
enum LeagueSquadLine { porteros, defensas, mediocentros, delanteros, otros }

/// Clasifica el texto de [LeagueSquadPlayer.posicion] en una línea de juego.
abstract final class LeagueSquadPositionBucket {
  LeagueSquadPositionBucket._();

  /// Orden en que se muestran las secciones en pantalla.
  static const List<LeagueSquadLine> displayOrder = [
    LeagueSquadLine.porteros,
    LeagueSquadLine.defensas,
    LeagueSquadLine.mediocentros,
    LeagueSquadLine.delanteros,
    LeagueSquadLine.otros,
  ];

  static LeagueSquadLine forPosition(String raw) {
    final p = _normalize(raw);
    if (p.isEmpty) {
      return LeagueSquadLine.otros;
    }

    final code = _firstMeaningfulToken(p);
    if (code.length <= 4) {
      const short = <String, LeagueSquadLine>{
        'por': LeagueSquadLine.porteros,
        'gk': LeagueSquadLine.porteros,
        'def': LeagueSquadLine.defensas,
        'dfc': LeagueSquadLine.defensas,
        'lat': LeagueSquadLine.defensas,
        'li': LeagueSquadLine.defensas,
        'ld': LeagueSquadLine.defensas,
        'dc': LeagueSquadLine.defensas,
        'mc': LeagueSquadLine.mediocentros,
        'med': LeagueSquadLine.mediocentros,
        'mco': LeagueSquadLine.mediocentros,
        'md': LeagueSquadLine.mediocentros,
        'mi': LeagueSquadLine.mediocentros,
        'del': LeagueSquadLine.delanteros,
        'fw': LeagueSquadLine.delanteros,
        'dl': LeagueSquadLine.delanteros,
      };
      final hit = short[code];
      if (hit != null) {
        return hit;
      }
    }

    if (_matches(p, const [
      'portero',
      'portera',
      'guardameta',
      'arquero',
      'goalkeeper',
      'gk',
      'pt',
    ])) {
      return LeagueSquadLine.porteros;
    }

    if (_matches(p, const [
      'defensa',
      'defensor',
      'defensivo',
      'lateral',
      'centrocampista defensivo',
      'libero',
      'carrilero',
      'df',
      'dc',
      'li',
      'ld',
      'dfc',
      'def',
    ])) {
      return LeagueSquadLine.defensas;
    }

    // Antes que delanteros: evita que "punta" dentro de "mediapunta" clasifique mal.
    if (_matches(p, const [
      'mediocentro',
      'centrocampista',
      'medio',
      'mediapunta',
      'interior',
      'pivote',
      'volante',
      'extremo',
      'mc',
      'mco',
      'mf',
      'md',
      'mi',
      'med',
      'wing',
      'carrilero ofensivo',
    ])) {
      return LeagueSquadLine.mediocentros;
    }

    if (_matches(p, const [
      'delantero',
      'delantera',
      'punta',
      'nueve',
      'segundo delantero',
      'falso nueve',
      'st',
      'fw',
      'fwl',
      'fwr',
      'att',
      'forward',
    ])) {
      return LeagueSquadLine.delanteros;
    }

    return LeagueSquadLine.otros;
  }

  /// Primer token alfanumérico (p. ej. `POR`, `DEL-9` → `del`).
  static String _firstMeaningfulToken(String normalized) {
    final parts = normalized.split(RegExp(r'[\s/|,_\-]+'));
    for (final part in parts) {
      final t = part.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (t.isNotEmpty) {
        return t;
      }
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _normalize(String raw) {
    var s = raw.toLowerCase().trim();
    const map = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    for (final e in map.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s;
  }

  static bool _matches(String normalized, List<String> needles) {
    for (final n in needles) {
      if (normalized == n || normalized.contains(n)) {
        return true;
      }
    }
    return false;
  }

  static String sectionTitle(LeagueSquadLine line) {
    switch (line) {
      case LeagueSquadLine.porteros:
        return 'Porteros';
      case LeagueSquadLine.defensas:
        return 'Defensas';
      case LeagueSquadLine.mediocentros:
        return 'Mediocentros';
      case LeagueSquadLine.delanteros:
        return 'Delanteros';
      case LeagueSquadLine.otros:
        return 'Otras posiciones';
    }
  }
}

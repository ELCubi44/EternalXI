import 'package:eternal_xi/data/models/league_squad_player.dart';

/// Recuentos de líneas para una formación tipo "4-4-2" (sin contar portero).
class MatchFormationCounts {
  const MatchFormationCounts({
    required this.defenders,
    required this.midfielders,
    required this.forwards,
  });

  final int defenders;
  final int midfielders;
  final int forwards;

  static const MatchFormationCounts fallback433 = MatchFormationCounts(
    defenders: 4,
    midfielders: 3,
    forwards: 3,
  );
}

/// Interpreta [raw] como "X-Y-Z". Si falta o es inválida, [MatchFormationCounts.fallback433].
MatchFormationCounts parseMatchFormation(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) {
    return MatchFormationCounts.fallback433;
  }
  final parts = t.split(RegExp(r'[-–—]'));
  if (parts.length != 3) {
    return MatchFormationCounts.fallback433;
  }
  final a = int.tryParse(parts[0].trim());
  final b = int.tryParse(parts[1].trim());
  final c = int.tryParse(parts[2].trim());
  if (a == null || b == null || c == null || a < 0 || b < 0 || c < 0) {
    return MatchFormationCounts.fallback433;
  }
  return MatchFormationCounts(defenders: a, midfielders: b, forwards: c);
}

enum _MatchPosBand { por, def, med, del, unknown }

_MatchPosBand _band(LeagueSquadPlayer p) {
  final pos = p.posicion.trim().toUpperCase();
  if (pos.startsWith('POR')) {
    return _MatchPosBand.por;
  }
  if (pos.startsWith('DEF')) {
    return _MatchPosBand.def;
  }
  if (pos.startsWith('MED') || pos.startsWith('MC')) {
    return _MatchPosBand.med;
  }
  if (pos.startsWith('DEL')) {
    return _MatchPosBand.del;
  }
  return _MatchPosBand.unknown;
}

int _compareMatchStarters(LeagueSquadPlayer a, LeagueSquadPlayer b) {
  final va = a.valoracion;
  final vb = b.valoracion;
  if (va != vb) {
    return vb.compareTo(va);
  }
  final na = a.nombre.trim().toLowerCase();
  final nb = b.nombre.trim().toLowerCase();
  final c = na.compareTo(nb);
  if (c != 0) {
    return c;
  }
  return a.pila.trim().toLowerCase().compareTo(b.pila.trim().toLowerCase());
}

/// Titulares colocados en líneas según [counts]; rellena huecos con jugadores restantes.
class MatchLineupPitchSlices {
  const MatchLineupPitchSlices({
    required this.goalkeepers,
    required this.defenders,
    required this.midfielders,
    required this.forwards,
  });

  final List<LeagueSquadPlayer> goalkeepers;
  final List<LeagueSquadPlayer> defenders;
  final List<LeagueSquadPlayer> midfielders;
  final List<LeagueSquadPlayer> forwards;
}

MatchLineupPitchSlices buildMatchPitchSlices({
  required List<LeagueSquadPlayer> starters,
  required MatchFormationCounts counts,
}) {
  final ordered = List<LeagueSquadPlayer>.from(starters)..sort(_compareMatchStarters);

  final gkPool = <LeagueSquadPlayer>[];
  final defPool = <LeagueSquadPlayer>[];
  final midPool = <LeagueSquadPlayer>[];
  final fwdPool = <LeagueSquadPlayer>[];
  final unkPool = <LeagueSquadPlayer>[];

  for (final p in ordered) {
    switch (_band(p)) {
      case _MatchPosBand.por:
        gkPool.add(p);
      case _MatchPosBand.def:
        defPool.add(p);
      case _MatchPosBand.med:
        midPool.add(p);
      case _MatchPosBand.del:
        fwdPool.add(p);
      case _MatchPosBand.unknown:
        unkPool.add(p);
    }
  }

  final used = <LeagueSquadPlayer>{};

  List<LeagueSquadPlayer> takeN(List<LeagueSquadPlayer> pool, int n) {
    final out = <LeagueSquadPlayer>[];
    for (final p in pool) {
      if (out.length >= n) {
        break;
      }
      if (used.add(p)) {
        out.add(p);
      }
    }
    return out;
  }

  var gk = takeN(gkPool, 1);
  var def = takeN(defPool, counts.defenders);
  var mid = takeN(midPool, counts.midfielders);
  var fwd = takeN(fwdPool, counts.forwards);

  final spill = <LeagueSquadPlayer>[
    ...gkPool,
    ...defPool,
    ...midPool,
    ...fwdPool,
    ...unkPool,
  ]..sort(_compareMatchStarters);

  final surplus = <LeagueSquadPlayer>[];
  for (final p in spill) {
    if (!used.contains(p)) {
      surplus.add(p);
    }
  }

  void fillLine(List<LeagueSquadPlayer> line, int target) {
    while (line.length < target && surplus.isNotEmpty) {
      line.add(surplus.removeAt(0));
      used.add(line.last);
    }
  }

  fillLine(gk, 1);
  fillLine(def, counts.defenders);
  fillLine(mid, counts.midfielders);
  fillLine(fwd, counts.forwards);

  while (surplus.isNotEmpty) {
    if (def.length < counts.defenders) {
      def.add(surplus.removeAt(0));
      continue;
    }
    if (mid.length < counts.midfielders) {
      mid.add(surplus.removeAt(0));
      continue;
    }
    if (fwd.length < counts.forwards) {
      fwd.add(surplus.removeAt(0));
      continue;
    }
    if (gk.isEmpty) {
      gk.add(surplus.removeAt(0));
      continue;
    }
    mid.add(surplus.removeAt(0));
  }

  return MatchLineupPitchSlices(
    goalkeepers: gk,
    defenders: def,
    midfielders: mid,
    forwards: fwd,
  );
}

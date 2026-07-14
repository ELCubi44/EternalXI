// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const _positions = [
  'goalkeeper',
  'centreBack',
  'fullBack',
  'defensiveMidfielder',
  'attackingMidfielder',
  'winger',
  'striker',
];

const _trialRivals = {
  'trial-attack': [
    'Favela Estrela',
    'Furia Menuda',
    'Instinto Real',
    'Academia Tianlong',
    'Dunas Movedizas',
  ],
  'trial-midfield': [
    'Academia Zenith',
    'Colegio Runaria',
    'Faro del Alba',
    'Legado Unido',
    'Asfalto Sur',
  ],
  'trial-defense': [
    'Bastion Adler',
    'Pico Artico',
    'Sistema Cero',
    'Ojo Vigilante',
    'Panteon Caido',
  ],
  'trial-goalkeeper': [
    'Colegio Runaria',
    'Faro del Alba',
    'Legado Unido',
    'Academia Zenith',
    'Instinto Real',
  ],
};

const _teamStories = {
  'Favela Estrela': 'La calle exige goles. Sus delanteros no perdonan.',
  'Furia Menuda': 'Pequenos pero letales. Velocidad pura en ataque.',
  'Instinto Real': 'Juegan sin miedo. Cada contra es una sentencia.',
  'Academia Tianlong': 'Disciplina oriental y remates desde lejos.',
  'Dunas Movedizas': 'El desierto los endurecio. Ataque implacable.',
  'Academia Zenith': 'Control total del balon en el centro del campo.',
  'Colegio Runaria': 'Formacion academica con pases de precision.',
  'Faro del Alba': 'Presion alta y transiciones rapidas.',
  'Legado Unido': 'Mediocampo solido que domina el ritmo.',
  'Asfalto Sur': 'Fisico y garra en cada duelo del centro.',
  'Bastion Adler': 'Muralla alemana. Defensa impenetrable.',
  'Pico Artico': 'Frialdad bajo cero en cada entrada.',
  'Sistema Cero': 'Maquina defensiva. Cero espacios.',
  'Ojo Vigilante': 'Vigilan cada linea de pase sin descanso.',
  'Panteon Caido': 'Defensas legendarios resucitan en cada piso.',
};

void main() {
  final root = Directory.current.path.contains('eternalxi_front')
      ? Directory('..')
      : Directory.current;
  final cardsFile = File('${root.path}/eternalxi_front/assets/data/clash/cards.json');
  final rivalsOut = File('${root.path}/eternalxi_front/assets/data/clash/rivals.json');
  final trialsOut = File('${root.path}/eternalxi_front/assets/data/clash/trials.json');

  final decoded = jsonDecode(cardsFile.readAsStringSync()) as Map<String, dynamic>;
  final cards = (decoded['cards'] as List)
      .map((c) => Map<String, dynamic>.from(c as Map))
      .where((c) => c['rarity'] == 'n' && c['team'] != 'Eternal XI')
      .toList();

  final byTeam = <String, List<Map<String, dynamic>>>{};
  for (final card in cards) {
    final team = card['team'] as String;
    byTeam.putIfAbsent(team, () => []).add(card);
  }

  String slug(String team) => team
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  final rivals = <Map<String, dynamic>>[];
  final rivalIdsByTeam = <String, String>{};

  for (final entry in byTeam.entries) {
    final team = entry.key;
    final teamCards = entry.value;
    final lineup = _pickLineup(teamCards);
    if (lineup.length < 7) {
      print('SKIP $team: solo ${lineup.length} posiciones');
      continue;
    }

    final totalPower = lineup.fold<int>(
      0,
      (sum, c) => sum + _power(c['stats'] as Map<String, dynamic>),
    );
    final rivalId = 'rival-${slug(team)}';
    rivalIdsByTeam[team] = rivalId;

    rivals.add({
      'id': rivalId,
      'name': team,
      'description': _teamStories[team] ?? 'Rival de la temporada Eterno Campeon.',
      'difficulty': (totalPower / 40).round().clamp(1, 5),
      'recommendedPower': totalPower,
      'lineup7v7': lineup.map(_rivalPlayerFromCard).toList(),
    });
  }

  rivals.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  rivalsOut.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({'rivals': rivals}),
  );

  final trials = jsonDecode(trialsOut.readAsStringSync()) as Map<String, dynamic>;
  final trialList = trials['trials'] as List;
  for (final trialRaw in trialList) {
    final trial = trialRaw as Map<String, dynamic>;
    final trialId = trial['id'] as String;
    final teams = _trialRivals[trialId];
    if (teams == null) continue;
    final floors = trial['floors'] as List;
    for (var i = 0; i < floors.length && i < teams.length; i++) {
      final floor = floors[i] as Map<String, dynamic>;
      final team = teams[i];
      final rivalId = rivalIdsByTeam[team];
      if (rivalId == null) continue;
      floor['rivalTeamId'] = rivalId;
      final story = _teamStories[team];
      if (story != null) {
        floor['description'] = '${floor['title']}: $story';
      }
    }
  }

  trialsOut.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(trials),
  );

  print('Rivals: ${rivals.length}');
  print('Updated trials.json with real rival teams');
}

List<Map<String, dynamic>> _pickLineup(List<Map<String, dynamic>> cards) {
  if (cards.length < 7) return const [];

  final sorted = [...cards]
    ..sort(
      (a, b) => _power(Map<String, dynamic>.from(b['stats'] as Map))
          .compareTo(_power(Map<String, dynamic>.from(a['stats'] as Map))),
    );

  final used = <String>{};
  final picked = <Map<String, dynamic>>[];

  Map<String, dynamic>? takeBest(bool Function(Map<String, dynamic> c) test) {
    for (final card in sorted) {
      final id = card['id'] as String;
      if (used.contains(id)) continue;
      if (test(card)) {
        used.add(id);
        return card;
      }
    }
    return null;
  }

  Map<String, dynamic>? takeAny() {
    for (final card in sorted) {
      final id = card['id'] as String;
      if (!used.contains(id)) {
        used.add(id);
        return card;
      }
    }
    return null;
  }

  int stat(Map<String, dynamic> card, String key) {
    final stats = Map<String, dynamic>.from(card['stats'] as Map);
    return (stats[key] as num?)?.round() ?? 0;
  }

  for (final pos in _positions) {
    Map<String, dynamic>? card = takeBest((c) => c['position'] == pos);
    card ??= switch (pos) {
      'goalkeeper' => takeBest((c) => stat(c, 'save') >= stat(c, 'shot')),
      'centreBack' || 'fullBack' =>
        takeBest((c) => stat(c, 'defense') >= stat(c, 'dribble')),
      'defensiveMidfielder' || 'attackingMidfielder' =>
        takeBest((c) => stat(c, 'pass') >= 12),
      _ => takeBest((c) => stat(c, 'shot') + stat(c, 'dribble') >= 20),
    };
    card ??= takeAny();
    if (card == null) return picked;
    picked.add({
      ...card,
      'position': pos,
    });
  }

  return picked;
}

int _power(Map<String, dynamic> stats) {
  return stats.values.whereType<num>().fold<int>(0, (s, v) => s + v.round());
}

Map<String, dynamic> _rivalPlayerFromCard(Map<String, dynamic> card) {
  final st = (card['superTechniques'] as List?)?.cast<Map<String, dynamic>>() ??
      const [];
  return {
    'id': 'rival-${card['id']}',
    'playerId': card['playerId'],
    'name': card['name'],
    'position': card['position'],
    'style': card['style'],
    'rarity': card['rarity'],
    'level': 5,
    'stats': card['stats'],
    if (st.isNotEmpty) 'superTechniques': st,
  };
}

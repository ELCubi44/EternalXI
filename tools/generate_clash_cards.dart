// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current.path.contains('eternalxi_front')
      ? Directory('..')
      : Directory.current;
  final playersFile = File('${root.path}/.local/tools/clash_players.tsv');
  final stFile = File('${root.path}/.local/tools/clash_st.tsv');
  final outFile = File('${root.path}/eternalxi_front/assets/data/clash/cards.json');
  final manifestFile =
      File('${root.path}/eternalxi_front/assets/data/clash/cards_manifest.json');

  final players = _loadPlayers(playersFile);
  final stByPlayer = _loadSuperTechniques(stFile);
  final cards = <Map<String, dynamic>>[];
  final teamCounters = <String, int>{};

  for (final player in players) {
    final pid = player.id;
    final pos = player.posicion;
    final dorsal = player.dorsal;
    final position = _clashPosition(pos, dorsal);
    final pcode = _posCode(position);
    final teamSlug = _slugify(player.team);
    final seq = (teamCounters[teamSlug] ?? 0) + 1;
    teamCounters[teamSlug] = seq;
    final style = _styleMap[player.estilo]!;
    final stList = stByPlayer[pid] ?? const [];

    for (final rarity in ['n', 'r', 'sr']) {
      final cardId = '$teamSlug-$rarity-$pcode-${seq.toString().padLeft(3, '0')}';
      final stats = _buildStats(pos, player.valoracion, rarity);
      cards.add({
        'id': cardId,
        'playerId': pid,
        'name': player.name,
        'team': player.team,
        'dorsal': dorsal,
        'teamId': player.teamId,
        'rarity': rarity,
        'level': 1,
        'style': style,
        'position': position,
        'basicPortraitPath': 'network',
        'stats': stats,
        'superTechniques':
            _buildStEntries(stList, rarity, cardId),
      });
    }
  }

  final payload = {'schemaVersion': 1, 'cards': cards};
  final raw = const JsonEncoder.withIndent('  ').convert(payload);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(raw);
  final sizeBytes = outFile.lengthSync();

  final eternalXiN = cards
      .where((c) => c['team'] == 'Eternal XI' && c['rarity'] == 'n')
      .length;

  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'cardsVersion': 1,
      'cardsUrl': 'https://api.eternalxi.com/api/v1/assets/clash/cards.json',
      'cardsBytes': sizeBytes,
      'playerCount': players.length,
      'cardCount': cards.length,
      'portraitsBaseUrl': 'https://api.eternalxi.com/assets/players',
    }),
  );

  print('Generated ${cards.length} cards for ${players.length} players');
  print('Eternal XI N cards: $eternalXiN');
  print('Output: ${outFile.path} (${(sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB)');
}

const _styleMap = {
  'PICARO': 'picaro',
  'PRECISO': 'preciso',
  'POTENTE': 'potente',
  'VALIENTE': 'valiente',
  'AGIL': 'agil',
};

const _stTypeMap = {
  'PARADA': 'save',
  'DEFENSA': 'defense',
  'REGATE': 'dribble',
  'TIRO': 'shot',
};

const _posProfile = {
  'POR': {
    'save': [30, 14],
    'defense': [16, 8],
    'pass': [12, 6],
    'dribble': [6, 4],
    'shot': [4, 2],
    'techniquePoints': [16, 8],
    'stamina': [100, 8],
  },
  'DEF': {
    'save': [4, 2],
    'defense': [28, 12],
    'pass': [14, 6],
    'dribble': [10, 5],
    'shot': [8, 4],
    'techniquePoints': [16, 8],
    'stamina': [102, 8],
  },
  'MED': {
    'save': [3, 1],
    'defense': [16, 8],
    'pass': [22, 10],
    'dribble': [18, 8],
    'shot': [14, 6],
    'techniquePoints': [18, 8],
    'stamina': [104, 8],
  },
  'DEL': {
    'save': [3, 1],
    'defense': [12, 6],
    'pass': [14, 6],
    'dribble': [20, 10],
    'shot': [26, 12],
    'techniquePoints': [18, 8],
    'stamina': [105, 10],
  },
};

const _rarityMult = {'n': 1.0, 'r': 1.08, 'sr': 1.18};
const _rarityStCount = {'n': 1, 'r': 2, 'sr': 3};

class _PlayerRow {
  _PlayerRow({
    required this.id,
    required this.teamId,
    required this.team,
    required this.name,
    required this.pila,
    required this.dorsal,
    required this.posicion,
    required this.estilo,
    required this.valoracion,
  });

  final int id;
  final int teamId;
  final String team;
  final String name;
  final String pila;
  final int dorsal;
  final String posicion;
  final String estilo;
  final int valoracion;
}

class _StRow {
  _StRow({
    required this.orden,
    required this.nombre,
    required this.potencia,
    required this.tipo,
    required this.estilo,
  });

  final int orden;
  final String nombre;
  final int potencia;
  final String tipo;
  final String estilo;
}

List<_PlayerRow> _loadPlayers(File file) {
  return file
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((line) {
        final p = line.split('\t');
        return _PlayerRow(
          id: int.parse(p[0]),
          teamId: int.parse(p[1]),
          team: p[2],
          name: p[3],
          pila: p[4],
          dorsal: int.parse(p[5]),
          posicion: p[6],
          estilo: p[7],
          valoracion: double.parse(p[8]).round(),
        );
      })
      .toList();
}

Map<int, List<_StRow>> _loadSuperTechniques(File file) {
  final map = <int, List<_StRow>>{};
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    final p = line.split('\t');
    final id = int.parse(p[0]);
    map.putIfAbsent(id, () => []).add(
          _StRow(
            orden: int.parse(p[2]),
            nombre: p[7],
            potencia: int.parse(p[4]),
            tipo: p[5],
            estilo: p[6],
          ),
        );
  }
  for (final list in map.values) {
    list.sort((a, b) => a.orden.compareTo(b.orden));
  }
  return map;
}

String _slugify(String text) {
  final normalized = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return normalized.isEmpty ? 'player' : normalized;
}

String _clashPosition(String pos, int dorsal) {
  switch (pos) {
    case 'POR':
      return 'goalkeeper';
    case 'DEF':
      return dorsal.isEven ? 'fullBack' : 'centreBack';
    case 'MED':
      return dorsal <= 8 ? 'defensiveMidfielder' : 'attackingMidfielder';
    default:
      return dorsal.isEven ? 'winger' : 'striker';
  }
}

String _posCode(String position) => switch (position) {
      'goalkeeper' => 'gk',
      'centreBack' => 'cb',
      'fullBack' => 'fb',
      'defensiveMidfielder' => 'dm',
      'attackingMidfielder' => 'am',
      'winger' => 'wg',
      _ => 'st',
    };

Map<String, int> _buildStats(String pos, int valoracion, String rarity) {
  final profile = _posProfile[pos]!;
  final scale = ((valoracion - 70) / 22.0).clamp(0.0, 1.0);
  final mult = _rarityMult[rarity]!;
  return {
    for (final entry in profile.entries)
      entry.key: ((entry.value[0] + entry.value[1] * scale) * mult)
          .round()
          .clamp(1, 999),
  };
}

int _ptCost(int power) {
  if (power >= 70) return 12;
  if (power >= 55) return 10;
  if (power >= 40) return 9;
  return 8;
}

List<Map<String, dynamic>> _buildStEntries(
  List<_StRow> stList,
  String rarity,
  String cardId,
) {
  final count = _rarityStCount[rarity]!;
  final entries = <Map<String, dynamic>>[];
  for (var i = 0; i < count && i < stList.length; i++) {
    final st = stList[i];
    entries.add({
      'id': '$cardId-st${i + 1}',
      'name': st.nombre,
      'description': st.nombre,
      'type': _stTypeMap[st.tipo],
      'style': _styleMap[st.estilo],
      'basePower': st.potencia,
      'ptCost': _ptCost(st.potencia),
      'level': 'normal',
    });
  }
  return entries;
}

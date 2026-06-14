import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/features/clash/team/data/repositories/clash_lineups_repository.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_rules.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _cardsJson = '''
{
  "cards": [
    {
      "id": "gk-1",
      "playerId": 1,
      "name": "Portero Uno",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "valiente",
      "position": "goalkeeper",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 40, "defense": 10, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "gk-1-st", "name": "Parada", "description": "T", "type": "save", "style": "valiente", "basePower": 40, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "gk-dup",
      "playerId": 1,
      "name": "Portero Duplicado",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "valiente",
      "position": "goalkeeper",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 35, "defense": 10, "pass": 10, "dribble": 8, "shot": 6, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "gk-dup-st", "name": "Parada", "description": "T", "type": "save", "style": "valiente", "basePower": 35, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "st-same-player",
      "playerId": 1,
      "name": "Jugador Versátil",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "potente",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 10, "shot": 30, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st-same-st", "name": "Tiro", "description": "T", "type": "shot", "style": "potente", "basePower": 35, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "st-1",
      "playerId": 2,
      "name": "Delantero Uno",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "potente",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 10, "shot": 35, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st-1-st", "name": "Tiro", "description": "T", "type": "shot", "style": "potente", "basePower": 40, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "cb-1",
      "playerId": 3,
      "name": "Central Uno",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 1,
      "style": "potente",
      "position": "centreBack",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 30, "pass": 10, "dribble": 10, "shot": 8, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "cb-1-st", "name": "Defensa", "description": "T", "type": "defense", "style": "potente", "basePower": 35, "ptCost": 10, "level": "normal"}]
    }
  ]
}
''';

class _FakeCardsDataSource extends ClashCardsLocalDataSource {
  _FakeCardsDataSource(this._cards);

  final List<ClashCardCatalogEntry> _cards;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _cards;
}

Future<ClashLineupsRepository> _repository() async {
  final cards = ClashCardsLocalDataSource().parseCardsJson(_cardsJson);
  final storage = InMemoryClashLineupsBackend();
  return ClashLineupsRepository(
    storage: storage,
    cardsRepository: ClashCardsRepository(_FakeCardsDataSource(cards)),
  );
}

Future<ClashLineupsController> _controller() async {
  final cards = ClashCardsLocalDataSource().parseCardsJson(_cardsJson);
  final cardsRepo = ClashCardsRepository(_FakeCardsDataSource(cards));
  final collectionRepo = ClashPlayerCollectionRepository(
    storage: InMemoryClashPlayerCollectionBackend(),
    cardsRepository: cardsRepo,
  );
  await collectionRepo.grantMissingCardIds(['gk-1', 'st-1', 'cb-1', 'gk-dup']);
  return ClashLineupsController(
    lineupsRepository: await _repository(),
    collectionRepository: collectionRepo,
  );
}

Map<String, ClashCardCatalogEntry> _catalog(List<ClashCardCatalogEntry> cards) {
  return {for (final entry in cards) entry.id: entry};
}

void main() {
  group('ClashLineup7v7 defaults', () {
    test('creación de 3 alineaciones', () {
      final lineups = ClashLineup7v7.createDefaultSet();
      expect(lineups, hasLength(3));
      expect(lineups[0].isActive, isTrue);
      expect(lineups[1].isActive, isFalse);
      expect(lineups.every((l) => l.slots.length == 7), isTrue);
    });
  });

  group('ClashLineupRules', () {
    late Map<String, ClashCardCatalogEntry> catalog;
    late ClashCardCatalogEntry gk;
    late ClashCardCatalogEntry st;

    setUp(() {
      final cards = ClashCardsLocalDataSource().parseCardsJson(_cardsJson);
      catalog = _catalog(cards);
      gk = catalog['gk-1']!;
      st = catalog['st-1']!;
    });

    test('rechazo de posición incorrecta', () {
      final lineup = ClashLineup7v7.createDefaultSet().first;
      expect(
        ClashLineupRules.blockReason(
          lineup: lineup,
          slot: ClashPosition.striker,
          entry: gk,
          catalogById: catalog,
        ),
        ClashLineupAssignBlockReason.wrongPosition,
      );
    });

    test('rechazo de playerId duplicado en la misma alineación', () {
      final lineup = ClashLineup7v7.createDefaultSet().first.copyWith(
        slots: {
          ...ClashLineup7v7.emptySlots(),
          ClashPosition.goalkeeper: 'gk-1',
        },
      );
      final samePlayerStriker = catalog['st-same-player']!;

      expect(
        ClashLineupRules.blockReason(
          lineup: lineup,
          slot: ClashPosition.striker,
          entry: samePlayerStriker,
          catalogById: catalog,
        ),
        ClashLineupAssignBlockReason.duplicatePlayer,
      );
    });

    test('cálculo de potencia total', () {
      final lineup = ClashLineup7v7.createDefaultSet().first.copyWith(
        slots: {
          ...ClashLineup7v7.emptySlots(),
          ClashPosition.goalkeeper: 'gk-1',
          ClashPosition.striker: 'st-1',
        },
      );
      expect(
        ClashLineupRules.calculateTotalPower(lineup, catalog),
        gk.power + st.power,
      );
    });

    test('alineación incompleta muestra posiciones faltantes', () {
      final lineup = ClashLineup7v7.createDefaultSet().first.copyWith(
        slots: {
          ...ClashLineup7v7.emptySlots(),
          ClashPosition.goalkeeper: 'gk-1',
        },
      );
      expect(lineup.isComplete, isFalse);
      expect(lineup.missingPositions, hasLength(6));
      expect(
        lineup.missingPositions,
        isNot(contains(ClashPosition.goalkeeper)),
      );
    });
  });

  group('ClashLineupsRepository', () {
    test('solo una alineación activa', () async {
      final repo = await _repository();
      await repo.loadLineups();
      final updated = await repo.setActiveLineup('lineup-2');
      expect(updated.where((l) => l.isActive), hasLength(1));
      expect(updated.firstWhere((l) => l.isActive).id, 'lineup-2');
    });

    test('asignación por posición compatible', () async {
      final repo = await _repository();
      await repo.loadLineups();
      final updated = await repo.assignCard(
        lineupId: 'lineup-1',
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );
      final lineup = updated.firstWhere((l) => l.id == 'lineup-1');
      expect(lineup.cardIdFor(ClashPosition.goalkeeper), 'gk-1');
    });

    test('rechazo de posición incorrecta en repositorio', () async {
      final repo = await _repository();
      await repo.loadLineups();
      expect(
        () => repo.assignCard(
          lineupId: 'lineup-1',
          slot: ClashPosition.striker,
          cardId: 'gk-1',
        ),
        throwsA(isA<ClashLineupOperationException>()),
      );
    });

    test('misma carta permitida en alineaciones distintas', () async {
      final repo = await _repository();
      await repo.loadLineups();
      await repo.assignCard(
        lineupId: 'lineup-1',
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );
      final updated = await repo.assignCard(
        lineupId: 'lineup-2',
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );
      expect(
        updated
            .firstWhere((l) => l.id == 'lineup-2')
            .cardIdFor(ClashPosition.goalkeeper),
        'gk-1',
      );
    });

    test('renombrar alineación', () async {
      final repo = await _repository();
      await repo.loadLineups();
      final updated = await repo.renameLineup('lineup-3', 'Titular alterno');
      expect(
        updated.firstWhere((l) => l.id == 'lineup-3').name,
        'Titular alterno',
      );
    });

    test('persistencia local', () async {
      final storage = InMemoryClashLineupsBackend();
      final cards = ClashCardsLocalDataSource().parseCardsJson(_cardsJson);
      final repo = ClashLineupsRepository(
        storage: storage,
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource(cards)),
      );

      await repo.assignCard(
        lineupId: 'lineup-1',
        slot: ClashPosition.striker,
        cardId: 'st-1',
      );

      final repo2 = ClashLineupsRepository(
        storage: storage,
        cardsRepository: ClashCardsRepository(_FakeCardsDataSource(cards)),
      );
      final reloaded = await repo2.loadLineups();
      expect(reloaded.first.cardIdFor(ClashPosition.striker), 'st-1');
      expect(storage.raw, isNotNull);
    });

    test('cambiar entre las 3 alineaciones conserva datos', () async {
      final repo = await _repository();
      await repo.loadLineups();
      await repo.assignCard(
        lineupId: 'lineup-1',
        slot: ClashPosition.goalkeeper,
        cardId: 'gk-1',
      );
      await repo.assignCard(
        lineupId: 'lineup-3',
        slot: ClashPosition.striker,
        cardId: 'st-1',
      );

      final all = await repo.loadLineups();
      expect(
        all
            .firstWhere((l) => l.id == 'lineup-1')
            .cardIdFor(ClashPosition.goalkeeper),
        'gk-1',
      );
      expect(
        all
            .firstWhere((l) => l.id == 'lineup-3')
            .cardIdFor(ClashPosition.striker),
        'st-1',
      );
    });
  });

  group('ClashLineupsController picker', () {
    test('selector filtra por posición mostrando bloqueos', () async {
      final controller = await _controller();
      await controller.load();

      final gkEntries = controller.pickerEntries(
        slot: ClashPosition.goalkeeper,
      );
      expect(gkEntries, isNotEmpty);
      expect(
        controller.canPickEntry(
          slot: ClashPosition.goalkeeper,
          entry: gkEntries.firstWhere((e) => e.id == 'gk-1'),
        ),
        isTrue,
      );
      expect(
        controller.pickerBlockReason(
          slot: ClashPosition.goalkeeper,
          entry: gkEntries.firstWhere((e) => e.id == 'st-1'),
        ),
        ClashLineupAssignBlockReason.wrongPosition,
      );
    });
  });
}

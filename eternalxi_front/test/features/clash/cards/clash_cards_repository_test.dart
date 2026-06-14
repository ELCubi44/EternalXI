import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleJson = '''
{
  "cards": [
    {
      "id": "test-1",
      "playerId": 1,
      "name": "Alpha Striker",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 5,
      "style": "potente",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {
        "save": 2,
        "defense": 10,
        "pass": 12,
        "dribble": 14,
        "shot": 30,
        "techniquePoints": 15,
        "stamina": 100
      },
      "superTechniques": [
        {
          "id": "test-1-st",
          "name": "Test Shot",
          "description": "Test",
          "type": "shot",
          "style": "potente",
          "basePower": 40,
          "ptCost": 10,
          "level": "normal"
        }
      ]
    },
    {
      "id": "test-2",
      "playerId": 2,
      "name": "Beta Keeper",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 3,
      "style": "valiente",
      "position": "goalkeeper",
      "basicPortraitPath": "placeholder",
      "stats": {
        "save": 40,
        "defense": 15,
        "pass": 10,
        "dribble": 8,
        "shot": 5,
        "techniquePoints": 12,
        "stamina": 105
      },
      "superTechniques": [
        {
          "id": "test-2-st",
          "name": "Test Save",
          "description": "Test",
          "type": "save",
          "style": "valiente",
          "basePower": 42,
          "ptCost": 11,
          "level": "normal"
        }
      ]
    },
    {
      "id": "test-3",
      "playerId": 3,
      "name": "Gamma Winger",
      "team": "Eternal XI",
      "rarity": "n",
      "level": 8,
      "style": "agil",
      "position": "winger",
      "basicPortraitPath": "placeholder",
      "stats": {
        "save": 2,
        "defense": 10,
        "pass": 18,
        "dribble": 28,
        "shot": 20,
        "techniquePoints": 14,
        "stamina": 101
      },
      "superTechniques": [
        {
          "id": "test-3-st",
          "name": "Test Dribble",
          "description": "Test",
          "type": "dribble",
          "style": "agil",
          "basePower": 36,
          "ptCost": 9,
          "level": "normal"
        }
      ]
    }
  ]
}
''';

List<ClashCardCatalogEntry> _sampleCards() {
  return ClashCardsLocalDataSource().parseCardsJson(_sampleJson);
}

class _FakeDataSource extends ClashCardsLocalDataSource {
  _FakeDataSource(this._cards);

  final List<ClashCardCatalogEntry> _cards;

  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async => _cards;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashCardsLocalDataSource', () {
    test('parsea JSON empaquetado del asset', () async {
      final dataSource = ClashCardsLocalDataSource(
        assetPath: 'assets/data/clash/cards.json',
      );
      final cards = await dataSource.loadCards();
      expect(cards.length, 14);
      expect(cards.every((c) => c.card.rarity == ClashRarity.n), isTrue);
    });

    test('parseCardsJson tolera estructura válida', () {
      final cards = _sampleCards();
      expect(cards, hasLength(3));
      expect(cards.first.name, 'Alpha Striker');
      expect(cards.first.card.playerId, 1);
    });
  });

  group('ClashCardsRepository', () {
    late ClashCardsRepository repository;
    late List<ClashCardCatalogEntry> sampleCards;

    setUp(() {
      sampleCards = _sampleCards();
      repository = ClashCardsRepository(_FakeDataSource(sampleCards));
    });

    test('carga cartas desde datasource', () async {
      final cards = await repository.fetchAllCards();
      expect(cards, hasLength(3));
    });

    test('filtra por posición', () {
      final filtered = repository.filterAndSort(
        cards: sampleCards,
        position: ClashPosition.goalkeeper,
      );
      expect(filtered, hasLength(1));
      expect(filtered.single.name, 'Beta Keeper');
    });

    test('filtra por rareza', () {
      final filtered = repository.filterAndSort(
        cards: sampleCards,
        rarity: ClashRarity.n,
      );
      expect(filtered, hasLength(3));
    });

    test('filtra por estilo', () {
      final filtered = repository.filterAndSort(
        cards: sampleCards,
        style: ClashPlayerStyle.agil,
      );
      expect(filtered, hasLength(1));
      expect(filtered.single.name, 'Gamma Winger');
    });

    test('ordena por potencia descendente', () {
      final sorted = repository.filterAndSort(
        cards: sampleCards,
        sortField: ClashCardSortField.power,
        descending: true,
      );
      expect(sorted.first.power, greaterThanOrEqualTo(sorted.last.power));
    });

    test('findById devuelve carta o null', () async {
      final found = await repository.findById('test-2');
      expect(found?.name, 'Beta Keeper');
      expect(await repository.findById('missing'), isNull);
    });
  });
}
